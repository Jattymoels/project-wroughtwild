"""Verify and apply declared R1 then R7 deltas to a fresh R7 prepared runtime."""
import argparse,shutil
from common import *
from package import verify
parser=argparse.ArgumentParser();parser.add_argument('package');parser.add_argument('runtime');args=parser.parse_args();guard()
source=Path(args.package).resolve();target=Path(args.runtime).resolve()
assert target.is_relative_to((ROOT/'build/art07-repairs/r7').resolve()) and target.name=='runtime'
verify(source);prepared=read(target.parent/'prepared.json');assert prepared['runtime_base']=='6bb2e044dcd0bf1788896aa2c19cdf56fee93522'
for name,row in prepared['original_files'].items():assert sha(target/name)==row['sha256'],name
r7=read(source/'changes.json');assert len(r7['parent_candidates'])==1;parent=r7['parent_candidates'][0]
pkg=Path(parent['path']);assert sha(pkg/'manifest.json')==parent['manifest_sha256'];verify(pkg)
for package,changes in [(pkg,read(pkg/'changes.json')['files']),(source,r7['files'])]:
    for row in changes:
        p=(target/row['path']).resolve();assert p.is_relative_to(target)
        assert (not p.exists()) if row['before_sha256'] is None else sha(p)==row['before_sha256'],row['path']
        assert sha(package/row['path'])==row['after_sha256']
    for row in changes:
        p=target/row['path'];p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(package/row['path'],p)
print('R7_APPLIED: published R1 once, followed by own R7 delta. Run fresh generated import/smoke jobs through the unchanged repair runner.')
