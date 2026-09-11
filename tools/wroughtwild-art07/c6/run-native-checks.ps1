param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
$c6Jobs=@(
 @('smithy-v6-77','res://c6/smithy_story.tscn','--','--weathered-look','--story-seed=77'),
 @('smithy-v6-1','res://c6/smithy_story.tscn','--','--weathered-look','--story-seed=1'),
 @('smithy-v5-1','res://c6/smithy_story.tscn','--','--weathered-look','--story-seed=1','--story-profile=frontier_v5'),
 @('discovery-sites','res://tests/discovery_sites.tscn'),
 @('discovery-clarity','res://tests/discovery_clarity.tscn'),
 @('pressure','res://tests/pressure_workshop.tscn'),
 @('environment','res://tests/environment_target_checks.tscn'),
 @('ecology','res://tests/ecology_buildings.tscn'),
 @('routes-5','res://c6/living_frontier_routes.tscn','--','--weathered-look','--route-seed=5'),
 @('routes-77','res://c6/living_frontier_routes.tscn','--','--weathered-look','--route-seed=77'))
foreach($c6Job in $c6Jobs){
 $c6Args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$Project)+$c6Job[1..($c6Job.Length-1)]
 & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments $c6Args -Log (Join-Path $Logs ($c6Job[0]+'.log'))
}
