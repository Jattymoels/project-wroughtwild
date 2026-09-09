param([switch]$Terrain, [switch]$Laboratory, [switch]$Campaign, [switch]$Legacy, [switch]$Full)
$lf4Options=@{}+$PSBoundParameters
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
    foreach ($lfScene in 'save_recovery','trial_intensive','forge_traversal') { Invoke-LFEngine $lfScene @('--headless',"res://tests/$lfScene.tscn") }
}
if ($Laboratory) { Invoke-LFEngine 'laboratory-b' @('--headless','--fixed-fps','60','res://tests/laboratory_trial.tscn') }
if ($lf4Options.Campaign) {
    Invoke-LFEngine 'laboratory-c' @('--headless','--fixed-fps','60','res://tests/laboratory_trial.tscn')
    Invoke-LFEngine 'pending-c' @('--headless','--fixed-fps','60','res://tests/laboratory_trial.tscn','--','--lf4c-pending')
    Invoke-LFEngine 'applied-c' @('--headless','--fixed-fps','60','res://tests/laboratory_trial.tscn','--','--lf4c-applied')
}
if ($lf4Options.Full) {
    $lfIndex=0
    foreach ($lfLine in Get-Content game/run_headless_checks.sh) {
        if ($lfLine -notmatch '^"\$GODOT" (.+?)(?: \|\| \{)?$') { continue }
        $lfArgs=@(($Matches[1] -replace '--path \. ?', '') -split ' ' | Where-Object { $_ })
        $lfIndex++
        Invoke-LFEngine ('pipeline-'+$lfIndex) $lfArgs
    }
    foreach ($lfIdentity in 'offence','guard','sustain','tempo') { Invoke-LFEngine ('identity-'+$lfIdentity) @('--headless',"res://tests/foundry_${lfIdentity}_identity.tscn") }
}
