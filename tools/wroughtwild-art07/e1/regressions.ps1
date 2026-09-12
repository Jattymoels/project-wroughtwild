param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
$e1Logs=[IO.Path]::GetFullPath($Logs)
if(Test-Path -LiteralPath $e1Logs){throw 'Use fresh logs'}
New-Item -ItemType Directory -Path $e1Logs | Out-Null
$e1Jobs=@(
 @{scene='home_station_placement';extra=@()},
 @{scene='home_station_clearance';extra=@()},
 @{scene='placement_transactions';extra=@()},
 @{scene='placement_transactions';extra=@('--placement-restore-only')},
 @{scene='workshop_feedback';extra=@()},
 @{scene='home_workshop_review';extra=@()},
 @{scene='home_material_joins';extra=@()},
 @{scene='save_recovery';extra=@()}
)
$e1Index=0
foreach($e1Job in $e1Jobs){
 $e1Index++
 $e1Args=@('--headless','--audio-driver','Dummy','--path',$Game,('res://tests/'+$e1Job.scene+'.tscn'))
 if($e1Job.scene -ne 'workshop_feedback'){$e1Args=@('--fixed-fps','60')+$e1Args}
 if($e1Job.extra.Count){$e1Args+=@('--')+$e1Job.extra}
 $e1Log=Join-Path $e1Logs ($e1Index.ToString()+'-'+$e1Job.scene+'.log')
 & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -JobArguments $e1Args -Log $e1Log
 Get-Content -LiteralPath $e1Log | Select-Object -Last 3
}
