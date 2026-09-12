param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Logs,[switch]$BenchmarksOnly)
$ErrorActionPreference='Stop'
$e1Logs=[IO.Path]::GetFullPath($Logs)
$e1Game=[IO.Path]::GetFullPath($Game)
$e1Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/e1'))
foreach($e1Path in @($e1Game,$e1Logs)){if(-not $e1Path.StartsWith($e1Root+[IO.Path]::DirectorySeparatorChar)){throw 'E1 paths only'}}
if(Test-Path -LiteralPath $e1Logs){throw 'Fresh logs required'}
New-Item -ItemType Directory -Path $e1Logs | Out-Null
foreach($e1Renderer in @('forward_plus','gl_compatibility')) {
 $e1Modes=if($BenchmarksOnly){@('benchmark')}else{@('capture','restore')}
 foreach($e1Mode in $e1Modes) {
  $e1Args=@('--audio-driver','Dummy','--path',$e1Game,'--rendering-method',$e1Renderer,'res://e1/review.tscn','--',('--'+$e1Mode))
  if($e1Mode -ne 'benchmark'){$e1Args=@('--fixed-fps','60')+$e1Args}
  if($e1Mode -eq 'restore'){$e1Args+=@('--capture')}
  & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments $e1Args -Log (Join-Path $e1Logs ($e1Renderer+'-'+$e1Mode+'.log'))
  Get-Content (Join-Path $e1Logs ($e1Renderer+'-'+$e1Mode+'.log')) | Select-Object -Last 4
 }
}
