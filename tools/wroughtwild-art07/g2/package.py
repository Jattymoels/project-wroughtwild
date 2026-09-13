"""Seal G2 review evidence only; verified G1 source/runtime companions stay separate."""
import json
import shutil
import sys
from pathlib import Path
from verify_copy import ROOT, BUILD, sha
OUT=BUILD/'v01';HANDOFF=BUILD/'v02/handoff'
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def copy(source,target):
    assert source.is_file(),source
    assert target.resolve().is_relative_to(HANDOFF.resolve())
    target.parent.mkdir(parents=True,exist_ok=True)
    assert not target.exists(),target
    shutil.copy2(source,target)
    assert sha(source)==sha(target),source

def verify():
    manifest=read(HANDOFF/'manifest.json')
    actual={p.relative_to(HANDOFF).as_posix() for p in HANDOFF.rglob('*') if p.is_file() and p!=HANDOFF/'manifest.json'}
    assert actual==set(manifest['files'])
    for name,row in manifest['files'].items():
        path=(HANDOFF/name).resolve();assert path.is_relative_to(HANDOFF)
        assert path.stat().st_size==row['bytes'] and sha(path)==row['sha256'],name
    receipt={'path':str(HANDOFF),'manifest_sha256':sha(HANDOFF/'manifest.json'),'files':len(actual),'bytes':sum(r['bytes'] for r in manifest['files'].values())}
    print('G2_PACKAGE_VERIFIED',json.dumps(receipt))
    return receipt

if '--verify' in sys.argv:
    verify();sys.exit(0)
summary=read(OUT/'review-summary.json');preserved=read(OUT/'preservation-final.json')
assert all(not row['failure'] and row['exit_code']==0 for row in summary['jobs'])
assert preserved['canonical_and_24_sources_before_after_equal']
HANDOFF.mkdir(parents=True,exist_ok=False)
for folder,destination in [(ROOT/'tools/wroughtwild-art07/g2','recipes'),(ROOT/'docs/art/leyline-studies/2026-09-09/art07/g2','report'),(OUT/'logs','logs'),(OUT/'review/evidence','godot'),(OUT/'blender','blender'),(OUT/'review/game/g2','inspection-runtime')]:
    for path in sorted(folder.rglob('*')):
        if path.is_file() and '__pycache__' not in path.parts and path.suffix not in ['.uid','.import','.blend1']:
            copy(path,HANDOFF/destination/path.relative_to(folder))
for path in sorted(OUT.glob('*.json')):
    copy(path,HANDOFF/'audit'/path.name)
copy(OUT/'after/inputs.json',HANDOFF/'audit/after-inputs.json')
for row in preserved['new_review_files']:
    name=row['path']
    if name.startswith(('evidence/','game/g2/')):continue
    copy(OUT/'review'/name,HANDOFF/'fixtures/review'/name)
copy(OUT/'review/game/g1/paid-home.json',HANDOFF/'fixtures/review/game/g1/paid-home.json')
for path in sorted((OUT/'users').rglob('*')):
    if path.is_file() and (path.name.endswith('.json') or '.json.' in path.name):
        copy(path,HANDOFF/'fixtures/users'/path.relative_to(OUT/'users'))
companions={'purpose':'G2 review-only evidence package, not a new game/content handoff. All full source assets remain unmodified in the verified companion copies.','source_copy':str(OUT/'sealed'),'source_manifest_sha256':sha(OUT/'sealed/manifest.json'),'runtime_copy':str(OUT/'review'),'runtime_original_files_and_hashes':'audit/copy.json','runtime_final_audit':'audit/preservation-final.json','canonical_g1':read(OUT/'inputs.json')['g1_package'],'reproduce':'recipes/README.md','publication':'Local branch findings only. Dedicated publisher owns integration/push. Receipt is committed separately after this package seal; it identifies exact Git commit and this manifest hash.'}
(HANDOFF/'companions.json').write_text(json.dumps(companions,indent=2),encoding='utf-8')
(HANDOFF/'README.md').write_text('# G2 independent review evidence\n\nStart with `report/README.md` and `report/costs.md`. `audit/review-summary.json` contains exact subprocess results and matched measurements. `logs/` preserves stdout/stderr and hashed launch receipts. `godot/` and `blender/` contain fresh actual renders; `fixtures/` includes deliberately invalid save-recovery test cases as well as paid native checkpoints. They are test artifacts.\n\n`companions.json` identifies the complete verified sealed sources and disposable runtime. No normal save or cache is part of this package. Reproduction instructions and G2 tools are in `recipes/`. The Git receipt is intentionally outside the package to avoid a self-referential manifest hash. Main integration and push remain with the publisher.\n',encoding='utf-8')
rows={path.relative_to(HANDOFF).as_posix():{'bytes':path.stat().st_size,'sha256':sha(path)} for path in sorted(HANDOFF.rglob('*')) if path.is_file()}
(HANDOFF/'manifest.json').write_text(json.dumps({'scope':'G2 independent fresh review evidence, recipes, audit logs and test-only checkpoints; no generated engine caches or normal player data.','files':rows},indent=2),encoding='utf-8')
receipt=verify()
with (HANDOFF.parent/'handoff-receipt.json').open('x',encoding='utf-8') as stream:json.dump(receipt,stream,indent=2)
