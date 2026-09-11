param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $Logs){throw 'Use a fresh benchmark log directory.'}
$artBusy=Get-Process | Where-Object {$_.ProcessName -match 'godot|blender|trellis'}
if($artBusy){throw 'Another engine is running; benchmark was not started.'}
New-Item -ItemType Directory -Path $Logs | Out-Null
@{started_utc=(Get-Date).ToUniversalTime().ToString('o');coordination='C2/C3/C4 explicitly held engine, encoding and heavy hashing work for this measurement window.';other_engine_processes=@();conditions='Fixed overview, 1440x900, MSAA4, VSync off, 120 warm-up + 600 samples per case; generation and capture are separate.'} | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $Logs 'conditions.json')
& C:/Windows/system32/nvidia-smi.exe --query-gpu=name,driver_version,memory.total,memory.used,temperature.gpu,utilization.gpu --format=csv | Set-Content (Join-Path $Logs 'gpu-before.csv')
foreach($artRenderer in @('forward_plus','gl_compatibility')){& "$PSScriptRoot/run-stage.ps1" -Project $Project -Logs $Logs -Stage benchmark -Renderer $artRenderer}
& C:/Windows/system32/nvidia-smi.exe --query-gpu=name,driver_version,memory.total,memory.used,temperature.gpu,utilization.gpu --format=csv | Set-Content (Join-Path $Logs 'gpu-after.csv')
Write-Output 'C1_BENCHMARK_BATCH_OK'
