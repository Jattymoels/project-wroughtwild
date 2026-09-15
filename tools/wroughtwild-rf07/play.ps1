param([switch]$Fresh)
# Owner-invoked ordinary play with private progress preserved across launches.
$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$rfMode=if($Fresh){'playtest-new'}else{'playtest-highland'}
$rfState="$rfRoot/build/rf07/$rfMode"
$rfPrior=@{}
foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP')){$rfPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
try {
 foreach($dir in @('user','local','temp')){New-Item -ItemType Directory -Path "$rfState/$dir" -Force | Out-Null}
 $env:APPDATA="$rfState/user"
 $env:LOCALAPPDATA="$rfState/local"
 $env:TEMP="$rfState/temp"
 $env:TMP="$rfState/temp"
 if(-not $Fresh) {
  $rfSave="$rfState/user/Godot/app_userdata/Wroughtwild/wroughtwild_save.json"
  if(-not (Test-Path -LiteralPath $rfSave) -and -not (Test-Path -LiteralPath ($rfSave+".previous"))) {
   New-Item -ItemType Directory -Path (Split-Path $rfSave) -Force | Out-Null
   Copy-Item -LiteralPath "$rfRoot/build/rf07/checked-world.json" -Destination $rfSave
  }
  Write-Output "Choose Continue saved world. Private progress: $rfSave"
  Write-Output 'Seed 77 highland bench: (840.5, 69, 708.5), facing east. The paid octagonal floor is just behind/left; the paid workbench is south, to your right.'
  Write-Output 'Explore the rocky shoulder and growth pockets, walk onto the floor, then aim at the workbench and press E.'
 } else {Write-Output 'Choose a class to start a separate seed-77 world at its normal opening. F5 saves to this private new-world slot.'}
 Write-Output 'WASD/mouse: move/look. E: interact. F5: save. H: controls. Normal enemies remain active. Close the game when finished; later launches retain your private progress.'
 & 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --path "$rfRoot/game" -- --world-seed=77
} finally {foreach($key in $rfPrior.Keys){[Environment]::SetEnvironmentVariable($key,$rfPrior[$key],'Process')}}
