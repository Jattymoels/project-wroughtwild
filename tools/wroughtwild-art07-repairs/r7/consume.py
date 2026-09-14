"""Verify the prepared runtime and deliberately consume only published R1 delta."""
import shutil
from common import *
guard()
prepared=read(OUT/'prepared.json')
assert prepared['runtime_base']=='6bb2e044dcd0bf1788896aa2c19cdf56fee93522'
for name,row in prepared['original_files'].items():assert sha(OUT/'runtime'/name)==row['sha256'],name
receipt=read(ROOT/'docs/prototype/art07-repairs/2026-09-14/receipts/r1.json')
pkg=receipt['package'];source=Path(pkg['path']);assert sha(source/'manifest.json')==pkg['manifest_sha256']
manifest=read(source/'manifest.json');rows=manifest.get('files',manifest)
if isinstance(rows,list):rows={x['path']:x for x in rows}
assert len(rows)==pkg['files']
for name,row in rows.items():
    assert (source/name).stat().st_size==row['bytes'] and sha(source/name)==row['sha256'],name
changes=read(source/'changes.json')['files']
for row in changes:
    name=row['path'];target=OUT/'runtime'/name
    assert name=='game/g1/art.gd' or name.startswith('game/r1/'),name
    assert (not target.exists()) if row['before_sha256'] is None else sha(target)==row['before_sha256'],name
    assert sha(source/name)==row['after_sha256']
for row in changes:
    target=OUT/'runtime'/row['path'];target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source/row['path'],target)
write(OUT/'evidence/r1-consumption.json',{'parent':pkg,'published_commits':receipt['publication'],'runtime_base':prepared['runtime_base'],'files':changes,'verification':'Complete prepared original payload and complete published R1 payload hashed before copying. Only declared R1 runtime delta applied.'})
write(OUT/'evidence/parent-runtime-hashes.json',{p.relative_to(OUT/'runtime').as_posix():sha(p) for p in (OUT/'runtime').rglob('*') if p.is_file() and '.godot' not in p.parts})
print('R7_PARENT_CONSUMED',len(changes))
