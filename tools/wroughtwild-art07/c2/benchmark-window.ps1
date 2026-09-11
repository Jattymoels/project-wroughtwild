param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
# Invoke only after the other ART-07 workers confirm a quiet CPU/GPU window.
# Hold this same-thread recursive mutex across both renderer jobs, including startup.
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
try {
 $artOwns=$artMutex.WaitOne(0);if(-not $artOwns){throw 'GPU slot busy.'}
 $artProcesses=@(Get-Process | Where-Object{$_.ProcessName -match 'godot|blender|trellis'})
 if($artProcesses.Count){throw 'Existing renderer/generator; no valid benchmark window.'}
 if(Test-Path -LiteralPath $Logs){throw 'Use a fresh benchmark log directory.'}
 New-Item -ItemType Directory -Path $Logs | Out-Null
 $artStart=Get-Date
 $artBefore= & nvidia-smi --query-gpu=name,driver_version,utilization.gpu,memory.used --format=csv,noheader
 & "$PSScriptRoot/run-stage.ps1" -Project $Project -Logs $Logs -Stage Benchmark
 $artAfter= & nvidia-smi --query-gpu=name,driver_version,utilization.gpu,memory.used --format=csv,noheader
 @{start=$artStart.ToString('o');end=(Get-Date).ToString('o');preexisting_renderers=0;gpu_before=$artBefore;gpu_after=$artAfter;scope='Coordinated quiet ART-07 window; neither capture, encoding nor generation inside the window. Other desktop GPU memory is not assumed absent.'} | ConvertTo-Json | Set-Content (Join-Path $Logs 'environment.json')
} finally {if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
