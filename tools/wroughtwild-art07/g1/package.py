"""Collect checked G1 evidence/lineage into the already freshly prepared handoff."""
import json
import shutil
import sys
from pathlib import Path
from verify_inputs import ROOT, INDEX, BASE, digest

build=ROOT/'build/art07/g1'
out=build/'v06/handoff'
assert out.is_dir() and not (out/'manifest.json').exists()
for required in ['fresh-import','final-unit','fresh-smoke-forward_plus','fresh-smoke-gl_compatibility']:
    assert json.loads((build/f'v06/{required}.log.json').read_text(encoding='utf-8-sig'))['exit_code']==0,required

def copy(source,target):
    target.parent.mkdir(parents=True,exist_ok=True)
    if source.is_dir():shutil.copytree(source,target,dirs_exist_ok=True,ignore=shutil.ignore_patterns('__pycache__','*.pyc','.godot','*.uid'))
    else:shutil.copy2(source,target)

copy(Path(__file__).parent,out/'recipes/g1')
copy(Path(__file__).parent/'launch.ps1',out/'launch.ps1')
copy(Path(__file__).parent/'HANDOFF.md',out/'README.md')
for file in (ROOT/'docs/art/leyline-studies/2026-09-09/art07/g1').iterdir():
    if file.suffix in ['.png','.webp','.json'] or file.name=='costs.md':copy(file,out/'evidence/curated'/file.name)
copy(Path('C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe'),out/'engine/Godot_v4.5-stable_win64.exe')
for name in ['baseline.zip','build.log','provenance.json','CMakeLists.txt']:
    copy(build/'v02/native'/name,out/'native'/name)
copy(INDEX,out/'lineage/g1-inputs-2026-09-12.json')
for when,path in [('before',build/'v01/inputs-verified.json'),('after',build/'v06/inputs-verified-final.json')]:copy(path,out/f'lineage/verified-{when}.json')
for ident,row in json.loads(INDEX.read_text())['inputs'].items():
    copy(Path(row['path'])/'manifest.json',out/f'lineage/manifests/{ident}.json')
    copy(ROOT/f'docs/prototype/art07-production/receipts/{ident}.md',out/f'lineage/receipts/{ident}.md')
for folder in ['views-art-forward_plus','views-art-gl_compatibility','paid-art-forward_plus-walk-review']:
    copy(build/'v05/pilot/evidence'/folder,out/'evidence'/folder)
for folder in ['paid-art-r02','paid-baseline-r02']:
    copy(build/'v04/pilot/evidence'/folder,out/'evidence'/folder)
copy(build/'v04/fingerprints.json',out/'evidence/paid-fingerprints.json')
for name in ['probes.json','runtime-delta.json','benchmark-comparison.json','fresh-copy.json']:
    copy(build/'v06'/name,out/'evidence'/name)

logs=[]
def take(version,folder,names=None):
    source=build/version/folder
    for path in sorted(source.glob('*.log')):
        if names is None or path.stem in names:logs.append(path)
take('v04','',['paid02','paid-baseline','paid-restart'])
take('v05','focused03',['unit'])
take('v05','focused-rest01')
take('v05','sources02',['b1','b3','c1','c1-partial'])
take('v05','sources-rest01',['c2','c2-partial','c3','c3-partial'])
take('v05','sources-rest02')
take('v05','devices02',['f1','f1-restart'])
take('v05','devices-rest02')
take('v05','shapes01',['d1','d1-restart','d2','d2-restart'])
take('v05','shapes-rendered')
take('v05','signals01')
take('v05','',['review-forward02','review-compat01','walk-forward'])
take('v06','captures')
take('v06','catalogue-final')
take('v06','stations',['e1','e1-restart'])
take('v06','stations-final')
take('v06','',['import','probe-art','probe-baseline','blender-final','bench-art-forward_plus','bench-baseline-forward_plus','bench-art-gl_compatibility','bench-baseline-gl_compatibility','fresh-import','fresh-smoke-forward_plus','fresh-smoke-gl_compatibility','final-unit'])
validation=[]
for log in logs:
    meta=json.loads(Path(str(log)+'.json').read_text(encoding='utf-8-sig'))
    text=log.read_text(encoding='utf-8-sig')
    assert meta['exit_code']==0,log
    assert not meta['competing_benchmark_processes'],log
    assert not any(line.startswith(('ERROR:','SCRIPT ERROR:','FAIL ')) for line in text.splitlines()),log
    summary=[line for line in text.splitlines() if any(word in line for word in [' checks','G1_','_OK','C3_NATIVE','C4_NATIVE','C5_NATIVE'])]
    validation.append({'log':str(log.resolve()),'package_log':str(Path('logs')/log.relative_to(build)),'metadata':meta,'result_lines':summary[-4:]})
    for suffix in ['', '.json','.stdout','.stderr']:copy(Path(str(log)+suffix),out/'logs'/Path(str(log.relative_to(build))+suffix))
(out/'evidence/validation.json').write_text(json.dumps(validation,indent=2))
# Keep the original failed attempts clearly separate; never count them as checks.
for rel in ['v05/exhausted-forward.log','v05/shapes01/d3.log','v05/catalogue04.log','v04/paid01.log']:
    for suffix in ['', '.json','.stdout','.stderr']:copy(build/(rel+suffix),out/'diagnostics'/(rel+suffix))
for name in ['launcher-diagnostic.json','f2-launcher-diagnostic.json']:copy(build/'v05'/name,out/'diagnostics'/name)
copy(build/'v06/e2-launcher-diagnostic.json',out/'diagnostics/e2-launcher-diagnostic.json')
for suffix in ['', '.json','.stdout','.stderr']:copy(build/('v06/stations/e2.log'+suffix),out/'diagnostics'/('v06/stations/e2.log'+suffix))
for ident in ['d1','d2','d3']:
    for mode in ['placement','restart']:
        p=out/f'game/art07_{ident}/check-{mode}.json'
        # These were copied predecessor result files, not generated by this final
        # project. Correct G1 runs live under logs above; remove only these files.
        if p.exists():
            assert p.resolve().is_relative_to(out.resolve());p.unlink()
(out/'delivery.json').write_text(json.dumps({'base':BASE,'index_sha256':digest(INDEX),'engine_sha256':digest(out/'engine/Godot_v4.5-stable_win64.exe'),'paid_checkpoint_sha256':digest(out/'game/g1/paid-home.json'),'checked_logs':len(validation),'scope':'G1 isolated integration only. Source recipes/assets remain predecessor-owned. Owner visual acceptance pending. G2 not started.'},indent=2))
print('G1_EVIDENCE_PACKAGED',len(validation))
