"""Immutable handoff assembly; generate hashes BEFORE engine import."""
import argparse,hashlib,json,shutil
from pathlib import Path

def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); ap.add_argument('--inspection',type=Path,required=True); ap.add_argument('--native',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
script=Path(__file__).resolve().parent; worker=script.parents[2]; out=a.output.resolve(); build=a.build.resolve()
assert out.is_relative_to(worker/'build/art07/d3') and not out.exists()
out.mkdir(parents=True); (out/'editable').mkdir(); (out/'proof').mkdir()
shutil.copy2(a.models/'fine-coverings.blend',out/'editable/fine-coverings.blend')
shutil.copy2(a.models/'geometry.json',out/'geometry.json')
shutil.copytree(script,out/'recipe',ignore=shutil.ignore_patterns('__pycache__'))
shutil.copytree(build/'snapshot/game',out/'review/game',ignore=shutil.ignore_patterns('.godot','*.import','*.log','evidence*'))
shutil.copytree(build/'snapshot/data',out/'review/data')
for name in ['prerequisites.json','assigned.json','original-inputs-final.json','source-audit.json','shelf-negative-control.json']:
    shutil.copy2(build/name,out/'proof'/name)
shutil.copy2(a.inspection/'reopen.json',out/'proof/blender-reopen.json')
shutil.copy2(a.native/'provenance.json',out/'proof/native-provenance.json')
shutil.copy2(a.native/'build.log',out/'proof/native-build.log')
for p in (build/'snapshot/game/art07_d3').glob('check-*.json'): shutil.copy2(p,out/'proof'/p.name)
shutil.copytree(a.models/'evidence',out/'evidence/blender')
shutil.copytree(a.inspection,out/'evidence/blender-inspection')
shutil.copytree(build/'snapshot/game/art07_d3/evidence',out/'evidence/godot')
shutil.copytree(worker/'docs/art/leyline-studies/2026-09-09/art07/d3',out/'evidence/curated')
shutil.copytree(build/'logs',out/'proof/logs',ignore=shutil.ignore_patterns('appdata','blender-user'))
launch='''param([ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$Visible)
$ErrorActionPreference='Stop'
$d3Source=$PSScriptRoot
$d3Copy=Join-Path (Split-Path $d3Source) ('review-copy-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
Copy-Item -LiteralPath (Join-Path $d3Source 'review') -Destination $d3Copy -Recurse
$d3App=$env:APPDATA
$d3Mutex=[Threading.Mutex]::new($false,'Local\\Wroughtwild-Art07-GPU')
$d3Owns=$false
try {
  $d3Owns=$d3Mutex.WaitOne(0)
  if (-not $d3Owns) { throw 'ART-07 GPU slot busy.' }
  if (Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }) { throw 'An art/playtest process is active; leave it undisturbed.' }
  $env:APPDATA=Join-Path $d3Copy 'appdata'
  New-Item -ItemType Directory $env:APPDATA | Out-Null
  $d3Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
  & $d3Godot --headless --path "$d3Copy/game" --import
  if ($LASTEXITCODE -ne 0) { throw 'Fresh import failed.' }
  $d3Window=if ($Visible) { 'Normal' } else { 'Hidden' }
  $d3Args='--path "'+$d3Copy+'/game" --audio-driver Dummy --rendering-method '+$Renderer+' res://art07_d3/gallery.tscn'
  $d3Process=Start-Process $d3Godot -ArgumentList $d3Args -WindowStyle $d3Window -PassThru
  $d3Process.WaitForExit()
} finally {
  $env:APPDATA=$d3App
  if ($d3Owns) { $d3Mutex.ReleaseMutex() }
  $d3Mutex.Dispose()
}
'''
(out/'Launch-review.ps1').write_text(launch)
(out/'README.md').write_text('# ART-07D3 handoff\n\nPacked editable fine/covering master, twelve D3 GLBs, five verified D1 coarse references and frozen native game review.\nRun `Launch-review.ps1 -Visible` for the posed gallery; `-Renderer gl_compatibility` selects Compatibility. Left/right arrows orbit, N toggles clay/material, Escape exits. The launcher copies before import and isolates saves. Native transaction tests are in `review/game/art07_d3/checks.tscn`; they use fixed inspection stock.\n\nThese ordinary pieces are static and unlit; motion evidence is a camera orbit. The native material library supplies all 85 legal pairings, including complete reed/cork coverings and fixed cinderglass. Final material-source integration, roofs, ordinary-world adoption and owner visual acceptance remain separate. Recipes and dimensions are in `recipe/README.md`.\n')
files={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps({'slice':'ART-07D3','base_revision':'0f35e87c6a23e3197bec968fa4443c8e134317b3','status':'technical review candidate; owner visual acceptance pending','files':files},indent=2)+'\n')
print('D3_HANDOFF',out,'manifest_sha256',sha(out/'manifest.json'),'files',len(files))
