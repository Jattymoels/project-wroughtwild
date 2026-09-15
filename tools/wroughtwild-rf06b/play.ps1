param([switch]$Fen,[switch]$Fresh)
# Owner-invoked normal play. Separate private slots; never replace existing progress.
$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$rfMode=if($Fresh){'playtest-new'}elseif($Fen){'playtest-fen'}else{'playtest-lake'}
$rfState="$rfRoot/build/rf06b/$rfMode"
$rfPrior=@{}
foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP')){$rfPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
try {
 foreach($dir in @('user','local','temp')){New-Item -ItemType Directory -Path "$rfState/$dir" -Force | Out-Null}
 $env:APPDATA="$rfState/user"; $env:LOCALAPPDATA="$rfState/local"; $env:TEMP="$rfState/temp"; $env:TMP="$rfState/temp"
 if(-not $Fresh) {
  $rfSave="$rfState/user/Godot/app_userdata/Wroughtwild/wroughtwild_save.json"
  if(-not (Test-Path -LiteralPath $rfSave) -and -not (Test-Path -LiteralPath ($rfSave+".previous"))) {
   New-Item -ItemType Directory -Path (Split-Path $rfSave) -Force | Out-Null
   if($Fen) {
    $rfFixture=Get-Content -LiteralPath "$rfRoot/build/rf06b/checked-world.json" -Raw | ConvertFrom-Json
    $rfPoint=(Get-Content -LiteralPath "$rfRoot/build/rf06b/expected.json" -Raw | ConvertFrom-Json).fen
    $rfFixture.player.position=@([double]$rfPoint[0],([double]$rfPoint[1]+1.1),[double]$rfPoint[2])
    $rfFixture.player.yaw=[Math]::PI/2
    $rfFixture.player.pitch=-0.13
    [IO.File]::WriteAllText($rfSave,($rfFixture | ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($false))
   } else {Copy-Item -LiteralPath "$rfRoot/build/rf06b/checked-world.json" -Destination $rfSave}
  }
  Write-Output "Choose Continue saved world. Private slot: $rfSave"
  if($Fen){Write-Output 'You start on the checked fen floor facing west. Walk among the low leaves and taller groups; ordinary enemies remain active.'}
  else{Write-Output 'You start at the dry lake home facing toward the water. Walk toward the lake, pass the boulders, wade/swim and return to shore.'}
 } else {Write-Output 'Choose a class to start seed 77. F5 saves to this separate new-world slot.'}
 Write-Output 'WASD/mouse move and look; F5 saves; H shows controls. Close the game when finished. Later launches keep this private progress.'
 & 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --path "$rfRoot/game" -- --world-seed=77
} finally {foreach($key in $rfPrior.Keys){[Environment]::SetEnvironmentVariable($key,$rfPrior[$key],'Process')}}
