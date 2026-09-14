"""Apply this R6 delta to a byte-matching, fresh private copy of the G1 baseline."""
import argparse
import json
import shutil
from pathlib import Path
from package import verify
from stage import sha

parser=argparse.ArgumentParser()
parser.add_argument('--baseline',type=Path,required=True)
parser.add_argument('--package',type=Path,required=True)
parser.add_argument('--out',type=Path,required=True)
args=parser.parse_args()
assert not args.out.exists(),'Refuse overwrite; use a fresh private destination.'
assert args.out.resolve().is_relative_to(Path('D:/project-wroughtwild-art07-r6/build/art07-repairs/r6').resolve()),'Reconstruction stays in the assigned R6 build tree.'
verify(args.package)
manifest=json.loads((args.baseline/'manifest.json').read_text(encoding='utf-8-sig'))
assert sha(args.baseline/'manifest.json')=='fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd'
rows=manifest.get('files',manifest)
if isinstance(rows,list):rows={row['path']:row for row in rows}
for name,row in rows.items():
    if Path(name).parts[0] not in ['game','data','engine']:continue
    source=(args.baseline/name).resolve()
    assert source.is_relative_to(args.baseline.resolve()) and sha(source)==row['sha256'],name
    target=args.out/name
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,target)
changes=json.loads((args.package/'changes.json').read_text(encoding='utf-8-sig'))
for row in changes['files']:
    target=(args.out/row['path']).resolve()
    assert target.is_relative_to(args.out.resolve())
    if row['before_sha256'] is None: assert not target.exists()
    else: assert sha(target)==row['before_sha256'],row['path']
    source=args.package/row['path']
    assert sha(source)==row['after_sha256']
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,target)
print('R6_APPLIED verified baseline-relative delta to',args.out)
