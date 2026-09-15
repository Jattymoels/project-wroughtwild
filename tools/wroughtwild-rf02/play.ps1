# Owner-launched normal play with separate RF02 saves/preferences.
# Interactive by design: ordinary game mouse-look and controls apply.
$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$rfPlay=Join-Path $rfRoot 'build/rf02/manual-play'
$rfPrior=@{}
foreach($name in @('APPDATA','LOCALAPPDATA','TEMP','TMP')) {$rfPrior[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try {
 foreach($name in @('user','local','temp')) {New-Item -ItemType Directory -Path (Join-Path $rfPlay $name) -Force | Out-Null}
 $env:APPDATA=Join-Path $rfPlay 'user'
 $env:LOCALAPPDATA=Join-Path $rfPlay 'local'
 $env:TEMP=Join-Path $rfPlay 'temp'
 $env:TMP=$env:TEMP
 & 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --path (Join-Path $rfRoot 'game') -- --world-seed=77
} finally {
 foreach($name in $rfPrior.Keys) {[Environment]::SetEnvironmentVariable($name,$rfPrior[$name],'Process')}
}
