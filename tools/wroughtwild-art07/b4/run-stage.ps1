param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('Capture','Walk','Motion','Benchmark')][string]$Stage='Capture')
$ErrorActionPreference='Stop'
foreach($b4Renderer in @('forward_plus','gl_compatibility')){
 $b4Log=Join-Path $Logs ($b4Renderer+'-'+$Stage.ToLowerInvariant()+'.log')
 if(Test-Path -LiteralPath "$b4Log.job.json"){
  $b4Prior=Get-Content -Raw -LiteralPath "$b4Log.job.json" | ConvertFrom-Json
  if($b4Prior.exit -eq 0 -and -not (Select-String -Path $b4Log,"$b4Log.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback' -Quiet)){Write-Output "Already passed $b4Renderer $Stage";continue}
  throw 'Prior attempt failed: choose fresh logs.'
 }
 & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments @('--path',[IO.Path]::GetFullPath($Project),'--rendering-method',$b4Renderer,'--fixed-fps','60','--audio-driver','Dummy','--',('--'+$Stage.ToLowerInvariant())) -Log $b4Log -Gpu -WaitSeconds 45
}
