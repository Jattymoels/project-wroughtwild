param([Parameter(Mandatory)][string]$Program,[Parameter(Mandatory)][string[]]$Arguments,[Parameter(Mandatory)][string]$Log,[switch]$Gpu)
$ErrorActionPreference='Stop'
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/c5'))
$artLog=[IO.Path]::GetFullPath($Log)
if(-not $artLog.StartsWith($artRoot+[IO.Path]::DirectorySeparatorChar)){throw 'Log must be in C5 output.'}
if(Test-Path -LiteralPath $artLog){throw 'Use fresh log.'}
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
$artPriorApp=$env:APPDATA;$artPriorLocal=$env:LOCALAPPDATA;$artPriorBlend=$env:BLENDER_USER_RESOURCES
try {
 if($Gpu){
  $artOwns=$artMutex.WaitOne(0);if(-not $artOwns){throw 'GPU slot busy.'}
  $artProcesses=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%' OR Name LIKE '%blender%' OR Name LIKE '%trellis%'" | Where-Object {$_.ThreadCount -gt 0})
  $artBusy=@($artProcesses | Where-Object {$_.Name -notmatch 'godot' -or $_.CommandLine -notmatch '--headless'})
  if($artBusy.Count){$artBusy | Select-Object ProcessId,Name,CommandLine | Format-List | Out-String | Write-Output;throw 'Existing renderer/generator; inspect before continuing.'}
 }
 $env:APPDATA=Join-Path (Split-Path $artLog) 'user';$env:LOCALAPPDATA=Join-Path (Split-Path $artLog) 'local-user';$env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $artLog) 'blender-user'
 New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,$env:BLENDER_USER_RESOURCES | Out-Null
 if($Gpu){@{processes=@($artProcesses | Select-Object ProcessId,Name,CommandLine,ThreadCount);gpu=(nvidia-smi --query-gpu=name,driver_version,utilization.gpu,memory.used --format=csv)} | ConvertTo-Json -Depth 5 | Set-Content "$artLog.preflight.json"}
 $artQuoted=($Arguments | ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' '
 $artStart=Get-Date
 $artProc=Start-Process -FilePath $Program -ArgumentList $artQuoted -PassThru -WindowStyle Hidden -RedirectStandardOutput $artLog -RedirectStandardError "$artLog.stderr"
 Write-Output "C5 own PID $($artProc.Id)"
 while(-not $artProc.WaitForExit(1000)){
  if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback' -Quiet){if(Get-Process -Id $artProc.Id -ErrorAction SilentlyContinue){Stop-Process -Id $artProc.Id}; $artProc.WaitForExit();throw "This C5 PID reported script/shader failure: $artLog"}
 }
 $artProc.Refresh()
 @{program=$Program;arguments=$Arguments;pid=$artProc.Id;exit=$artProc.ExitCode;seconds=((Get-Date)-$artStart).TotalSeconds;gpu_slot=[bool]$Gpu;appdata=$env:APPDATA} | ConvertTo-Json -Depth 6 | Set-Content "$artLog.job.json"
 if($artProc.ExitCode -ne 0){throw "Job failed: $artLog"}
 if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback' -Quiet){throw "Diagnostic failure: $artLog"}
 Write-Output "C5_JOB_OK $artLog"
} finally {$env:APPDATA=$artPriorApp;$env:LOCALAPPDATA=$artPriorLocal;$env:BLENDER_USER_RESOURCES=$artPriorBlend;if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
