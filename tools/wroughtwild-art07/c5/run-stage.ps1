param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('Native','Capture','Benchmark','Import')][string]$Stage)
$ErrorActionPreference='Stop'
$artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
if($Stage -eq 'Import'){
 & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments @('--headless','--editor','--path',$Project,'--import') -Log (Join-Path $Logs 'import.log')
} elseif($Stage -eq 'Native'){
 foreach($artMode in @('flow','partial','final')){
  $artArgs=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$Project,'res://c5/native_review.tscn')
  if($artMode -ne 'flow'){$artArgs+=@('--',"--restore-$artMode")}
  & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments $artArgs -Log (Join-Path $Logs ($artMode+'.log'))
 }
 & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments @('--headless','--path',$Project,'--script','res://c5/verify_pause.gd') -Log (Join-Path $Logs 'pause.log')
} else {
 foreach($artRenderer in @('forward_plus','gl_compatibility')){
  $artArgs=@('--audio-driver','Dummy','--path',$Project,'--rendering-method',$artRenderer,'--position','-16000,-16000','--resolution','1440x900','res://c5/review.tscn','--',('--'+$Stage.ToLower()))
  & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments $artArgs -Log (Join-Path $Logs ($artRenderer+'.log')) -Gpu
  if($Stage -eq 'Capture'){
   $artArgs=@('--audio-driver','Dummy','--fixed-fps','60','--path',$Project,'--rendering-method',$artRenderer,'--position','-16000,-16000','--resolution','1440x900','res://c5/native_review.tscn')
   & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments $artArgs -Log (Join-Path $Logs ($artRenderer+'-native.log')) -Gpu
  }
 }
}
