param([ValidateSet('Highland','Bank','Impact','Fresh')][string]$View='Highland')
# Owner-invoked ordinary game. Each view has its own persistent private progress.
$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$rfSlot=$View.ToLowerInvariant()
$rfState="$rfRoot/build/rf09/playtest-$rfSlot"
$rfPrior=@{}
foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP')){$rfPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
try {
 foreach($dir in @('user','local','temp')){New-Item -ItemType Directory -Path "$rfState/$dir" -Force | Out-Null}
 $env:APPDATA="$rfState/user"
 $env:LOCALAPPDATA="$rfState/local"
 $env:TEMP="$rfState/temp"
 $env:TMP="$rfState/temp"
 if($View -ne 'Fresh') {
  $rfSave="$rfState/user/Godot/app_userdata/Wroughtwild/wroughtwild_save.json"
  if(-not (Test-Path -LiteralPath $rfSave) -and -not (Test-Path -LiteralPath ($rfSave+'.previous'))) {
   $rfSource="$rfRoot/build/rf09/view-$rfSlot.json"
   if(-not (Test-Path -LiteralPath $rfSource)){throw "Retained RF-09 fixture is missing: $rfSource"}
   New-Item -ItemType Directory -Path (Split-Path $rfSave) -Force | Out-Null
   Copy-Item -LiteralPath $rfSource -Destination $rfSave
  }
  Write-Output "Choose Continue saved world. Persistent private progress: $rfSave"
  switch($View) {
   'Highland' {Write-Output 'Seed 77 highland: look west at the weathered outcrop, turf pockets and paid floor. Workbench is southwest; aim and press E.'}
   'Bank' {Write-Output 'Seed 77 dry far lake bank: look across the water through the shaded leaves. Walk along the bank, or wade and swim.'}
   'Impact' {Write-Output 'Seed 77 Rootvault impact: face north toward the old fragment and low recovery growth. Existing living scars pulse nearby.'}
  }
 } else {Write-Output 'Choose a class for a separate seed-77 New World, or Continue any progress already saved in this Fresh slot.'}
 Write-Output 'WASD/mouse move/look. E interacts. F5 saves. H shows controls. Normal enemies are active. Later launches keep private progress.'
 & 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' --path "$rfRoot/game" -- --world-seed=77
 if($LASTEXITCODE -ne 0){throw "Godot exited with code $LASTEXITCODE"}
} finally {foreach($key in $rfPrior.Keys){[Environment]::SetEnvironmentVariable($key,$rfPrior[$key],'Process')}}
