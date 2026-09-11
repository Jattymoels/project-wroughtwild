param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[string]$Renderer='headless')
$ErrorActionPreference='Stop'
foreach($artMode in @('flow','partial','final')) {
 $artArgs=@('--audio-driver','Dummy','--fixed-fps','60','--path',$Project)
 if($Renderer -eq 'headless'){$artArgs=@('--headless')+$artArgs}else{$artArgs+=@('--rendering-method',$Renderer)}
 $artArgs+=@('res://c1/native_review.tscn')
 if($artMode -ne 'flow'){$artArgs+=@('--',('--restore-'+$artMode))}
 & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments $artArgs -Log (Join-Path $Logs ($artMode+'.log')) -Gpu:($Renderer -ne 'headless')
}
