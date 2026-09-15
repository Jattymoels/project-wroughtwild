param([switch]$Trace)
# Owner-invoked ordinary game only; never called by the automated check runner.
$ErrorActionPreference='Stop'
$playRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$playState="$playRoot/build/play03-group/playtest"
$sourceSave="$playRoot/build/play03-group/group-start.json"
$playSave="$playState/user/Godot/app_userdata/Wroughtwild/wroughtwild_save.json"
$playPrior=@{}
foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP')){$playPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
try {
 foreach($dir in @('user','local','temp','traces')){New-Item -ItemType Directory -Path "$playState/$dir" -Force | Out-Null}
 $env:APPDATA="$playState/user"
 $env:LOCALAPPDATA="$playState/local"
 $env:TEMP="$playState/temp"
 $env:TMP="$playState/temp"
 if(-not (Test-Path -LiteralPath $playSave)) {
  if(-not (Test-Path -LiteralPath $sourceSave)){throw 'Retained group-start.json is required from the worker handoff.'}
  New-Item -ItemType Directory -Path (Split-Path $playSave) -Force | Out-Null
  Copy-Item -LiteralPath $sourceSave -Destination $playSave
 }
 Write-Output 'Choose Continue saved world / suspended trial. On first use this private RF-05 save starts outside the generated mixed group, facing it. Hold W briefly, then press X outside build mode to sound the horn and call the nearby packs.'
 Write-Output 'This isolated fixture adds one shrieker horn and changes only the starting pose otherwise; it is not the owner save.'
 Write-Output 'The mouse stays free. F5 saves to this separate playtest slot; later launches keep that saved progress. The owner save slot is untouched.'
 $playArgs=@('--path',"$playRoot/game",'--','--world-seed=77','--r8-no-mouse-capture')
 if($Trace){$playArgs+="--play03-trace=$playState/traces"}
 & 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' @playArgs
} finally {
 foreach($key in $playPrior.Keys){[Environment]::SetEnvironmentVariable($key,$playPrior[$key],'Process')}
}
