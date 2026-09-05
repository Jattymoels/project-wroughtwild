import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

from server import Bridge, dispatch

ROOT = Path(__file__).resolve().parents[2]


class ProtocolTests(unittest.TestCase):
    def setUp(self):
        self.bridge = Bridge(ROOT, 'does-not-exist.exe')

    def request(self, method, params=None):
        return dispatch(self.bridge, {'jsonrpc': '2.0', 'id': 7, 'method': method, 'params': params or {}})

    def test_negotiation_and_notifications(self):
        self.assertEqual(self.request('initialize', {'protocolVersion': '2025-06-18'})['result']['protocolVersion'], '2025-06-18')
        self.assertIsNone(dispatch(self.bridge, {'jsonrpc': '2.0', 'method': 'notifications/initialized'}))
        self.assertEqual(self.request('ping')['result'], {})

    def test_missing_blender_is_tool_error(self):
        self.assertTrue(self.request('tools/call', {'name': 'blender_status'})['result']['isError'])

    def test_rejects_arbitrary_arguments_and_code(self):
        with patch('server.subprocess.Popen') as spawn:
            for params in ({'name': 'execute_python'}, {'name': 'build_building_study', 'arguments': {'script': '../../bad.py'}}, {'name': 'build_nature_study', 'arguments': {'script': '../../bad.py'}}, {'name': 'build_furnishings_study', 'arguments': {'script': '../../bad.py'}}, {'name': 'build_mobs_study', 'arguments': {'script': '../../bad.py'}}, {'name': 'blender_job_status', 'arguments': {'job_id': []}}):
                self.assertTrue(self.request('tools/call', params)['result']['isError'])
            spawn.assert_not_called()

    def test_unknown_job(self):
        self.assertTrue(self.request('tools/call', {'name': 'blender_job_status', 'arguments': {'job_id': '../escape'}})['result']['isError'])

    def test_wire_framing_and_parse_error_recovery(self):
        messages = ['broken', json.dumps({'jsonrpc': '2.0', 'method': 'notifications/initialized'}), json.dumps({'jsonrpc': '2.0', 'id': 9, 'method': 'tools/list'})]
        run = subprocess.run([sys.executable, str(ROOT / 'tools/wroughtwild-blender/server.py'), '--project', str(ROOT)], input='\n'.join(messages) + '\n', capture_output=True, text=True, timeout=10)
        self.assertEqual(run.returncode, 0, run.stderr)
        replies = [json.loads(line) for line in run.stdout.splitlines()]
        self.assertEqual(len(replies), 2)
        self.assertEqual(replies[0]['error']['code'], -32700)
        self.assertEqual({t['name'] for t in replies[1]['result']['tools']}, {'blender_status', 'build_building_study', 'build_nature_study', 'build_furnishings_study', 'build_mobs_study', 'blender_job_status'})
        self.assertEqual(replies[1]['id'], 9)


if __name__ == '__main__':
    unittest.main()
