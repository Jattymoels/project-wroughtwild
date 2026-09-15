param(
 [ValidateSet('import','native','restore')][string]$Job='native',
 [string]$Output='D:/Wroughtwild/work/mob05-nymph/build/mob05/integration',
 [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
 [switch]$Capture
)
$ErrorActionPreference='Stop'
$nymphRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
New-Item -ItemType Directory -Path $Output,"$Output/user","$Output/temp" -Force | Out-Null
$env:APPDATA="$Output/user"
$env:TEMP="$Output/temp"
$env:WROUGHTWILD_NYMPH_OUTPUT=$Output
$mutex=$null
$held=$false
$madeOverride=$false
$process=$null
$resultCode=1
$override="$nymphRoot/game/override.cfg"
$overrideText="[display]`nwindow/size/no_focus=true`nwindow/size/viewport_width=1024`nwindow/size/viewport_height=768`n"
$started=Get-Date
try {
 $arguments=@('--path',"$nymphRoot/game",'--audio-driver','Dummy')
 if($Job -eq 'import') {
  $arguments+=@('--headless','--editor','--import')
 } else {
  $arguments+="res://tests/mob05/$Job.tscn"
  if($Capture) {
   if($Job -ne 'native') {throw 'Only the native fixture needs rendered capture.'}
   $mutex=[System.Threading.Mutex]::new($false,'Local\WroughtwildArtRender')
   try {$held=$mutex.WaitOne(0)} catch [System.Threading.AbandonedMutexException] {$held=$true}
   if(-not $held) {Write-Output 'RENDER_BUSY: no process launched';exit 2}
   if(Test-Path -LiteralPath $override) {throw 'Existing override must be preserved.'}
   Set-Content -LiteralPath $override -Value $overrideText -NoNewline -Encoding utf8
   $madeOverride=$true
   $arguments+=@('--rendering-method','forward_plus','--fixed-fps','60','--','--r8-no-mouse-capture','--nymph-capture')
  } else {$arguments+=@('--headless','--','--r8-no-mouse-capture')}
 }
 $process=Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput "$Output/$Job.out.log" -RedirectStandardError "$Output/$Job.err.log"
 @{pid=$process.Id;started=$started.ToString('o');job=$Job;capture=[bool]$Capture} | ConvertTo-Json | Set-Content -LiteralPath "$Output/$Job-process.json" -Encoding utf8
 if(-not $process.WaitForExit(45000)) {
  Write-Output "Owned $Job still running after 45 seconds."
  if(-not $process.WaitForExit(45000)) {throw "Owned $Job reached its 90-second timeout."}
 }
 $process.WaitForExit()
 $resultCode=$process.ExitCode
 $errors=@(Select-String -LiteralPath "$Output/$Job.out.log","$Output/$Job.err.log" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:')
 if($errors.Count -gt 0) {$resultCode=1}
 @{exitCode=$resultCode;engineExitCode=$process.ExitCode;seconds=[Math]::Round(((Get-Date)-$started).TotalSeconds,2);reportedErrors=$errors.Count} | ConvertTo-Json | Set-Content -LiteralPath "$Output/$Job-result.json" -Encoding utf8
 Get-Content -LiteralPath "$Output/$Job-result.json"
 Get-Content -LiteralPath "$Output/$Job.out.log" -Tail 5
 Get-Content -LiteralPath "$Output/$Job.err.log" -Tail 16
} finally {
 if($null -ne $process -and -not $process.HasExited) {$process.Kill($true);$process.WaitForExit()}
 if($madeOverride -and (Test-Path -LiteralPath $override)) {
  if((Get-Content -LiteralPath $override -Raw) -eq $overrideText) {Remove-Item -LiteralPath $override}
  else {Write-Warning 'Override changed during the test; preserved for inspection.'}
 }
 if($held) {$mutex.ReleaseMutex()}
 if($null -ne $mutex) {$mutex.Dispose()}
}
exit $resultCode
