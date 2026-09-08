param([switch]$Hosts, [switch]$Native, [switch]$FocusedNative, [switch]$Full, [switch]$Import, [switch]$Visuals, [switch]$Habitat, [switch]$HabitatRestore, [switch]$HabitatVisuals)
$ErrorActionPreference = 'Stop'
$lf3Options = @{} + $PSBoundParameters
. (Join-Path $PSScriptRoot 'living_frontier_checks.ps1')
$lfLogs = Join-Path $lfRoot 'build/lf3'
New-Item -ItemType Directory -Force -Path $lfLogs | Out-Null
$env:APPDATA = Join-Path $lfLogs 'appdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
if ($lf3Options.Import) { Invoke-LFEngine 'import' @('--headless','--import') }
if ($lf3Options.Hosts) { Invoke-LFEngine 'hosts' @('--headless','--fixed-fps','60','res://tests/living_frontier_hosts.tscn') }
if ($lf3Options.Visuals) { Invoke-LFEngine 'host-visuals' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','res://tests/living_frontier_hosts.tscn','--','--host-visuals') }
if ($lf3Options.Habitat) { Invoke-LFEngine 'habitat' @('--headless','--fixed-fps','60','res://tests/living_frontier_habitat.tscn') }
if ($lf3Options.HabitatRestore) { Invoke-LFEngine 'habitat-restart' @('--headless','--fixed-fps','60','res://tests/living_frontier_habitat.tscn','--','--lf3-restore') }
if ($lf3Options.HabitatVisuals) { Invoke-LFEngine 'habitat-visuals' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','res://tests/living_frontier_habitat.tscn','--','--lf3-visuals') }
if ($lf3Options.Native -or $lf3Options.FocusedNative) {
    $lfCompiler = 'C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
    $env:PATH = (Split-Path $lfCompiler) + ';' + $env:PATH
    $lfSources = @(Get-ChildItem sim/src -Filter *.cpp).FullName
    $lfSuites = if ($lf3Options.Native) { @('test_living_frontier_wave3','test_main','test_leyline','test_living_frontier_wave2') } else { @('test_living_frontier_wave3') }
    foreach ($lfTest in $lfSuites) {
        $lfBinary = Join-Path $lfLogs ($lfTest + '.exe')
        & $lfCompiler -std=c++17 -Wall -Wextra -Werror -O1 -Isim/include ("tests/sim/" + $lfTest + '.cpp') @lfSources -o $lfBinary
        if ($LASTEXITCODE -ne 0) { throw "$lfTest compile failed" }
        & $lfBinary data/tuning | Tee-Object -FilePath (Join-Path $lfLogs ($lfTest + '.log'))
        if ($LASTEXITCODE -ne 0) { throw "$lfTest failed" }
    }
}
if ($lf3Options.Full) {
    # Preserve every ordered invocation and restart flag in the canonical pipeline.
    $lfIndex = 0
    foreach ($lfLine in Get-Content game/run_headless_checks.sh) {
        if ($lfLine -notmatch '^"\$GODOT" (.+?)(?: \|\| \{)?$') { continue }
        $lfArgs = @(($Matches[1] -replace '--path \. ?', '') -split ' ' | Where-Object { $_ })
        $lfIndex++
        Invoke-LFEngine ('pipeline-' + $lfIndex) $lfArgs
    }
    foreach ($lfIdentity in @('offence','guard','sustain','tempo')) {
        Invoke-LFEngine ('identity-' + $lfIdentity) @('--headless', ('res://tests/foundry_' + $lfIdentity + '_identity.tscn'))
    }
}
