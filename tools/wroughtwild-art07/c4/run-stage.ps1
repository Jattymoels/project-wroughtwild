param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('Capture','Motion','Walk','Benchmark','Native')][string]$Stage)
$ErrorActionPreference='Stop'
$c4Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
foreach($c4Renderer in @('forward_plus','gl_compatibility')){
 $c4Modes=if($Stage -eq 'Native'){@('flow','partial','final')}else{@($Stage.ToLowerInvariant())}
 foreach($c4Mode in $c4Modes){
  $c4Log=Join-Path ([IO.Path]::GetFullPath($Logs)) ($c4Renderer+'-'+$c4Mode+'.log')
  $c4Args=@('--path',[IO.Path]::GetFullPath($Project),'--rendering-method',$c4Renderer,'--audio-driver','Dummy')
  if($Stage -ne 'Benchmark'){$c4Args+=@('--fixed-fps','60')}
  if($Stage -eq 'Native'){
   $c4Args+='res://c4/native_review.tscn'
   if($c4Mode -ne 'flow'){$c4Args+=@('--',('--restore-'+$c4Mode))}
  }else{$c4Args+=@('--',('--'+$c4Mode))}
  & "$PSScriptRoot/run-job.ps1" -Program $c4Godot -Arguments $c4Args -Log $c4Log -Gpu -WaitSeconds 45
 }
}
