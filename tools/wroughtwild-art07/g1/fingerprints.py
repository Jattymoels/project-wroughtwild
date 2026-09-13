"""Compare actual paid runs, excluding only auto-generated station scene names."""
import copy
import hashlib
import json
import sys
from pathlib import Path


def canonical(snapshot):
    result = copy.deepcopy(snapshot)
    for name in ['sim', 'contraptions', 'leylines']:
        result[name] = json.loads(result[name])
    result['resource_nodes'].sort(key=lambda row: row['resource_id'])
    for row in result['stations']:
        row.pop('name')  # Godot's @StaticBody3D@counter, NOT station_key.
    result['stations'].sort(key=lambda row: row['station_key'])
    return result


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


art, baseline, destination = map(Path, sys.argv[1:])
a, b = [json.loads(path.read_text()) for path in [art, baseline]]
assert a['failures'] == b['failures'] == 0
report = {'art': str(art.resolve()), 'baseline': str(baseline.resolve()), 'stages': {},
          'canonicalization': 'Parse native JSON, sort finite resource/station records, omit only auto-generated station scene-node name. Persistent station_key, resource_id, positions, quantities, work, skills, effects, loot, building addresses and ownership remain exact.'}
for stage in ['initial', 'paid', 'final']:
    x, y = canonical(a[stage]), canonical(b[stage])
    assert x == y, (stage, [key for key in x if x[key] != y[key]])
    report['stages'][stage] = {'sha256': digest(x), 'fields': {key: digest(x[key]) for key in x}}
assert a['walk'] == b['walk'] and not a['walk']['stalled']
report['walk_metres'] = a['walk']['metres']
with destination.open('x') as stream:
    json.dump(report, stream, indent=2)
print('G1_FINGERPRINTS_MATCH', report['walk_metres'])
