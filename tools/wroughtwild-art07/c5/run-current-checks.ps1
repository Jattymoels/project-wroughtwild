param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
$artJobs=@(
 @('unit','--script','tests/run_tests.gd'),
 @('art','--script','tests/art_checks.gd'),
 @('gathering','res://tests/gathering_feedback.tscn'),
 @('world','res://tests/world_intensive.tscn'),
 @('materials','res://tests/material_intensive.tscn'),
 @('placement','res://tests/placement_transactions.tscn'),
 @('placement-restore','res://tests/placement_transactions.tscn','--','--placement-restore-only'),
 @('loads','res://tests/building_load_boundaries.tscn'),
 @('loads-restore','res://tests/building_load_boundaries.tscn','--','--load-restore-only'),
 @('loose-write','res://tests/loose_drop_save.tscn','--','--write-checkpoint'),
 @('loose-read','res://tests/loose_drop_save.tscn','--','--read-checkpoint'),
 @('source-work','res://tests/living_frontier_flow.tscn'),
 @('source-restore','res://tests/living_frontier_flow.tscn','--','--lf-restore'),
 @('save-recovery','res://tests/save_recovery.tscn'))
foreach($artJob in $artJobs){
 $artExisting=Join-Path $Logs ($artJob[0]+'.log.job.json')
 if(Test-Path -LiteralPath $artExisting){$artResult=Get-Content -Raw $artExisting | ConvertFrom-Json;if($artResult.exit -eq 0){Write-Output "Already checked $($artJob[0])";continue}else{throw 'Earlier check failed; use fresh logs.'}}
 $artArgs=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$Project)+$artJob[1..($artJob.Length-1)]
 & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments $artArgs -Log (Join-Path $Logs ($artJob[0]+'.log'))
 # run-job propagates actual Start-Process ExitCode failures as exceptions.
}
