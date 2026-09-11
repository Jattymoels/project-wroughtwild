param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('Capture','Motion','Benchmark','Native')][string]$Stage)
$ErrorActionPreference='Stop'
foreach($artRenderer in @('forward_plus','gl_compatibility')){
 if($Stage -eq 'Native'){
  foreach($artMode in @('flow','partial','final')){
   $artArgs=@('--path',$Project,'--rendering-method',$artRenderer,'--audio-driver','Dummy','--fixed-fps','60','res://c2/native_review.tscn')
   if($artMode -ne 'flow'){$artArgs+=@('--',('--restore-'+$artMode))}
   & "$PSScriptRoot/run-job.ps1" -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -Arguments $artArgs -Log (Join-Path $Logs "$artRenderer-$artMode.log") -Gpu
  }
 }else{
  $artArgs=@('--path',$Project,'--rendering-method',$artRenderer,'--audio-driver','Dummy')
  if($Stage -ne 'Benchmark'){$artArgs+=@('--fixed-fps','60')}
  $artArgs+=@('--',('--'+$Stage.ToLower()))
  & "$PSScriptRoot/run-job.ps1" -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -Arguments $artArgs -Log (Join-Path $Logs "$artRenderer-$Stage.log") -Gpu
 }
}
