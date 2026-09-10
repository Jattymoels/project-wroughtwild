param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Logs,[ValidateSet('Native','Capture','Benchmark')][string]$Stage='Native')
$ErrorActionPreference='Stop'
$artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$artReview=Join-Path $Root 'review';$artGame=Join-Path $Root 'native/game'
if($Stage -eq 'Native'){
 foreach($artMode in @('flow','partial','final')){
  $artArgs=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$artGame,'res://b3/native_review.tscn')
  if($artMode -ne 'flow'){$artArgs+=@('--',"--restore-$artMode")}
  & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments $artArgs -Log (Join-Path $Logs ("native-$artMode.log"))
 }
}else{
 foreach($artRenderer in @('forward_plus','gl_compatibility')){
  if($Stage -eq 'Capture'){
   & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments @('--path',$artReview,'--rendering-method',$artRenderer,'--resolution','1440x900','--audio-driver','Dummy','--','--capture') -Log (Join-Path $Logs ("$artRenderer-static.log")) -Gpu
   & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments @('--path',$artGame,'--rendering-method',$artRenderer,'--resolution','1440x900','--audio-driver','Dummy','--fixed-fps','60','res://b3/native_review.tscn') -Log (Join-Path $Logs ("$artRenderer-native.log")) -Gpu
  }else{
   foreach($artVariant in @('art','baseline')){
    $artArgs=@('--path',$artReview,'--rendering-method',$artRenderer,'--resolution','1440x900','--audio-driver','Dummy','--','--benchmark')
    if($artVariant -eq 'baseline'){$artArgs+='--no-art'}
    & "$PSScriptRoot/run-job.ps1" -Program $artGodot -Arguments $artArgs -Log (Join-Path $Logs ("$artRenderer-$artVariant-benchmark.log")) -Gpu
   }
  }
 }
}
