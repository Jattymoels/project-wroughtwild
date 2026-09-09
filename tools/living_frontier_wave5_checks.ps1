param([switch]$Hybrid, [switch]$Visuals, [switch]$Native, [switch]$Pairing, [switch]$TrialNative, [switch]$Campaign, [switch]$Legacy, [switch]$TransitionVisuals)
$lf5Options=@{}+$PSBoundParameters
. "$PSScriptRoot/living_frontier_checks.ps1"
$lfLogs = Join-Path $lfRoot 'build/lf5'
New-Item -ItemType Directory -Force $lfLogs | Out-Null
$env:APPDATA = Join-Path $lfLogs 'appdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
if ($lf5Options.Hybrid) {
    Invoke-LFEngine 'hybrid' @('--headless','--fixed-fps','60','res://tests/living_frontier_hybrid.tscn')
    Invoke-LFEngine 'single-hosts' @('--headless','--fixed-fps','60','res://tests/living_frontier_hosts.tscn')
}
if ($lf5Options.Visuals) { Invoke-LFEngine 'hybrid-visuals' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','res://tests/living_frontier_hybrid.tscn','--','--hybrid-visuals') }
if ($lf5Options.Pairing -or $lf5Options.Campaign) {
    Invoke-LFEngine 'pairing' @('--headless','--fixed-fps','60','res://tests/pairing_trial.tscn')
    Invoke-LFEngine 'pairing-boundary' @('--headless','--fixed-fps','60','res://tests/pairing_trial.tscn','--','--lf5b-boundary')
}
if ($lf5Options.Campaign) {
    Invoke-LFEngine 'second-terrain' @('--headless','--fixed-fps','60','res://tests/second_resonance_terrain.tscn')
    foreach ($lfPhase in 'host-recovery','pending','applied','real-return') { Invoke-LFEngine ("second-"+$lfPhase) @('--headless','--fixed-fps','60','res://tests/second_resonance_terrain.tscn','--',("--lf5c-"+$lfPhase)) }
    foreach ($lfArchive in 'lf4-published-dormant','lf4-published-pending','lf4-published-paid-pending','lf4-published-applied','lf5b-published-clear','lf5b-published-boundary') {
        Invoke-LFEngine ("compat-"+$lfArchive) @('--headless','--fixed-fps','60','res://tests/second_resonance_terrain.tscn','--',("--lf5-compat="+$lfArchive))
    }
}
if ($lf5Options.TransitionVisuals) { Invoke-LFEngine 'second-visuals' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','res://tests/second_resonance_terrain.tscn','--','--lf5c-visuals') }
if ($lf5Options.Legacy) {
    foreach ($lfScene in 'save_recovery','trial_intensive','forge_traversal') { Invoke-LFEngine $lfScene @('--headless',"res://tests/$lfScene.tscn") }
    Invoke-LFEngine 'annex' @('--headless','--fixed-fps','60','res://tests/laboratory_trial.tscn')
}
if ($lf5Options.Native -or $lf5Options.TrialNative) {
    $lfCompiler = 'C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
    $env:PATH = (Split-Path $lfCompiler) + ';' + $env:PATH
    $lfObjects = @(Get-ChildItem build/gdext/CMakeFiles/wroughtwild_sim.dir -Filter *.obj -Recurse | Where-Object { $_.FullName -match '[\\/]sim[\\/]src[\\/]' }).FullName
    if ($lfObjects.Count -eq 0) { throw 'Build the current GDExtension before native checks.' }
    $lfSuites=if($lf5Options.TrialNative){@('test_laboratory','test_pairing')}else{@('test_living_frontier_wave3','test_laboratory','test_pairing','test_resonance','test_main','test_leyline','test_living_frontier_wave2')}
    foreach ($lfTest in $lfSuites) {
        $lfBinary = Join-Path $lfLogs ($lfTest + '.exe')
        & $lfCompiler -std=c++17 -Wall -Wextra -Werror -O1 -Isim/include ("tests/sim/" + $lfTest + '.cpp') @lfObjects -o $lfBinary
        if ($LASTEXITCODE -ne 0) { throw "$lfTest compile failed" }
        & $lfBinary data/tuning | Tee-Object -FilePath (Join-Path $lfLogs ($lfTest + '.log'))
        if ($LASTEXITCODE -ne 0) { throw "$lfTest failed" }
    }
}
