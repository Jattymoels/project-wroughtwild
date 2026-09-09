"""Package one frozen, checked actual-game pilot. Exclude caches and live user data."""
import hashlib,json,shutil,sys
from pathlib import Path
run=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve();root=Path(__file__).resolve().parents[2]
assert out.is_relative_to(root/'build') and not out.exists(),'Use a fresh destination under build/'
out.mkdir(parents=True)
def ignore(path,names):return [n for n in names if n=='.godot' or n.startswith('art05_probe.')]
shutil.copytree(run/'game',out/'game',ignore=ignore);shutil.copytree(run/'data',out/'data')
frame_manifest=json.loads((run/'evidence-art/captured-frames.json').read_text(encoding='utf-8'))
valid_frames={p for entry in frame_manifest.values() for p in entry['frames']}
def evidence_ignore(path,names):
    parent=Path(path)
    if parent.name in ('walk','combat'):return [n for n in names if parent.name+'/'+n not in valid_frames]
    return []
for name in ('evidence-art','evidence-baseline'):shutil.copytree(run/name,out/name,ignore=evidence_ignore)
checkpoint=run/'game/art05/route-checkpoint.json'
assert checkpoint.exists(),'Run the complete paid route first'
shutil.copy2(checkpoint,out/'game/art05/route-checkpoint.json')
runner=(root/'tools/wroughtwild-route/run.ps1').read_text(encoding='utf-8').replace("='build/art05/baseline-v01/game'","=(Join-Path $PSScriptRoot 'game')")
(out/'Check route.ps1').write_text(runner,encoding='utf-8')
shutil.copy2(root/'tools/wroughtwild-route/README.md',out/'README.md')
native=run/'native/provenance.json'
if not native.exists():native=run.parent/'native-v02/provenance.json'
shutil.copy2(native,out/'native-provenance.json')
(out/'Launch route.ps1').write_text('''$ErrorActionPreference='Stop'
$game=Join-Path $PSScriptRoot 'game'
$env:APPDATA=Join-Path $PSScriptRoot 'user-data'
$godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
& $godot --headless --path $game --editor --import --quit
if($LASTEXITCODE -ne 0){throw 'Import failed'}
$arguments=@('--path',('"'+$game+'"'),'res://art05/play.tscn','--','--living-frontier-wave3','--art05')
$process=Start-Process -FilePath $godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
@{pid=$process.Id;project=$game;appdata=$env:APPDATA}|ConvertTo-Json|Set-Content (Join-Path $PSScriptRoot 'last-launch.json')
''',encoding='utf-8')
files={}
for p in sorted(out.rglob('*')):
 if p.is_file():files[p.relative_to(out).as_posix()]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
manifest={'baseline':'8aec10ef3b1df190e23fc4f32bc910877e8ded86','files':files,'bytes':sum(v['bytes'] for v in files.values()),'note':'Full isolated game/data and cooked pilot assets. Original editable handoffs remain under build/boar-art01, build/grove-art02 and build/workshop-art04. No normal save, imported cache or live native DLL was copied.'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('ART05_PACKAGE_OK',len(files),manifest['bytes'])
