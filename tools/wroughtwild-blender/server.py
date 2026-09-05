"""Small local stdio MCP server. No packages, sockets, or arbitrary-code tool.

Blender jobs run in fresh background processes; this does not control an open UI.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid

HERE = Path(__file__).resolve().parent
PROTOCOLS = ('2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05')
RECIPES = {'build_building_study': 'build_study.py', 'build_nature_study': 'build_nature.py',
           'build_furnishings_study': 'build_furnishings.py', 'build_mobs_study': 'build_mobs.py'}


class Bridge:
    def __init__(self, project, blender=None):
        self.project = Path(project).resolve()
        self.blender = blender
        self.jobs = {}

    def executable(self):
        configured = self.blender or os.environ.get('BLENDER_EXECUTABLE')
        if configured:
            path = Path(configured).resolve()
            if not path.is_file():
                raise ValueError('Configured Blender executable does not exist')
            return str(path)
        portable = sorted((self.project / 'build/blender-tool').glob('blender-*/blender.exe'))
        result = str(portable[-1]) if portable else shutil.which('blender')
        if not result:
            raise ValueError('Blender not found. Set BLENDER_EXECUTABLE or use the portable build.')
        return result

    def call(self, name, arguments):
        if name == 'blender_status':
            return {'executable': self.executable(), 'project': str(self.project),
                    'mode': 'background asset jobs; no live UI connection'}
        if name in RECIPES:
            if any(job['process'].poll() is None for job in self.jobs.values()):
                raise ValueError('A build is already running; inspect it with blender_job_status.')
            executable = self.executable()
            job_id = uuid.uuid4().hex
            output = self.project / 'build/blender-study' / job_id
            output.mkdir(parents=True)
            log_path = output / 'blender.log'
            with log_path.open('w', encoding='utf-8') as log:
                process = subprocess.Popen(
                    [executable, '--background', '--factory-startup', '--disable-autoexec',
                     '--python-exit-code', '1', '--python', str(HERE / 'scripts' / RECIPES[name]),
                     '--', str(self.project), str(output)], cwd=self.project,
                    stdout=log, stderr=subprocess.STDOUT,
                    creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
            self.jobs[job_id] = {'process': process, 'output': output, 'log': log_path}
            return {'job_id': job_id, 'output': str(output), 'status': 'running'}
        if name == 'blender_job_status':
            job = self.jobs.get(arguments.get('job_id'))
            if not job:
                raise ValueError('Unknown job id for this server session')
            code = job['process'].poll()
            result = {'status': 'running' if code is None else ('complete' if code == 0 else 'failed'),
                      'exit_code': code, 'output': str(job['output']),
                      'log_tail': job['log'].read_text(encoding='utf-8', errors='replace')[-5000:]}
            report = job['output'] / 'report.json'
            if code == 0 and report.exists():
                result['report'] = json.loads(report.read_text(encoding='utf-8'))
            return result
        raise ValueError('Unknown tool: ' + name)

    def close(self):
        for job in self.jobs.values():
            if job['process'].poll() is None:
                job['process'].terminate()
                try:
                    job['process'].wait(timeout=5)
                except subprocess.TimeoutExpired:
                    job['process'].kill()
                    job['process'].wait()


def tool(name, description, properties=None, required=None, read_only=False):
    return {'name': name, 'description': description,
            'inputSchema': {'type': 'object', 'properties': properties or {},
                            'required': required or [], 'additionalProperties': False},
            'annotations': {'readOnlyHint': read_only, 'destructiveHint': False,
                            'openWorldHint': False}}


TOOLS = [
    tool('blender_status', 'Locate local Blender and report this project connection.', read_only=True),
    tool('build_building_study', 'Create a new wall/post/beam study: blend, visual GLBs, collision GLBs, preview and dimensional report. Returns a job id; poll for completion.'),
    tool('build_nature_study', 'Create a seeded tree, boulder, shrub, fern, deadfall and stump study with Blender scene, GLBs, baseline collision proxies and landscape renders. Returns a job id; poll for completion.'),
    tool('build_furnishings_study', 'Create the existing chest, campfire, workbench, mason yard and two forge tiers as Blender meshes, baseline collision proxies and furnishing review renders. Returns a job id; poll for completion.'),
    tool('build_mobs_study', 'Create the current enemy roster, Forge Tyrant and passive elk as skinned Blender meshes with preview animation clips, existing capsule proxies and review renders. Returns a job id; poll for completion.'),
    tool('blender_job_status', 'Read progress and dimensional results for a job in this session.',
         {'job_id': {'type': 'string'}}, ['job_id'], True),
]


def dispatch(bridge, request):
    if not isinstance(request, dict) or request.get('jsonrpc') != '2.0' or not isinstance(request.get('method'), str):
        return {'jsonrpc': '2.0', 'id': None, 'error': {'code': -32600, 'message': 'Invalid request'}}
    if 'id' not in request:
        return None
    response = {'jsonrpc': '2.0', 'id': request['id']}
    method, params = request['method'], request.get('params', {})
    if not isinstance(params, dict):
        response['error'] = {'code': -32602, 'message': 'params must be an object'}
    elif method == 'initialize':
        requested = params.get('protocolVersion')
        response['result'] = {'protocolVersion': requested if requested in PROTOCOLS else PROTOCOLS[0],
                              'capabilities': {'tools': {}},
                              'serverInfo': {'name': 'wroughtwild-blender', 'version': '0.4.0'}}
    elif method == 'ping':
        response['result'] = {}
    elif method == 'tools/list':
        response['result'] = {'tools': TOOLS}
    elif method == 'tools/call':
        try:
            name, arguments = params.get('name'), params.get('arguments', {})
            definition = next((t for t in TOOLS if t['name'] == name), None)
            if not definition or not isinstance(arguments, dict):
                raise ValueError('Unknown tool or invalid arguments')
            schema = definition['inputSchema']
            if set(arguments) - set(schema['properties']) or any(k not in arguments for k in schema['required']):
                raise ValueError('Unexpected or missing tool arguments')
            if any(not isinstance(v, str) for v in arguments.values()):
                raise ValueError('Tool arguments must be strings')
            result = bridge.call(name, arguments)
            response['result'] = {'content': [{'type': 'text', 'text': json.dumps(result)}], 'isError': False}
        except (ValueError, OSError) as exc:
            response['result'] = {'content': [{'type': 'text', 'text': str(exc)}], 'isError': True}
    else:
        response['error'] = {'code': -32601, 'message': 'Method not found'}
    return response


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--blender')
    args = parser.parse_args()
    if not (args.project / 'data/tuning/construction.json').is_file():
        parser.error('--project must point to a Wroughtwild checkout')
    bridge = Bridge(args.project, args.blender)
    try:
        for line in sys.stdin:
            try:
                response = dispatch(bridge, json.loads(line))
            except json.JSONDecodeError:
                response = {'jsonrpc': '2.0', 'id': None, 'error': {'code': -32700, 'message': 'Parse error'}}
            if response is not None:
                print(json.dumps(response), flush=True)
    finally:
        bridge.close()


if __name__ == '__main__':
    main()
