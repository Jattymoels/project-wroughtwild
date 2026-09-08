param([switch]$Native, [switch]$Flow, [switch]$Restore, [switch]$Rendered, [switch]$Regression)
$ErrorActionPreference = 'Stop'
$lfRoot = Split-Path $PSScriptRoot
Set-Location -LiteralPath $lfRoot
$lfLogs = Join-Path $lfRoot 'build/lf1'
New-Item -ItemType Directory -Force -Path $lfLogs | Out-Null
$lfGodot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
function Invoke-LFEngine([string]$Name, [string[]]$Arguments) {
    $lfOut = Join-Path $lfLogs ($Name + '.out.log')
    $lfErr = Join-Path $lfLogs ($Name + '.err.log')
    $lfProcess = Start-Process -FilePath $lfGodot -ArgumentList (@('--path', 'game') + $Arguments) -WindowStyle Hidden -RedirectStandardOutput $lfOut -RedirectStandardError $lfErr -PassThru
    $lfHandle = $lfProcess.Handle
    $lfStarted = Get-Date
    while (-not $lfProcess.WaitForExit(1000)) {
        $lfLiveErrors = (Get-Content -LiteralPath $lfErr -ErrorAction SilentlyContinue) -join "`n"
        if ($lfLiveErrors -match '(?m)^(SCRIPT ERROR|ERROR:)' -or ((Get-Date) - $lfStarted).TotalMinutes -gt 8) {
            $lfProcess.Kill()
            $lfProcess.WaitForExit()
            throw "$Name stopped after engine error or eight-minute test timeout: $lfLiveErrors"
        }
    }
    $lfText = (Get-Content -LiteralPath $lfOut,$lfErr -ErrorAction SilentlyContinue) -join "`n"
    Write-Output ($Name + ': exit ' + $lfProcess.ExitCode)
    $lfText -split "`n" | Select-String -Pattern 'checks|FAIL|SCRIPT ERROR|ERROR:|LF1_|CODEX_' | ForEach-Object { $_.Line }
    if ($lfProcess.ExitCode -ne 0 -or $lfText -match '(?m)^(SCRIPT ERROR|FAIL|ERROR:)') { throw "$Name failed; see $lfLogs" }
}
if ($Native) {
    $lfCompiler = 'C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
    $env:PATH = (Split-Path $lfCompiler) + ';' + $env:PATH
    $lfSources = @(Get-ChildItem sim/src -Filter *.cpp).FullName
    foreach ($lfTest in @('test_leyline','test_main')) {
        $lfBinary = Join-Path $lfLogs ($lfTest + '.exe')
        & $lfCompiler -std=c++17 -Wall -Wextra -Werror -O1 -Isim/include ("tests/sim/" + $lfTest + '.cpp') @lfSources -o $lfBinary
        if ($LASTEXITCODE -ne 0) { throw "$lfTest compile failed" }
        & $lfBinary data/tuning | Tee-Object -FilePath (Join-Path $lfLogs ($lfTest + '.log'))
        if ($LASTEXITCODE -ne 0) { throw "$lfTest failed" }
    }
}
if ($Flow) {
    if ($Rendered) { Invoke-LFEngine 'flow-rendered' @('--position', '-9999,-9999', '--audio-driver', 'Dummy', 'res://tests/living_frontier_flow.tscn') }
    else { Invoke-LFEngine 'flow' @('--headless', 'res://tests/living_frontier_flow.tscn') }
}
if ($Restore) { Invoke-LFEngine 'flow-restart' @('--headless', 'res://tests/living_frontier_flow.tscn', '--', '--lf-restore') }
if ($Regression) {
    foreach ($lfScene in @('crafting_catalogue','contraption_intensive','pressure_workshop','loose_drop_save','save_recovery','weathered_save','wide_frontier_pacing')) {
        Invoke-LFEngine $lfScene @('--headless', ('res://tests/' + $lfScene + '.tscn'))
    }
}
