param([switch]$Boss, [switch]$Central, [switch]$Native, [switch]$Visuals, [switch]$Ending, [switch]$SaveFailure, [switch]$Controls, [switch]$Recovery)
$lf6Options=@{}+$PSBoundParameters
. "$PSScriptRoot/living_frontier_checks.ps1"
$lfLogs=Join-Path $lfRoot 'build/lf6'
New-Item -ItemType Directory -Force $lfLogs | Out-Null
$env:APPDATA=Join-Path $lfLogs 'appdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
if ($lf6Options.Boss) { Invoke-LFEngine 'conservator' @('--headless','--fixed-fps','60','res://tests/conservator_combat.tscn') }
if ($lf6Options.Ending) {
    foreach ($lfPhase in 'ending','after-death') { Invoke-LFEngine ("central-"+$lfPhase) @('--headless','--fixed-fps','60','res://tests/central_trial.tscn','--',("--lf6-"+$lfPhase)) }
}
if ($lf6Options.Central) {
    Invoke-LFEngine 'central' @('--headless','--fixed-fps','60','res://tests/central_trial.tscn')
    foreach ($lfPhase in 'boundary','ending','after-death') { Invoke-LFEngine ("central-"+$lfPhase) @('--headless','--fixed-fps','60','res://tests/central_trial.tscn','--',("--lf6-"+$lfPhase)) }
}
if ($lf6Options.SaveFailure) {
    Invoke-LFEngine 'central-save-failure' @('--headless','--fixed-fps','60','res://tests/central_trial.tscn','--','--lf6-save-failure')
    foreach ($lfPhase in 'ending','after-death') { Invoke-LFEngine ("central-retried-"+$lfPhase) @('--headless','--fixed-fps','60','res://tests/central_trial.tscn','--',("--lf6-"+$lfPhase)) }
}
if ($lf6Options.Controls) { Invoke-LFEngine 'central-controls' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','res://tests/central_trial.tscn','--','--lf6-control-visuals') }
if ($lf6Options.Recovery) {
    Invoke-LFEngine 'central-death' @('--headless','--fixed-fps','60','res://tests/central_recovery.tscn')
    Invoke-LFEngine 'central-death-restart' @('--headless','--fixed-fps','60','res://tests/central_recovery.tscn','--','--lf6-death-restart')
}
if ($lf6Options.Visuals) { Invoke-LFEngine 'conservator-visuals' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','res://tests/conservator_combat.tscn','--','--lf6-visuals') }
if ($lf6Options.Native) {
    $lfCompiler='C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
    $env:PATH=(Split-Path $lfCompiler)+';'+$env:PATH
    $lfObjects=@(Get-ChildItem build/gdext/CMakeFiles/wroughtwild_sim.dir -Filter *.obj -Recurse | Where-Object { $_.FullName -match '[\\/]sim[\\/]src[\\/]' }).FullName
    if ($lfObjects.Count -eq 0) { throw 'Build the current extension first.' }
    $lfBinary=Join-Path $lfLogs 'test_central.exe'
    & $lfCompiler -std=c++17 -Wall -Wextra -Werror -O1 -Isim/include tests/sim/test_central.cpp @lfObjects -o $lfBinary
    if ($LASTEXITCODE -ne 0) { throw 'Central native compilation failed.' }
    & $lfBinary data/tuning | Tee-Object -FilePath (Join-Path $lfLogs 'test_central.log')
    if ($LASTEXITCODE -ne 0) { throw 'Central native checks failed.' }
}
