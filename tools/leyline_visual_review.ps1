param(
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
    [ValidateSet('baseline','after','check','perf-repeat')][string]$Phase = 'after',
    [switch]$Headless,
    [switch]$ViewsOnly,
    [int]$Seconds = 240
)
$ErrorActionPreference = 'Stop'
$leyRepo = Split-Path $PSScriptRoot
$leyRoot = Join-Path $leyRepo 'build/leyline-visual'
$leyLogs = Join-Path $leyRoot 'logs'
New-Item -ItemType Directory -Force -Path $leyLogs | Out-Null
if ($Phase -eq 'baseline' -and (Test-Path -LiteralPath (Join-Path $leyRoot 'baseline/manifest.json'))) {
    throw 'The original baseline is preserved; choose another phase for a repeat.'
}
$leyOut = Join-Path $leyLogs "$Phase.out.log"
$leyErr = Join-Path $leyLogs "$Phase.err.log"
$leyArgs = "--path `"$(Join-Path $leyRepo 'game')`" "
if ($Headless) { $leyArgs += '--headless ' }
else { $leyArgs += '--resolution 1440x900 --position -9999,-9999 ' }
$leyArgs += "res://tests/leyline_visual_review.tscn -- --leyline-phase=$Phase"
if ($ViewsOnly -or $Phase -eq 'perf-repeat') { $leyArgs += ' --leyline-views-only' }
$leyProcess = Start-Process -FilePath $Godot -ArgumentList $leyArgs -WindowStyle Hidden -RedirectStandardOutput $leyOut -RedirectStandardError $leyErr -PassThru
$leyHandle = $leyProcess.Handle
$leyDeadline = (Get-Date).AddSeconds($Seconds)
while (-not $leyProcess.WaitForExit(1000)) {
    if ((Get-Date) -gt $leyDeadline) {
        Stop-Process -Id $leyProcess.Id -Force -ErrorAction SilentlyContinue
        throw "Leyline review timed out; see $leyLogs"
    }
}
$leyText = (Get-Content -LiteralPath $leyOut,$leyErr -ErrorAction SilentlyContinue) -join "`n"
$leyText -split "`n" | Select-String -Pattern 'LEYLINE|checks|FAIL|SCRIPT ERROR|ERROR:|Godot Engine|Vulkan' | ForEach-Object { $_.Line }
if ($leyProcess.ExitCode -ne 0 -or $leyText -match '(?m)^(SCRIPT ERROR|ERROR:|FAIL)') { throw "Leyline review failed (exit $($leyProcess.ExitCode))" }
