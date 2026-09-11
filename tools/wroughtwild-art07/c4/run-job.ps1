param([Parameter(Mandatory)][string]$Program,[Parameter(Mandatory)][string[]]$Arguments,[Parameter(Mandatory)][string]$Log,[switch]$Gpu,[int]$WaitSeconds=0)
$ErrorActionPreference='Stop'
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/c4'))
$artLog=[IO.Path]::GetFullPath($Log)
if(-not $artLog.StartsWith($artRoot+[IO.Path]::DirectorySeparatorChar)){throw 'Log must be in C4 output.'}
if(Test-Path -LiteralPath $artLog){throw 'Use fresh log.'}
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
$artPriorApp=$env:APPDATA;$artPriorLocal=$env:LOCALAPPDATA;$artPriorBlend=$env:BLENDER_USER_RESOURCES
try {
 if($Gpu){
  $artDeadline=(Get-Date).AddSeconds([Math]::Min($WaitSeconds,45))
  do {
   $artOwns=$artMutex.WaitOne(0)
   if($artOwns -and -not (Get-Process | Where-Object{$_.ProcessName -match 'godot|blender|trellis'})){break}
   if($artOwns){$artMutex.ReleaseMutex();$artOwns=$false}
   if((Get-Date) -ge $artDeadline){throw 'GPU slot or existing renderer busy; no other process changed.'}
   Start-Sleep -Milliseconds 1500
  } while($true)
 }
 $env:APPDATA=Join-Path (Split-Path $artLog) 'user';$env:LOCALAPPDATA=Join-Path (Split-Path $artLog) 'local-user';$env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $artLog) 'blender-user'
 New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,$env:BLENDER_USER_RESOURCES | Out-Null
 $artQuoted=($Arguments | ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' '
 $artStart=Get-Date
 $artProc=Start-Process -FilePath $Program -ArgumentList $artQuoted -PassThru -WindowStyle Hidden -RedirectStandardOutput $artLog -RedirectStandardError "$artLog.stderr"
 Write-Output "C4 own PID $($artProc.Id)"
 while(-not $artProc.WaitForExit(1000)){
  if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback' -Quiet){if(Get-Process -Id $artProc.Id -ErrorAction SilentlyContinue){Stop-Process -Id $artProc.Id}; $artProc.WaitForExit();throw "This C4 PID reported script/shader failure: $artLog"}
 }
 $artProc.Refresh()
 @{program=$Program;arguments=$Arguments;pid=$artProc.Id;exit=$artProc.ExitCode;seconds=((Get-Date)-$artStart).TotalSeconds;started_utc=$artStart.ToUniversalTime().ToString('o');finished_utc=(Get-Date).ToUniversalTime().ToString('o');gpu_slot=[bool]$Gpu;appdata=$env:APPDATA} | ConvertTo-Json -Depth 6 | Set-Content "$artLog.job.json"
 if($artProc.ExitCode -ne 0){throw "Job failed: $artLog"}
 if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback' -Quiet){throw "Diagnostic failure: $artLog"}
 Write-Output "C4_JOB_OK $artLog"
} finally {$env:APPDATA=$artPriorApp;$env:LOCALAPPDATA=$artPriorLocal;$env:BLENDER_USER_RESOURCES=$artPriorBlend;if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
