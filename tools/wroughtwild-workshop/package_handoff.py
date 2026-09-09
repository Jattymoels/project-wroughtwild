"""Package the checked Red study, excluding engine caches and normal saves.
Usage: REVIEW EDITABLE ASSETS NATIVE FRESH_DESTINATION
"""
from pathlib import Path
import sys,json,hashlib,shutil
review,editable,assets,native,out=map(lambda p:Path(p).resolve(),sys.argv[1:6])
repo=Path(__file__).resolve().parents[2];recipe=Path(__file__).parent
assert not out.exists();out.mkdir(parents=True)
def ignored(directory,names):
    return [n for n in names if n=='.godot' or n.endswith(('.import','.uid','.blend1','.pyc')) or '_Image_' in n or n=='__pycache__']
shutil.copytree(review,out/'review',ignore=ignored)
shutil.copytree(editable,out/'editable',ignore=ignored)
shutil.copytree(recipe,out/'recipe',ignore=ignored)
(out/'provenance').mkdir()
for path in [assets/'asset-report.json',native/'provenance.json',repo/'build/workshop-art04/red-source-v01/generation.json',recipe/'source-prompt.txt']:
    shutil.copy2(path,out/'provenance'/path.name)
shutil.copy2(repo/'docs/art/leyline-studies/2026-09-09/workshop-art04/red-inclusion-input-v01.png',out/'provenance')
raw=repo/'build/workshop-art04/red-source-v01/rock.glb'
shutil.copy2(raw,out/'provenance/red-inclusion-untouched.glb')
shutil.copy2(recipe/'README.md',out/'README.md')
launch='''$ErrorActionPreference='Stop'
$artPreviousAppData=$env:APPDATA
try {
    $env:APPDATA=Join-Path $PSScriptRoot 'review-appdata'
    $artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
    $artProject=Join-Path $PSScriptRoot 'review'
    & $artGodot --headless --editor --import --quit --path $artProject
    if ($LASTEXITCODE -ne 0) { throw 'Review import failed.' }
    & $artGodot --path $artProject
} finally { $env:APPDATA=$artPreviousAppData }
'''
(out/'Launch review.ps1').write_text(launch,encoding='utf-8')
manifest={p.relative_to(out).as_posix():{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('ART04_HANDOFF_PACKAGED',len(manifest),'files',sum(r['bytes'] for r in manifest.values()),'bytes')
