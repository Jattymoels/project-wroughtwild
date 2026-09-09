param([switch]$Native, [switch]$Controls, [switch]$Combat, [switch]$Effects, [switch]$Visuals, [switch]$Loop, [switch]$Restart, [switch]$Routes, [switch]$LoopVisuals)
$lf7Options=@{}+$PSBoundParameters
. "$PSScriptRoot/living_frontier_checks.ps1"
$lfLogs=Join-Path $lfRoot 'build/lf7'
New-Item -ItemType Directory -Force $lfLogs | Out-Null
$env:APPDATA=Join-Path $lfLogs 'appdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
if ($lf7Options.Native) {
    $lfCompiler=Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
    $env:PATH=(Split-Path $lfCompiler)+';'+$env:PATH
    $lfObjects=@(Get-ChildItem build/gdext/CMakeFiles/wroughtwild_sim.dir -Filter *.obj -Recurse | Where-Object { $_.FullName -match '[\\/]sim[\\/]src[\\/]' }).FullName
    $lfBinary=Join-Path $lfLogs 'test_laboratory_experiment.exe'
    & $lfCompiler -std=c++17 -Wall -Wextra -Werror -O1 -Isim/include tests/sim/test_laboratory_experiment.cpp @lfObjects -o $lfBinary
    if ($LASTEXITCODE -ne 0) { throw 'Laboratory native compilation failed.' }
    & $lfBinary data/tuning | Tee-Object -FilePath (Join-Path $lfLogs 'native.log')
    if ($LASTEXITCODE -ne 0) { throw 'Laboratory native checks failed.' }
}
if ($lf7Options.Controls) { Invoke-LFEngine 'controls' @('--headless','--fixed-fps','60','res://tests/laboratory_experiment.tscn') }
if ($lf7Options.Loop) { Invoke-LFEngine 'loop' @('--headless','--fixed-fps','60','res://tests/laboratory_repeat_loop.tscn') }
if ($lf7Options.Restart) { Invoke-LFEngine 'loop-restart' @('--headless','--fixed-fps','60','res://tests/laboratory_repeat_loop.tscn','--','--lf7-restart') }
if ($lf7Options.Routes) { Invoke-LFEngine 'routes' @('--headless','--fixed-fps','60','res://tests/laboratory_route_geometry.tscn') }
if ($lf7Options.Combat) { Invoke-LFEngine 'combat' @('--headless','--fixed-fps','60','res://tests/laboratory_experiment_combat.tscn') }
if ($lf7Options.Effects) { Invoke-LFEngine 'effects' @('--headless','--fixed-fps','60','res://tests/laboratory_pressure_effects.tscn') }
if ($lf7Options.Visuals) { Invoke-LFEngine 'visuals' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','res://tests/laboratory_experiment.tscn','--','--lf7-visuals') }
if ($lf7Options.LoopVisuals) { Invoke-LFEngine 'loop-visuals' @('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','--fixed-fps','60','res://tests/laboratory_repeat_loop.tscn','--','--lf7-loop-visuals') }
