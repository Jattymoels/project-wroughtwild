param([switch]$Native, [switch]$Blue, [switch]$Restore, [switch]$Rendered, [switch]$Bootstrap, [switch]$Regression, [switch]$Green, [switch]$GreenRestore, [switch]$Heat, [switch]$HeatRestore)
$ErrorActionPreference = 'Stop'
$lf2Options = @{} + $PSBoundParameters
. (Join-Path $PSScriptRoot 'living_frontier_checks.ps1')
$lfLogs = Join-Path $lfRoot 'build/lf2'
New-Item -ItemType Directory -Force -Path $lfLogs | Out-Null
$env:APPDATA = Join-Path $lfLogs 'appdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
if ($lf2Options.Bootstrap) {
    Invoke-LFEngine 'paid-bootstrap' @('--headless','res://tests/living_frontier_flow.tscn')
    Copy-Item -LiteralPath (Join-Path $env:APPDATA 'Godot/app_userdata/Wroughtwild/lf1-flow.json') -Destination (Join-Path $lfLogs 'wave1.json')
}
if ($lf2Options.Native) {
    $lfCompiler = 'C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
    $env:PATH = (Split-Path $lfCompiler) + ';' + $env:PATH
    $lfSources = @(Get-ChildItem sim/src -Filter *.cpp).FullName
    foreach ($lfTest in @('test_leyline','test_living_frontier_wave2')) {
        $lfBinary = Join-Path $lfLogs ($lfTest + '.exe')
        & $lfCompiler -std=c++17 -Wall -Wextra -Werror -O1 -Isim/include ("tests/sim/" + $lfTest + '.cpp') @lfSources -o $lfBinary
        if ($LASTEXITCODE -ne 0) { throw "$lfTest compile failed" }
        & $lfBinary data/tuning | Tee-Object -FilePath (Join-Path $lfLogs ($lfTest + '.log'))
        if ($LASTEXITCODE -ne 0) { throw "$lfTest failed" }
    }
}
if ($lf2Options.Blue) {
    $lfMode = @('--headless')
    if ($lf2Options.Rendered) { $lfMode = @('--position','-9999,-9999','--audio-driver','Dummy') }
    Invoke-LFEngine 'blue-flow' ($lfMode + @('res://tests/living_frontier_wave2_flow.tscn'))
}
if ($lf2Options.Restore) { Invoke-LFEngine 'blue-restart' @('--headless','res://tests/living_frontier_wave2_flow.tscn','--','--lf2-restore') }
if ($lf2Options.Regression) {
    foreach ($lfScene in @('crafting_catalogue','contraption_intensive','pressure_workshop','loose_drop_save','save_recovery','weathered_save','wide_frontier_pacing')) {
        Invoke-LFEngine $lfScene @('--headless', ('res://tests/' + $lfScene + '.tscn'))
    }
}

if ($lf2Options.Green) {
    $lfMode = @('--headless')
    if ($lf2Options.Rendered) { $lfMode = @('--position','-9999,-9999','--audio-driver','Dummy') }
    Invoke-LFEngine 'green-flow' ($lfMode + @('res://tests/living_frontier_green_flow.tscn'))
}
if ($lf2Options.GreenRestore) { Invoke-LFEngine 'green-restart' @('--headless','res://tests/living_frontier_green_flow.tscn','--','--green-restore') }

if ($lf2Options.Heat) {
    $lfMode = @('--headless')
    if ($lf2Options.Rendered) { $lfMode = @('--position','-9999,-9999','--audio-driver','Dummy') }
    Invoke-LFEngine 'heat-flow' ($lfMode + @('res://tests/living_frontier_heat_flow.tscn'))
}
if ($lf2Options.HeatRestore) { Invoke-LFEngine 'heat-restart' @('--headless','res://tests/living_frontier_heat_flow.tscn','--','--heat-restore') }
