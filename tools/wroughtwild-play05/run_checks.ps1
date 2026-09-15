param(
 [ValidateSet('import','reproduce','transfers','restore')][string]$Job='transfers',
 [string]$Output='',
 [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
$ErrorActionPreference='Stop'
$play05Root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
if(-not $Output){$Output="$play05Root/build/play05/checks"}
$Output=[System.IO.Path]::GetFullPath($Output).Replace('\','/')
if(-not $Output.StartsWith('D:/',[System.StringComparison]::OrdinalIgnoreCase)){throw 'Test output/private state must stay on D:.'}
New-Item -ItemType Directory -Path $Output,"$Output/user","$Output/local","$Output/temp" -Force | Out-Null
$oldEnvironment=@{}
foreach($key in @('APPDATA','LOCALAPPDATA','TEMP','TMP','WROUGHTWILD_PLAY05_OUTPUT')){$oldEnvironment[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
$env:APPDATA="$Output/user"
$env:LOCALAPPDATA="$Output/local"
$env:TEMP="$Output/temp"
$env:TMP="$Output/temp"
$env:WROUGHTWILD_PLAY05_OUTPUT=$Output
$process=$null
$resultCode=1
$started=Get-Date
try {
 $arguments=@('--path',"`"$play05Root/game`"",'--headless','--audio-driver','Dummy')
 if($Job -eq 'import') {$arguments+=@('--editor','--import')}
 else {$arguments+=@('res://tests/play05_chest.tscn','--','--r8-no-mouse-capture',"--play05-$Job")}
 $process=Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput "$Output/$Job.out.log" -RedirectStandardError "$Output/$Job.err.log"
 # Retain the native handle so Windows PowerShell can report the exit code.
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
 if($Job -ne 'import' -and -not (Select-String -LiteralPath "$Output/$Job.out.log" -Pattern "PLAY05_$($Job.ToUpper()) [0-9]+ checks, 0 failures")){$resultCode=1}
 @{exitCode=$resultCode;engineExitCode=$process.ExitCode;seconds=[Math]::Round(((Get-Date)-$started).TotalSeconds,2);reportedErrors=$errors.Count} | ConvertTo-Json | Set-Content -LiteralPath "$Output/$Job-result.json"
 Get-Content -LiteralPath "$Output/$Job-result.json"
 Get-Content -LiteralPath "$Output/$Job.out.log" -Tail 4
 Get-Content -LiteralPath "$Output/$Job.err.log" -Tail 18
} finally {
 if($null -ne $process -and -not $process.HasExited){$process.Kill();$process.WaitForExit()}
 if($null -ne $process){$process.Dispose()}
 foreach($key in $oldEnvironment.Keys){[Environment]::SetEnvironmentVariable($key,$oldEnvironment[$key],'Process')}
}
exit $resultCode
