param(
 [ValidateSet('import','transition','diagnostic')][string]$Job='transition',
 [string]$Output='D:/Wroughtwild/work/play03-underground/build/play03/transition',
 [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
$ErrorActionPreference='Stop'
$play03Root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$Output=[System.IO.Path]::GetFullPath($Output).Replace('\','/')
if(-not $Output.StartsWith('D:/',[System.StringComparison]::OrdinalIgnoreCase)){throw 'Test output/private state must stay on D:.'}
New-Item -ItemType Directory -Path $Output,"$Output/user","$Output/local","$Output/temp" -Force | Out-Null
$oldEnvironment=@{}
foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP','WROUGHTWILD_PLAY03_OUTPUT')){$oldEnvironment[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
$env:APPDATA="$Output/user"
$env:LOCALAPPDATA="$Output/local"
$env:TEMP="$Output/temp"
$env:TMP="$Output/temp"
$env:WROUGHTWILD_PLAY03_OUTPUT=$Output
$mutex=$null
$held=$false
$madeOverride=$false
$process=$null
$resultCode=1
$override="$play03Root/game/override.cfg"
$overrideText="[display]`nwindow/size/no_focus=true`nwindow/size/viewport_width=1280`nwindow/size/viewport_height=720`n"
$started=Get-Date
try {
 $arguments=@('--path',"`"$play03Root/game`"",'--audio-driver','Dummy')
 if($Job -eq 'import') {$arguments+=@('--headless','--editor','--import')}
 elseif($Job -eq 'transition') {
  $mutex=[System.Threading.Mutex]::new($false,'Local\WroughtwildArtRender')
  try {$held=$mutex.WaitOne(0)} catch [System.Threading.AbandonedMutexException] {$held=$true}
  if(-not $held) {throw 'RENDER_BUSY: no process launched.'}
  if(Test-Path -LiteralPath $override) {throw 'Existing override must be preserved.'}
  [System.IO.File]::WriteAllText($override,$overrideText,[System.Text.UTF8Encoding]::new($false))
  $madeOverride=$true
  $arguments+=@('--rendering-method','forward_plus','res://tests/play03_transition.tscn','--','--r8-no-mouse-capture')
 } else {$arguments+=@('--headless','res://tests/play03_diagnostic_check.tscn','--','--r8-no-mouse-capture')}
 $process=Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput "$Output/$Job.out.log" -RedirectStandardError "$Output/$Job.err.log"
 $processHandle=$process.Handle
 @{pid=$process.Id;started=$started.ToString('o');job=$Job} | ConvertTo-Json | Set-Content -LiteralPath "$Output/$Job-process.json"
 $timeout=300000
 while(-not $process.WaitForExit(1000)) {
  if(((Get-Date)-$started).TotalMilliseconds -gt $timeout){throw "Owned $Job exceeded its five-minute process limit."}
 }
 $process.WaitForExit()
 if($null -eq $process.ExitCode){throw 'Engine exit code unavailable.'}
 $resultCode=$process.ExitCode
 $errors=@(Select-String -LiteralPath "$Output/$Job.out.log","$Output/$Job.err.log" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|ERROR:')
 if($errors.Count -gt 0){$resultCode=1}
 @{exitCode=$resultCode;engineExitCode=$process.ExitCode;seconds=[Math]::Round(((Get-Date)-$started).TotalSeconds,2);reportedErrors=$errors.Count} | ConvertTo-Json | Set-Content -LiteralPath "$Output/$Job-result.json"
 Get-Content -LiteralPath "$Output/$Job-result.json"
 Get-Content -LiteralPath "$Output/$Job.out.log" -Tail 3
 Get-Content -LiteralPath "$Output/$Job.err.log" -Tail 12
} finally {
 if($null -ne $process -and -not $process.HasExited){$process.Kill();$process.WaitForExit()}
 if($madeOverride -and (Test-Path -LiteralPath $override)) {
  if([System.IO.File]::ReadAllText($override) -eq $overrideText){Remove-Item -LiteralPath $override}
  else {Write-Warning 'Changed override preserved for inspection.'}
 }
 if($held){$mutex.ReleaseMutex()}
 if($null -ne $mutex){$mutex.Dispose()}
 foreach($key in $oldEnvironment.Keys){[Environment]::SetEnvironmentVariable($key,$oldEnvironment[$key],'Process')}
}
exit $resultCode
