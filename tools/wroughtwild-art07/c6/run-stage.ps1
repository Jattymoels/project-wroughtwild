param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('check','capture','walk','motion','benchmark')][string]$Stage='check',[string[]]$Renderers=@('forward_plus','gl_compatibility'))
$ErrorActionPreference='Stop'
foreach($c6Renderer in $Renderers){
 $c6Args=@('--audio-driver','Dummy','--path',$Project,'--rendering-method',$c6Renderer)
 if($Stage -eq 'check'){$c6Args+=@('--headless','--fixed-fps','60')}
 else{$c6Args+=@('--position','-16000,-16000','--resolution','1440x900');if($Stage -in @('walk','motion')){$c6Args+=@('--fixed-fps','60')}}
 $c6Args+=@('res://c6/native_review.tscn','--','--weathered-look',"--c6-mode=$Stage")
 & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments $c6Args -Log (Join-Path $Logs "$c6Renderer.log") -Gpu:($Stage -ne 'check')
}
