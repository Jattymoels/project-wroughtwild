param([switch]$Hybrid, [switch]$Visuals, [switch]$Native, [switch]$Campaign, [switch]$Legacy)
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
if ($lf5Options.Native) {
    $lfCompiler = 'C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
    $env:PATH = (Split-Path $lfCompiler) + ';' + $env:PATH
    $lfObjects = @(Get-ChildItem build/gdext/CMakeFiles/wroughtwild_sim.dir -Filter *.obj -Recurse | Where-Object { $_.FullName -match '[\\/]sim[\\/]src[\\/]' }).FullName
    if ($lfObjects.Count -eq 0) { throw 'Build the current GDExtension before native checks.' }
    foreach ($lfTest in @('test_living_frontier_wave3','test_laboratory','test_resonance','test_main','test_leyline','test_living_frontier_wave2')) {
        $lfBinary = Join-Path $lfLogs ($lfTest + '.exe')
        & $lfCompiler -std=c++17 -Wall -Wextra -Werror -O1 -Isim/include ("tests/sim/" + $lfTest + '.cpp') @lfObjects -o $lfBinary
        if ($LASTEXITCODE -ne 0) { throw "$lfTest compile failed" }
        & $lfBinary data/tuning | Tee-Object -FilePath (Join-Path $lfLogs ($lfTest + '.log'))
        if ($LASTEXITCODE -ne 0) { throw "$lfTest failed" }
    }
}
