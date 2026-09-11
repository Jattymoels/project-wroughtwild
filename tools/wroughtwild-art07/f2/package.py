"""Seal a fresh local F2 handoff; exclude imports, caches and ordinary saves."""
import hashlib,json,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
BUILD=ROOT/'build/art07/f2'
out=Path(sys.argv[1]).resolve();assert out.is_relative_to(BUILD);out.mkdir(parents=True,exist_ok=False)
def copy(src,dst):
    if src.is_dir():
        shutil.copytree(src,dst,ignore=shutil.ignore_patterns('.godot','*.import','__pycache__','*.pyc','*.blend1','evidence'))
    else:dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
copy(BUILD/'game01/game',out/'review');copy(BUILD/'game01/data',out/'data')
(out/'review/f2/evidence').mkdir()
copy(BUILD/'v03/devices',out/'source/devices');copy(BUILD/'v03/source',out/'source/thrumroot')
copy(BUILD/'v01/generated',out/'raw')
copy(BUILD/'v02/inspection',out/'source/inspection')
copy(HERE,out/'recipes')
copy(ROOT/'docs/art/leyline-studies/2026-09-09/art07/f2',out/'evidence/gallery')
copy(BUILD/'game01/game/f2/evidence',out/'evidence/godot')
copy(BUILD/'v01/native/provenance.json',out/'evidence/native-provenance.json')
copy(BUILD/'v01/inputs.json',out/'evidence/inputs-before.json')
copy(BUILD/'inputs-after.json',out/'evidence/inputs-after.json')
copy(BUILD/'scope-audit.json',out/'evidence/scope-audit.json')
for name in ['checks02','regression02','reopen-final','captures02','motion02','detail','benchmark02']:
    copy(BUILD/'v03'/name,out/'evidence'/name)
copy(BUILD/'v03/reopen-final.log.json',out/'evidence/reopen-command.json')
copy(BUILD/'v03/devices.log.json',out/'evidence/devices-command.json')
copy(BUILD/'v03/source.log.json',out/'evidence/source-command.json')
(out/'launch.ps1').write_text('''param([ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',
 [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')
$ErrorActionPreference='Stop'
$f2Project=Join-Path $PSScriptRoot 'review'
$env:APPDATA=Join-Path $PSScriptRoot 'isolated-user'
& $Godot --headless --path $f2Project --editor --import
if($LASTEXITCODE -ne 0){throw 'F2 import failed'}
& $Godot --path $f2Project --rendering-method $Renderer
''')
(out/'README.md').write_text('''# ART-07F2 local handoff

Run `./launch.ps1` (Forward+) or `./launch.ps1 -Renderer gl_compatibility`.
Godot 4.5 stable, Windows x64, existing native DLL included. Run in a fresh copy
to preserve this sealed package. Ordinary Godot import creates local caches.
The launcher isolates saves under `isolated-user/F2Native` and stays open until
Esc. Do not launch alongside another ART-07 GPU worker; use the shared mutex
wrapper from the worktree when reviewing there.

The study crafts a supported linked pair from explicitly granted inspection
supplies. Buttons perform original native transactions. 1 source, 2 drum,
3 landing, 4 span, G emission toggle, R reset the initial paid inspection.
Pause freezes both native travel and shader phase. One static recovered sample
appears when the pack owns roots; it is neither a pickup nor an inventory owner.

See `recipes/README.md` and `recipes/CONTRACTS.md` for reconstruction, controls,
exact costs, bounds, state/ownership/refund contracts and known limitations.
Original TRELLIS output is in `raw`; selected packed Blender masters, all LODs
and metric GLBs are in `source`; native study in `review` with sibling `data`.
No integration into the normal game or owner visual acceptance is claimed.
`manifest.json` hashes every supplied file except itself. Imports/saves created
after launch are not part of the sealed manifest. Review media is in `evidence`.
''')
files=[]
for p in sorted(out.rglob('*')):
    if p.is_file():files.append({'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
manifest=out/'manifest.json';manifest.write_text(json.dumps({'slice':'ART-07F2','base':'4b5d89b376765fbf4d46049aa099e0bb154a82da','files':files},indent=2)+'\n')
print('F2_PACKAGE',out,len(files),sum(f['bytes'] for f in files),hashlib.sha256(manifest.read_bytes()).hexdigest())
