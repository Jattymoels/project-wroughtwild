"""Immutable handoff assembly; generate hashes BEFORE engine import."""
import argparse,hashlib,json,shutil
from pathlib import Path

def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); ap.add_argument('--inspection',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
script=Path(__file__).resolve().parent; worker=script.parents[2]; out=a.output.resolve(); build=a.build.resolve()
assert out.is_relative_to(worker/'build/art07/d1') and not out.exists()
out.mkdir(parents=True); (out/'editable').mkdir(); (out/'proof').mkdir()
shutil.copy2(a.models/'core-lattice.blend',out/'editable/core-lattice.blend')
shutil.copy2(a.models/'geometry.json',out/'geometry.json')
shutil.copytree(script,out/'recipe',ignore=shutil.ignore_patterns('__pycache__'))
shutil.copytree(build/'snapshot/game',out/'review/game',ignore=shutil.ignore_patterns('.godot','*.import','*.log','evidence*'))
shutil.copytree(build/'snapshot/data',out/'review/data')
for name in ['prerequisites.json','assigned.json','original-inputs-final.json']:
    shutil.copy2(build/name,out/'proof'/name)
shutil.copy2(a.inspection/'reopen.json',out/'proof/blender-reopen.json')
for p in (build/'snapshot/game/art07_d1').glob('check-*.json'): shutil.copy2(p,out/'proof'/p.name)
shutil.copytree(a.models/'evidence',out/'evidence/blender')
shutil.copytree(a.inspection,out/'evidence/blender-inspection')
shutil.copytree(build/'snapshot/game/art07_d1/evidence',out/'evidence/godot')
shutil.copytree(worker/'docs/art/leyline-studies/2026-09-09/art07/d1',out/'evidence/curated')
shutil.copytree(build/'logs',out/'proof/logs',ignore=shutil.ignore_patterns('appdata','blender-user'))
launch='''param([ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$Visible)
$ErrorActionPreference='Stop'
$d1Source=$PSScriptRoot
$d1Copy=Join-Path (Split-Path $d1Source) ('review-copy-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
Copy-Item -LiteralPath (Join-Path $d1Source 'review') -Destination $d1Copy -Recurse
$d1App=$env:APPDATA
$d1Mutex=[Threading.Mutex]::new($false,'Local\\Wroughtwild-Art07-GPU')
$d1Owns=$false
try {
  $d1Owns=$d1Mutex.WaitOne(0)
  if (-not $d1Owns) { throw 'ART-07 GPU slot busy.' }
  if (Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }) { throw 'An art/playtest process is active; leave it undisturbed.' }
  $env:APPDATA=Join-Path $d1Copy 'appdata'
  New-Item -ItemType Directory $env:APPDATA | Out-Null
  $d1Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
  & $d1Godot --headless --path "$d1Copy/game" --import
  if ($LASTEXITCODE -ne 0) { throw 'Fresh import failed.' }
  $d1Window=if ($Visible) { 'Normal' } else { 'Hidden' }
  $d1Args='--path "'+$d1Copy+'/game" --audio-driver Dummy --rendering-method '+$Renderer+' res://art07_d1/gallery.tscn'
  $d1Process=Start-Process $d1Godot -ArgumentList $d1Args -WindowStyle $d1Window -PassThru
  $d1Process.WaitForExit()
} finally {
  $env:APPDATA=$d1App
  if ($d1Owns) { $d1Mutex.ReleaseMutex() }
  $d1Mutex.Dispose()
}
'''
(out/'Launch-review.ps1').write_text(launch)
(out/'README.md').write_text('# ART-07D1 handoff\n\nPacked editable core lattice master, ten GLBs and frozen native game review.\nRun `Launch-review.ps1 -Visible` for the posed gallery; `-Renderer gl_compatibility` selects Compatibility. The launcher copies before import and isolates saves. Native transaction tests are in `review/game/art07_d1/checks.tscn`; they use fixed inspection stock.\n\nNo normal-game adoption or owner visual acceptance is claimed. These ordinary pieces are static and unlit; the motion evidence is a camera orbit. Final materials, fine pieces and roofs remain separate slices. Recipes and full dimensional contract are in `recipe/README.md`.\n')
files={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps({'slice':'ART-07D1','base_revision':'56ce6bbe343012205690cf669491372958b80662','status':'technical review candidate; owner visual acceptance pending','files':files},indent=2)+'\n')
print('D1_HANDOFF',out,'manifest_sha256',sha(out/'manifest.json'),'files',len(files))
