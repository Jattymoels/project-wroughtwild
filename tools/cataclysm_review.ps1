param(
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
    [string]$Scene = 'cataclysm_intensive',
    [switch]$Rendered,
    [int]$Seed = 1,
    [switch]$ViewsOnly,
    [switch]$CostOnly,
    [switch]$UnboundedRefresh,
    [switch]$WarmView,
    [int]$Seconds = 240
)
$ErrorActionPreference = 'Stop'
$catRepo = Split-Path $PSScriptRoot
$catLogs = Join-Path $catRepo 'build/cataclysm/logs'
New-Item -ItemType Directory -Force -Path $catLogs | Out-Null
$catVariant = if ($Rendered) { 'rendered' } else { 'headless' }
if ($ViewsOnly) { $catVariant += '-views' }
if ($CostOnly) { $catVariant += '-cost' }
if ($UnboundedRefresh) { $catVariant += '-unbounded' }
if ($WarmView) { $catVariant += '-warm-view' }
$catOut = Join-Path $catLogs "$Scene-$Seed-$catVariant.out.log"
$catErr = Join-Path $catLogs "$Scene-$Seed-$catVariant.err.log"
$catArguments = "--path `"$(Join-Path $catRepo 'game')`" "
if ($Rendered) { $catArguments += '--resolution 1440x900 --position -9999,-9999 ' }
else { $catArguments += '--headless ' }
$catSceneDirectory = if ($Scene -eq 'forge_review') { 'experiments' } else { 'tests' }
$catArguments += "res://$catSceneDirectory/$Scene.tscn -- --cat-seed=$Seed --cataclysm"
if ($ViewsOnly) { $catArguments += ' --cat-views-only' }
if ($CostOnly) { $catArguments += ' --cat-cost-only' }
if ($Scene -eq 'frontier_polish_walk') { $catArguments += ' --polish-walk-perf' }
if ($UnboundedRefresh) { $catArguments += ' --cat-unbounded-refresh' }
if ($WarmView) { $catArguments += ' --cat-warm-view' }
$catProcess = Start-Process -FilePath $Godot -ArgumentList $catArguments -WindowStyle Hidden -RedirectStandardOutput $catOut -RedirectStandardError $catErr -PassThru
$catProcessHandle = $catProcess.Handle
# Poll at short intervals: callers can yield their exec cell while the bounded
# review runs. Never touch an editor or game started by the owner.
$catDeadline = (Get-Date).AddSeconds($Seconds)
while (-not $catProcess.WaitForExit(1000)) {
    if ((Get-Date) -gt $catDeadline) {
        $catChildren = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($catProcess.Id)"
        foreach ($catChild in $catChildren) { Stop-Process -Id $catChild.ProcessId -Force -ErrorAction SilentlyContinue }
        Stop-Process -Id $catProcess.Id -Force -ErrorAction SilentlyContinue
        throw "$Scene timed out; see $catLogs"
    }
}
$catText = (Get-Content -LiteralPath $catOut,$catErr -ErrorAction SilentlyContinue) -join "`n"
$catText -split "`n" | Select-String -Pattern 'CATACLYSM|checks|FAIL|SCRIPT ERROR|ERROR:|Godot Engine|Vulkan' | ForEach-Object { $_.Line }
if ($catProcess.ExitCode -ne 0 -or $catText -match '(?m)^(SCRIPT ERROR|ERROR:|FAIL)') { throw "$Scene failed (exit $($catProcess.ExitCode))" }
