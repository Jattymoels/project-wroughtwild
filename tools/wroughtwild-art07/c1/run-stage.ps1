param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('capture','motion','benchmark','check')][string]$Stage='capture',[string]$Renderer='forward_plus')
$ErrorActionPreference='Stop'
$artArgs=@('--audio-driver','Dummy','--path',$Project,'--rendering-method',$Renderer)
if($Stage -ne 'benchmark'){$artArgs+=@('--fixed-fps','60')}
$artArgs+=@('--',('--'+$Stage))
& "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments $artArgs -Log (Join-Path $Logs ($Renderer+'-'+$Stage+'.log')) -Gpu
