param([Parameter(Mandatory)][string]$Program,[Parameter(Mandatory)][string[]]$Arguments,[Parameter(Mandatory)][string]$Log,[switch]$Gpu)
$ErrorActionPreference='Stop'
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/c6'))
$artLog=[IO.Path]::GetFullPath($Log)
if(-not $artLog.StartsWith($artRoot+[IO.Path]::DirectorySeparatorChar)){throw 'Log must be in C6 output.'}
if(Test-Path -LiteralPath $artLog){throw 'Use fresh log.'}
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
$artPriorApp=$env:APPDATA;$artPriorLocal=$env:LOCALAPPDATA;$artPriorBlend=$env:BLENDER_USER_RESOURCES
try {
 $c6Processes=@()
 if($Gpu){
  $artOwns=$artMutex.WaitOne(0);if(-not $artOwns){throw 'GPU slot busy.'}
  $c6Processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%blender%' OR Name LIKE '%Godot%' OR Name LIKE '%trellis%'" | Select-Object ProcessId,ParentProcessId,Name,CommandLine,WorkingSetSize,KernelModeTime,UserModeTime)
  foreach($c6Process in $c6Processes){
   if($c6Process.Name -match 'blender|trellis'){throw 'Existing Blender/generator; continue independent work.'}
   if($c6Process.CommandLine -match '--headless'){continue}
   $c6Parent=$c6Processes | Where-Object {$_.ProcessId -eq $c6Process.ParentProcessId}
   if(-not $c6Process.CommandLine -and $c6Process.WorkingSetSize -lt 1048576 -and $c6Parent.CommandLine -match '--headless'){continue}
   throw 'Existing renderer or unclassified engine process; no process changed.'
  }
 }
 $env:APPDATA=Join-Path (Split-Path $artLog) 'user';$env:LOCALAPPDATA=Join-Path (Split-Path $artLog) 'local-user';$env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $artLog) 'blender-user'
 New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,$env:BLENDER_USER_RESOURCES | Out-Null
 $artQuoted=($Arguments | ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' '
 $artStart=Get-Date
 $artProc=Start-Process -FilePath $Program -ArgumentList $artQuoted -PassThru -WindowStyle Hidden -RedirectStandardOutput $artLog -RedirectStandardError "$artLog.stderr"
 Write-Output "C6 own PID $($artProc.Id)"
 while(-not $artProc.WaitForExit(1000)){
  if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback' -Quiet){if(Get-Process -Id $artProc.Id -ErrorAction SilentlyContinue){Stop-Process -Id $artProc.Id}; $artProc.WaitForExit();throw "This C6 PID reported script/shader failure: $artLog"}
 }
 $artProc.Refresh()
 $c6After=@()
 if($Gpu){$c6After=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%blender%' OR Name LIKE '%Godot%' OR Name LIKE '%trellis%'" | Select-Object ProcessId,ParentProcessId,Name,CommandLine,WorkingSetSize,KernelModeTime,UserModeTime)}
 @{program=$Program;arguments=$Arguments;pid=$artProc.Id;exit=$artProc.ExitCode;started_utc=$artStart.ToUniversalTime().ToString('o');finished_utc=(Get-Date).ToUniversalTime().ToString('o');seconds=((Get-Date)-$artStart).TotalSeconds;gpu_slot=[bool]$Gpu;appdata=$env:APPDATA;other_processes_at_acquisition=$c6Processes;other_processes_at_completion=$c6After} | ConvertTo-Json -Depth 6 | Set-Content "$artLog.job.json"
 if($artProc.ExitCode -ne 0){throw "Job failed: $artLog"}
 if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback' -Quiet){throw "Diagnostic failure: $artLog"}
 Write-Output "C6_JOB_OK $artLog"
} finally {$env:APPDATA=$artPriorApp;$env:LOCALAPPDATA=$artPriorLocal;$env:BLENDER_USER_RESOURCES=$artPriorBlend;if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
