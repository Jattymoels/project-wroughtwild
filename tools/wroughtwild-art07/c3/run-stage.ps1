param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('Capture','Motion','Walk','Benchmark','Native')][string]$Stage)
$ErrorActionPreference='Stop'
foreach($artRenderer in @('forward_plus','gl_compatibility')){
 if($Stage -eq 'Native'){
  foreach($artState in @('flow','partial','final')){
   $artArgs=@('--path',$Project,'--rendering-method',$artRenderer,'--audio-driver','Dummy','--fixed-fps','60','res://c3/native_review.tscn')
   if($artState -ne 'flow'){$artArgs+=@('--',('--restore-'+$artState))}
   & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments $artArgs -Log (Join-Path $Logs ($artRenderer+'-'+$artState+'.log')) -Gpu -WaitSeconds 10
  }
 }else{
  $artArgs=@('--path',$Project,'--rendering-method',$artRenderer,'--audio-driver','Dummy')
  if($Stage -ne 'Benchmark'){$artArgs+=@('--fixed-fps','60')}
  $artArgs+=@('--',('--'+$Stage.ToLower()))
  & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments $artArgs -Log (Join-Path $Logs ($artRenderer+'-'+$Stage.ToLower()+'.log')) -Gpu -WaitSeconds 10
 }
}
