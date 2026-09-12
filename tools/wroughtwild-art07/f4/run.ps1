param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Log,[ValidateSet('check','capture','restore','restore-capture','exhausted','exhausted-capture','benchmark','play')][string]$Mode='check',[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$NoShadows)
$ErrorActionPreference='Stop'
$f4Args=@('--audio-driver','Dummy','--path',[IO.Path]::GetFullPath($Game),'--rendering-method',$Renderer,'res://f4/review.tscn','--')
switch($Mode){
 'check' {$f4Args=@('--headless','--fixed-fps','60')+$f4Args+'--check'}
 'capture' {$f4Args=@('--fixed-fps','60')+$f4Args+'--capture'}
 'restore' {$f4Args=@('--headless','--fixed-fps','60')+$f4Args+'--restore'}
 'restore-capture' {$f4Args=@('--fixed-fps','60')+$f4Args+@('--restore','--capture')}
 'exhausted' {$f4Args=@('--headless','--fixed-fps','60')+$f4Args+'--restore-exhausted'}
 'exhausted-capture' {$f4Args=@('--fixed-fps','60')+$f4Args+@('--restore-exhausted','--capture')}
 'benchmark' {$f4Args+='--benchmark'}
 'play' {$f4Args+='--play'}
}
if($NoShadows){if($Mode -ne 'benchmark'){throw 'Shadow comparison is benchmark-only.'};$f4Args+='--no-shadows'}
& (Join-Path $PSScriptRoot 'queued-job.ps1') -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments $f4Args -Log $Log
