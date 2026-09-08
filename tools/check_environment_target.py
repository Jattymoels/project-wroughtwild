"""Check curated INT-02B GLBs against the retained pre-slice envelopes.

Standard library only. No Blender, build directory or normal save is required.
The ruin triangle contracts are from a7c3854, not regenerated from new meshes.
"""
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]


def inspect(path):
    blob = path.read_bytes()
    size = struct.unpack_from('<I', blob, 12)[0]
    document = json.loads(blob[20:20+size])
    binary = memoryview(blob)[28+size:]

    def values(index):
        accessor = document['accessors'][index]
        view = document['bufferViews'][accessor['bufferView']]
        code = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[accessor['componentType']]
        count = {'SCALAR': 1, 'VEC3': 3}[accessor['type']]
        fmt = '<'+code*count
        stride = view.get('byteStride', struct.calcsize(fmt))
        start = view.get('byteOffset', 0)+accessor.get('byteOffset', 0)
        return [struct.unpack_from(fmt, binary, start+i*stride) for i in range(accessor['count'])]

    points, triangles = [], []
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            vertices = values(primitive['attributes']['POSITION'])
            indices = [v[0] for v in values(primitive['indices'])]
            points.extend(vertices)
            for i in range(0, len(indices), 3):
                triangles.append(sorted(tuple(round(c, 6) for c in vertices[index]) for index in indices[i:i+3]))
    canonical = json.dumps(sorted(triangles), separators=(',', ':')).encode()
    return {
        'sha256': hashlib.sha256(blob).hexdigest(),
        'triangle_geometry_sha256': hashlib.sha256(canonical).hexdigest(),
        'triangles': len(triangles),
        'bounds': [[min(p[a] for p in points) for a in range(3)], [max(p[a] for p in points) for a in range(3)]],
        'radius': max((p[0]**2+p[2]**2)**.5 for p in points),
        'opaque': all(m.get('alphaMode', 'OPAQUE') == 'OPAQUE' for m in document.get('materials', [])),
        'identity_nodes': all('matrix' not in n and n.get('translation', [0,0,0]) == [0,0,0] and n.get('scale', [1,1,1]) == [1,1,1] and n.get('rotation', [0,0,0,1]) == [0,0,0,1] for n in document['nodes']),
        'visual_only': not any('colonly' in n.get('name', '') or 'convcol' in n.get('name', '') for n in document['nodes'])}


def main():
    folder = ROOT/'game/assets/authored'
    manifest = json.loads((folder/'environment_target_manifest.json').read_text())
    checks = 0
    for name, contract in manifest['assets'].items():
        actual = inspect(folder/(name+'.glb'))
        assert actual['sha256'] == contract['sha256'], (name, 'curated file hash')
        assert actual['opaque'] and actual['visual_only'] and actual['identity_nodes'], (name, 'visual export contract')
        checks += 2
        old = contract['retained_bounds']
        assert all(actual['bounds'][0][a] >= old[0][a]-1e-6 and actual['bounds'][1][a] <= old[1][a]+1e-6 for a in range(3)), (name, 'envelope grew')
        checks += 1
        if name.startswith('cataclysm_'):
            assert actual['triangle_geometry_sha256'] == contract['retained_triangle_geometry_sha256'], (name, 'solid ruin geometry changed')
            checks += 1
        if 'habitat_radius' in contract:
            assert actual['radius'] <= contract['habitat_radius'], (name, 'habitat footprint')
            checks += 1
        assert actual['triangles'] <= contract['triangle_budget'], (name, 'triangle budget')
        checks += 1
        print(name, actual['triangles'], 'triangles; retained envelope')
    print(f'ENVIRONMENT_EXPORTS {checks} checks, 0 failures')


if __name__ == '__main__':
    main()
