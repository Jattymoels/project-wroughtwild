"""Apply only the R1 delta to a fresh prepared R1 G1 runtime; never a peer/owner tree."""
import argparse,json,shutil,subprocess
from pathlib import Path
from measure import ROOT,sha
from package import verify
parser=argparse.ArgumentParser();parser.add_argument('package');parser.add_argument('runtime');args=parser.parse_args()
source=Path(args.package).resolve();target=Path(args.runtime).resolve()
assert subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()=='codex/art07-r1'
assert target.is_relative_to((ROOT/'build/art07-repairs/r1').resolve()) and target.name=='runtime'
prepared=json.loads((target.parent/'prepared.json').read_text());assert prepared['runtime_base']=='6bb2e044dcd0bf1788896aa2c19cdf56fee93522'
verify(source)
for name,row in prepared['original_files'].items():assert sha(target/name)==row['sha256'],('Prepared base differs',name)
changes=json.loads((source/'changes.json').read_text())['files']
for change in changes:
    name=change['path'];p=(target/name).resolve();assert p.is_relative_to(target)
    assert name=='game/g1/art.gd' or name.startswith('game/r1/')
    if change['before_sha256'] is None:assert not p.exists(),name
    else:assert sha(p)==change['before_sha256'],name
    assert sha(source/name)==change['after_sha256'],name
for change in changes:
    p=target/change['path'];p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source/change['path'],p)
    assert sha(p)==change['after_sha256']
print('R1_DELTA_APPLIED',len(changes),'files; run the generated import-smoke.json through the repair runner')
