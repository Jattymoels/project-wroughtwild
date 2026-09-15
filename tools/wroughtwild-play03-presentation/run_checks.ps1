param(
 [ValidateSet('import','after','lifecycle')][string]$Job='after',
 [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$rfOutput="$rfRoot/build/play03-presentation"
foreach($dir in @($rfOutput,"$rfOutput/user","$rfOutput/local","$rfOutput/temp","$rfOutput/logs","$rfOutput/media")) {
 New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
$rfPrior=@{};foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP','WROUGHTWILD_ARRIVAL_OUTPUT')){$rfPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
# Isolated arrival checks; no owner save or prior worker state is copied.
$env:APPDATA="$rfOutput/user"
$env:LOCALAPPDATA="$rfOutput/local"
$env:TEMP="$rfOutput/temp"
$env:TMP="$rfOutput/temp"
$env:WROUGHTWILD_ARRIVAL_OUTPUT="$rfOutput/$Job"
New-Item -ItemType Directory -Force -Path $env:WROUGHTWILD_ARRIVAL_OUTPUT | Out-Null
$mutex=$null
$held=$false
$madeOverride=$false
$process=$null
$resultCode=1
$override="$rfRoot/game/override.cfg"
$overrideText="[display]`nwindow/size/no_focus=true`nwindow/size/viewport_width=1280`nwindow/size/viewport_height=720`n"
$started=Get-Date
$stamp=$started.ToString('yyyyMMdd-HHmmss')
$log="$rfOutput/logs/$Job-$stamp"
try {
 $arguments=@('--path',"$rfRoot/game",'--audio-driver','Dummy')
 if($Job -eq 'import') {
  $arguments+=@('--headless','--editor','--import')
 } else {
  $arguments+= $(if($Job -eq 'lifecycle'){'res://tests/play03_presentation_lifecycle.tscn'}else{'res://tests/play03_presentation.tscn'})
  if($Job -eq 'after') {
   $mutex=[System.Threading.Mutex]::new($false,'Local\WroughtwildArtRender')
   try {$held=$mutex.WaitOne(0)} catch [System.Threading.AbandonedMutexException] {$held=$true}
   if(-not $held) {Write-Output 'RENDER_BUSY: no process launched';exit 2}
   if(Test-Path -LiteralPath $override) {throw 'Existing override must be preserved.'}
   [System.IO.File]::WriteAllText($override,$overrideText,[System.Text.UTF8Encoding]::new($false))
   $madeOverride=$true
   $arguments+=@('--rendering-method','forward_plus','--','--r8-no-mouse-capture')
  } else {$arguments+=@('--headless','--','--r8-no-mouse-capture','--arrival-lifecycle')}
 }
 $process=Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput "$log.out.log" -RedirectStandardError "$log.err.log"
 $processHandle=$process.Handle
 @{pid=$process.Id;started=$started.ToString('o');job=$Job} | ConvertTo-Json | Set-Content -LiteralPath "$log.process.json" -Encoding utf8
 $waits=0
 while(-not $process.WaitForExit(5000)) {
  $waits++
  if($waits % 9 -eq 0) {Write-Output "Owned $Job still running ($($waits*5) seconds); PID $($process.Id)."}
  if(@(Select-String -LiteralPath "$log.out.log","$log.err.log" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:').Count -gt 0) {$process.Kill();break}
  if($waits -ge 48) {throw "Owned $Job reached its focused-run timeout."}
 }
 $process.WaitForExit()
 if($null -eq $process.ExitCode) {throw 'Engine exit code unavailable.'}
 $resultCode=$process.ExitCode
 $errors=@(Select-String -LiteralPath "$log.out.log","$log.err.log" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:')
 if($errors.Count -gt 0) {$resultCode=1}
 @{exitCode=$resultCode;engineExitCode=$process.ExitCode;seconds=[Math]::Round(((Get-Date)-$started).TotalSeconds,2);reportedErrors=$errors.Count;log=$log} | ConvertTo-Json | Set-Content -LiteralPath "$rfOutput/$Job-result.json" -Encoding utf8
 Get-Content -LiteralPath "$rfOutput/$Job-result.json"
 Get-Content -LiteralPath "$log.out.log" -Tail 8
 Get-Content -LiteralPath "$log.err.log" -Tail 24
} finally {
 if($null -ne $process -and -not $process.HasExited) {$process.Kill($true);$process.WaitForExit()}
 if($madeOverride -and (Test-Path -LiteralPath $override)) {
  if((Get-Content -LiteralPath $override -Raw) -eq $overrideText) {Remove-Item -LiteralPath $override}
  else {Write-Warning 'Override changed during test; preserved.'}
 }
 if($held) {$mutex.ReleaseMutex()}
 if($null -ne $mutex) {$mutex.Dispose()}
 foreach($key in $rfPrior.Keys){[Environment]::SetEnvironmentVariable($key,$rfPrior[$key],'Process')}
}
exit $resultCode
