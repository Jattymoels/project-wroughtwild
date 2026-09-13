param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Output,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[ValidateSet('views','catalogue','walk','feeder','feeder-restore','feeder-exhausted','benchmark','smoke')][string]$Mode='views',[switch]$Baseline)
$ErrorActionPreference='Stop'
$g1Scene=switch($Mode){'views' {'g1/review.tscn'} 'benchmark' {'g1/review.tscn'} 'catalogue' {'g1/catalogue.tscn'} 'walk' {'g1/walk_review.tscn'} 'smoke' {'g1/play.tscn'} default {'f4/review.tscn'}}
$g1Args=@('--rendering-method',$Renderer,'--path',[IO.Path]::GetFullPath($Game),('res://'+$g1Scene),'--')
switch($Mode){
 'walk' {$g1Args+=@('--capture','--run-id=walk-review')}
 'feeder' {$g1Args+=@('--capture')}
 'feeder-restore' {$g1Args+=@('--capture','--restore')}
 'feeder-exhausted' {$g1Args+=@('--capture','--restore-exhausted')}
 'benchmark' {$g1Args+=@('--benchmark')}
 'smoke' {$g1Args+=@('--smoke')}
}
if($Baseline){$g1Args+=@('--baseline')}
& "$PSScriptRoot/gpu-slot.ps1" -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments $g1Args -Log ([IO.Path]::GetFullPath($Output))
