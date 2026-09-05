"""Exercise the real MCP wire protocol and wait for a study without a client UI."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import time

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
choice = parser.add_mutually_exclusive_group()
choice.add_argument('--nature', action='store_true', help='Build land/nature fixtures')
choice.add_argument('--furnishings', action='store_true', help='Build the existing furnishing catalogue')
choice.add_argument('--mobs', action='store_true', help='Build and rig the current mob roster')
args = parser.parse_args()
with subprocess.Popen([sys.executable, '-B', str(Path(__file__).with_name('server.py')),
                       '--project', str(root)], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                      text=True, encoding='utf-8') as server:
    def request(method, params):
        server.stdin.write(json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}) + '\n')
        server.stdin.flush()
        reply = json.loads(server.stdout.readline())['result']
        if method == 'tools/call':
            if reply.get('isError'):
                raise RuntimeError(reply)
            return json.loads(reply['content'][0]['text'])
        return reply

    try:
        request('initialize', {'protocolVersion': '2025-11-25', 'capabilities': {},
                               'clientInfo': {'name': 'study-smoke', 'version': '1.0'}})
        server.stdin.write(json.dumps({'jsonrpc': '2.0', 'method': 'notifications/initialized'}) + '\n')
        server.stdin.flush()
        recipe = 'build_furnishings_study' if args.furnishings else ('build_nature_study' if args.nature else 'build_building_study')
        if args.mobs:
            recipe = 'build_mobs_study'
        job = request('tools/call', {'name': recipe})
        print(json.dumps(job), flush=True)
        deadline = time.monotonic() + 240
        while time.monotonic() < deadline:
            result = request('tools/call', {'name': 'blender_job_status', 'arguments': {'job_id': job['job_id']}})
            if result['status'] != 'running':
                print(json.dumps(result, indent=2), flush=True)
                if result['status'] != 'complete':
                    raise RuntimeError('Blender job failed')
                break
            time.sleep(1)
        else:
            raise TimeoutError('Study took more than 240 seconds')
    finally:
        server.stdin.close()
