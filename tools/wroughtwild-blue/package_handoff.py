"""Pack one checked Blue review. Usage: REVIEW EDITABLE ASSETS SOURCE FRESH_OUT.
Original dense meshes and compiled/imported output remain under ignored build/.
"""
import sys,json,hashlib,shutil
from pathlib import Path
review,editable,assets,source,out=[Path(p).resolve() for p in sys.argv[1:6]]
repo=Path(__file__).resolve().parents[2];recipe=Path(__file__).parent
assert not out.exists();out.mkdir(parents=True)
for f in ['native-checks.json','native-restart.json','visual-checks.json']:
    assert not json.loads((review/'evidence'/f).read_text())['failures']
assert not json.loads((review/'evidence-compat/visual-checks.json').read_text())['failures']
assert not json.loads((editable/'asset-checks.json').read_text())['failures']
assert (review/'evidence/performance.json').is_file()
ignore=shutil.ignore_patterns('.godot','*.import','*.uid','__pycache__','*.blend1')
shutil.copytree(review,out/'review',ignore=ignore)
shutil.copytree(editable,out/'editable',ignore=ignore)
shutil.copytree(recipe,out/'recipe',ignore=ignore)
(out/'provenance').mkdir()
for f in ['rock.glb','generation.json','generation.log']:
    shutil.copy2(source/f,out/'provenance'/f)
shutil.copy2(assets/'asset-report.json',out/'provenance/asset-report.json')
shutil.copy2(recipe/'source-prompt.txt',out/'provenance/source-prompt.txt')
docs=repo/'docs/art/leyline-studies/2026-09-09/workshop-blue'
shutil.copy2(docs/'blue-fracture-input-v01.png',out/'provenance/blue-fracture-input-v01.png')
shutil.copy2(docs/'checks.json',out/'provenance/checks.json')
shutil.copy2(recipe/'run-review.ps1',out/'run-review.ps1')
(out/'Launch review.ps1').write_text("$ErrorActionPreference='Stop'\n& (Join-Path $PSScriptRoot 'run-review.ps1') -Project (Join-Path $PSScriptRoot 'review') -Mode import\n& (Join-Path $PSScriptRoot 'run-review.ps1') -Project (Join-Path $PSScriptRoot 'review') -Mode open\n")
shutil.copy2(recipe/'README.md',out/'README.md')
manifest={str(p.relative_to(out)).replace('\\','/'):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps({'files':manifest,'file_count':len(manifest),'bytes':sum(v['bytes'] for v in manifest.values())},indent=2))
for name,record in manifest.items():assert hashlib.sha256((out/name).read_bytes()).hexdigest()==record['sha256']
print('BLUE_PACKAGE_VERIFIED',len(manifest),'files',sum(v['bytes'] for v in manifest.values()),'bytes')
