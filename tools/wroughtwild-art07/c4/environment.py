"""Record selected source/tool/check evidence after all current checks."""
import sys,json,subprocess
from pathlib import Path
import PIL,numpy
from prerequisites import sha,DEPOT
root=Path(sys.argv[1]).resolve();out=root/'environment-final.json';assert not out.exists()
jobs={p.name:json.loads(p.read_text()) for p in (root/'current-checks').glob('*.job.json')}
assert len(jobs)==14 and all(j['exit']==0 for j in jobs.values())
source_paths=[root/'ash-raw/source.glb',root/'kit-v03/c4-master.blend',root/'inspection/ash-source.blend',root/'native-v03/game/bin/libwroughtwild_sim.windows.x86_64.dll']
source_paths += list((root/'ash-raw').glob('*.png'))
for n in ['README.md','docs/DESIGN.md','docs/decisions/registry.md','docs/prototype/art07-production/receipts/b4.md','docs/art/concepts/environment/2026-09-09-frontier/02-habitat-kits.png','docs/art/references/environment/env-002-dense-frontier-original.png']:
    source_paths.append(DEPOT/n)
sources={str(p):{'bytes':p.stat().st_size,'sha256':sha(p)} for p in source_paths}
result={'python':sys.version,'python_executable':sys.executable,'pillow':PIL.__version__,'numpy':numpy.__version__,'frozen_revision':'f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9','selection':{'kit':'kit-v03','review':'review-v03','native':'native-v03','blender':'blender-v03'},'sources':sources,'current_check_jobs':jobs,'native_provenance':json.loads((root/'native-v03/provenance.json').read_text()),'known_diagnostics':['Initial image audit did not force lazy packed-image decode; fixed by reading pixels.','Initial exact float scale assertion detected native lean roundoff; corrected to approximate unit basis plus exact child model scale.','First candidate review ground winding was reversed; actual ray support check caught it and clockwise front faces restored.','First composition retained distracting B3 middle UVs and dense bramble; selected source uses near B3 geometry and sparse whole leaves.'],'unchanged_assertions':8225}
result['selection']['review']='review-v04'
result['known_diagnostics'].append('Review-v03 scar camera faced the back; review-v04 captures the front, with fixed identical clock for light off/on and a close front pulse view. No source geometry changed.')
out.write_text(json.dumps(result,indent=2)+'\n');print('C4_ENVIRONMENT_RECORDED')
