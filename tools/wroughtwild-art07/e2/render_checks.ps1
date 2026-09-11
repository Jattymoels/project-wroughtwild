param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Logs,[switch]$BenchmarksOnly)
$ErrorActionPreference='Stop'
$e2Logs=[IO.Path]::GetFullPath($Logs)
$e2Game=[IO.Path]::GetFullPath($Game)
$e2Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/e2'))
foreach($e2Path in @($e2Game,$e2Logs)){if(-not $e2Path.StartsWith($e2Root+[IO.Path]::DirectorySeparatorChar)){throw 'E2 paths only'}}
if(Test-Path -LiteralPath $e2Logs){throw 'Fresh logs required'}
New-Item -ItemType Directory -Path $e2Logs | Out-Null
foreach($e2Renderer in @('forward_plus','gl_compatibility')) {
 $e2Modes=if($BenchmarksOnly){@('benchmark')}else{@('capture','restore')}
 foreach($e2Mode in $e2Modes) {
  $e2Args=@('--audio-driver','Dummy','--path',$e2Game,'--rendering-method',$e2Renderer,'res://e2/review.tscn','--',('--'+$e2Mode))
  if($e2Mode -ne 'benchmark'){$e2Args=@('--fixed-fps','60')+$e2Args}
  if($e2Mode -eq 'restore'){$e2Args+=@('--capture')}
  & (Join-Path $PSScriptRoot 'queued-job.ps1') -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments $e2Args -Log (Join-Path $e2Logs ($e2Renderer+'-'+$e2Mode+'.log'))
  Get-Content (Join-Path $e2Logs ($e2Renderer+'-'+$e2Mode+'.log')) | Select-Object -Last 4
 }
}
