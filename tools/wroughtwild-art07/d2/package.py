"""Immutable handoff assembly; generate hashes BEFORE engine import."""
import argparse,hashlib,json,shutil
from pathlib import Path

def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); ap.add_argument('--inspection',type=Path,required=True); ap.add_argument('--native',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
script=Path(__file__).resolve().parent; worker=script.parents[2]; out=a.output.resolve(); build=a.build.resolve()
assert out.is_relative_to(worker/'build/art07/d2') and not out.exists()
out.mkdir(parents=True); (out/'editable').mkdir(); (out/'proof').mkdir()
shutil.copy2(a.models/'roof-joinery-spans.blend',out/'editable/roof-joinery-spans.blend')
shutil.copy2(a.models/'geometry.json',out/'geometry.json')
shutil.copytree(script,out/'recipe',ignore=shutil.ignore_patterns('__pycache__'))
shutil.copytree(build/'snapshot/game',out/'review/game',ignore=shutil.ignore_patterns('.godot','*.import','*.log','evidence*'))
shutil.copytree(build/'snapshot/data',out/'review/data')
for name in ['prerequisites.json','assigned.json','original-inputs-final.json']:
    shutil.copy2(build/name,out/'proof'/name)
shutil.copy2(a.inspection/'reopen.json',out/'proof/blender-reopen.json')
for p in (build/'snapshot/game/art07_d2').glob('check-*.json'): shutil.copy2(p,out/'proof'/p.name)
shutil.copytree(a.models/'evidence',out/'evidence/blender')
shutil.copytree(a.inspection,out/'evidence/blender-inspection')
for renderer in ['forward_plus','gl_compatibility']:
    shutil.copytree(build/'snapshot/game/art07_d2/evidence'/renderer/'v03',out/'evidence/godot'/renderer)
shutil.copytree(worker/'docs/art/leyline-studies/2026-09-09/art07/d2',out/'evidence/curated',ignore=shutil.ignore_patterns('handoff-verification.json','README.md'))
shutil.copytree(build/'logs',out/'proof/logs',ignore=shutil.ignore_patterns('appdata','blender-user'))
shutil.copy2(a.native/'provenance.json',out/'proof/native-provenance.json')
for name in ['compile.log','tests.log']: shutil.copy2(build/'sim-suite'/name,out/'proof'/('sim-'+name))
launch='''param([ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$Visible)
$ErrorActionPreference='Stop'
$d2Source=$PSScriptRoot
$d2Copy=Join-Path (Split-Path $d2Source) ('review-copy-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
Copy-Item -LiteralPath (Join-Path $d2Source 'review') -Destination $d2Copy -Recurse
$d2App=$env:APPDATA
$d2Mutex=[Threading.Mutex]::new($false,'Local\\Wroughtwild-Art07-GPU')
$d2Owns=$false
try {
  $d2Owns=$d2Mutex.WaitOne(0)
  if (-not $d2Owns) { throw 'ART-07 GPU slot busy.' }
  if (Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }) { throw 'An art/playtest process is active; leave it undisturbed.' }
  $env:APPDATA=Join-Path $d2Copy 'appdata'
  New-Item -ItemType Directory $env:APPDATA | Out-Null
  $d2Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
  & $d2Godot --headless --path "$d2Copy/game" --import
  if ($LASTEXITCODE -ne 0) { throw 'Fresh import failed.' }
  $d2Window=if ($Visible) { 'Normal' } else { 'Hidden' }
  $d2Args='--path "'+$d2Copy+'/game" --audio-driver Dummy --rendering-method '+$Renderer+' res://art07_d2/gallery.tscn'
  $d2Process=Start-Process $d2Godot -ArgumentList $d2Args -WindowStyle $d2Window -PassThru
  $d2Process.WaitForExit()
} finally {
  $env:APPDATA=$d2App
  if ($d2Owns) { $d2Mutex.ReleaseMutex() }
  $d2Mutex.Dispose()
}
'''
(out/'Launch-review.ps1').write_text(launch)
(out/'README.md').write_text('# ART-07D2 handoff\n\nPacked editable roof/joinery/span master, seven D2 GLBs plus verified D1 context and frozen native game review.\nRun `Launch-review.ps1 -Visible` for the posed gallery; `-Renderer gl_compatibility` selects Compatibility. The launcher copies before import and isolates saves. Native transaction tests are in `review/game/art07_d2/checks.tscn`; they use fixed inspection stock.\n\nNo normal-game adoption or owner visual acceptance is claimed. Ordinary pieces are unlit. Motion evidence records actual E door state changes; the native door switches pose without a tween. Fine pieces, final material integration and ordinary-world adoption remain separate. Recipes and full dimensional contract are in `recipe/README.md`.\n')
files={p.relative_to(out).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(out.rglob('*')) if p.is_file()}
(out/'manifest.json').write_text(json.dumps({'slice':'ART-07D2','base_revision':'0f35e87c6a23e3197bec968fa4443c8e134317b3','status':'technical review candidate; owner visual acceptance pending','files':files},indent=2)+'\n')
print('D2_HANDOFF',out,'manifest_sha256',sha(out/'manifest.json'),'files',len(files))
