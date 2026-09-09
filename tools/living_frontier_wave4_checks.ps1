param([switch]$Terrain, [switch]$Legacy)
. "$PSScriptRoot/living_frontier_checks.ps1"
$lfLogs = Join-Path $lfRoot 'build/lf4'
New-Item -ItemType Directory -Force $lfLogs | Out-Null
$env:APPDATA = Join-Path $lfLogs 'appdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
if ($Terrain) {
    Invoke-LFEngine 'terrain-a' @('--headless','--fixed-fps','60','res://tests/resonance_terrain.tscn')
    Invoke-LFEngine 'terrain-a-pending' @('--headless','--fixed-fps','60','res://tests/resonance_terrain.tscn','--','--lf4a-pending')
    Invoke-LFEngine 'terrain-a-applied' @('--headless','--fixed-fps','60','res://tests/resonance_terrain.tscn','--','--lf4a-applied')
}
if ($Legacy) {
    foreach ($lfSeed in 5,77) { Invoke-LFEngine "legacy-$lfSeed" @('--headless','--fixed-fps','60','res://tests/living_frontier_routes.tscn','--',"--route-seed=$lfSeed",'--lf3-r1-restore-only') }
    foreach ($lfScene in 'save_recovery','trial_intensive','trial_resume') { Invoke-LFEngine $lfScene @('--headless',"res://tests/$lfScene.tscn") }
}
