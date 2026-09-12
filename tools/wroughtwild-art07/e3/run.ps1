param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Log,
 [ValidateSet('import','check','restore','capture','benchmark','test')][string]$Mode='check',
 [string]$Renderer='forward_plus',[string]$Test='building_load_boundaries',[string[]]$Extra=@())
$ErrorActionPreference='Stop'
$e3Args=@('--path',$Game,'--audio-driver','Dummy')
if($Mode -eq 'import'){$e3Args+=@('--headless','--editor','--import')}
elseif($Mode -eq 'test'){$e3Args+=@('--headless','--fixed-fps','60',"res://tests/$Test.tscn");if($Extra.Count){$e3Args+=@('--')+$Extra}}
else {
 if($Mode -in @('check','restore')){$e3Args+=@('--headless','--fixed-fps','60')}
 else{$e3Args+=@('--rendering-method',$Renderer);if($Mode -eq 'capture'){$e3Args+=@('--fixed-fps','60')}}
 $e3Args+=@('res://e3/review.tscn','--',"--$Mode")
}
& (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -JobArguments $e3Args -Log $Log
Get-Content -Tail 6 $Log
