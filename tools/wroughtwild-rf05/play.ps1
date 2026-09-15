param([switch]$CheckedLake)
# User-invoked ordinary play. Runs no automation and keeps owner saves separate.
$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$rfMode=if($CheckedLake){'playtest-checked-home'}else{'playtest-new'}
$rfState="$rfRoot/build/rf05/$rfMode"
$rfPrior=@{};foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP')){$rfPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
try {
 foreach($dir in @('user','local','temp')){New-Item -ItemType Directory -Path "$rfState/$dir" -Force | Out-Null}
 $env:APPDATA="$rfState/user"; $env:LOCALAPPDATA="$rfState/local"; $env:TEMP="$rfState/temp"; $env:TMP="$rfState/temp"
 if($CheckedLake) {
  $rfSave="$rfState/user/Godot/app_userdata/Wroughtwild/wroughtwild_save.json"
  if(-not (Test-Path -LiteralPath $rfSave)) {
   New-Item -ItemType Directory -Path (Split-Path $rfSave) -Force | Out-Null
   Copy-Item -LiteralPath "$rfRoot/build/rf05/private-world.json" -Destination $rfSave
  }
  Write-Output 'Choose Continue saved world to enter the checked, paid lakeside floor and afloat save. Later saves stay in this private playtest folder.'
 } else {Write-Output 'Choose a class for New World seed 77. F5 saves here; next launch offers Continue. Owner saves are separate.'}
 & 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --path "$rfRoot/game" -- --world-seed=77
} finally {foreach($key in $rfPrior.Keys){[Environment]::SetEnvironmentVariable($key,$rfPrior[$key],'Process')}}
