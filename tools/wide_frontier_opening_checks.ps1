param([string]$Scene = 'new_world_startup', [switch]$Import, [switch]$Capture, [switch]$Preparing)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot
$project = Join-Path $repo 'build/wide-frontier/review/game'
$logs = Join-Path $repo 'build/wide-frontier/logs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$env:APPDATA = Join-Path $repo 'build/wide-frontier/opening-appdata'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
if ($Preparing) { $Capture = $true }
$name = if ($Import) { 'opening-import' } elseif ($Preparing) { 'seed-preparing' } elseif ($Capture) { 'seed-chooser' } else { $Scene }
$out = Join-Path $logs ($name + '.out.log')
$err = Join-Path $logs ($name + '.err.log')
$arguments = if ($Import) { '--headless --import' } elseif ($Capture) { '--resolution 1280x720 --position -9999,-9999 --script res://tests/world_seed_capture.gd' } else { "--headless res://tests/$Scene.tscn" }
if ($Preparing) { $arguments += ' -- --preparing-view' }
$process = Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList "--path `"$project`" $arguments" -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
$retainedHandle = $process.Handle
if (-not $process.WaitForExit(120000)) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    throw "$name timed out; only the owned review process was stopped. Logs: $logs"
}
$result = (Get-Content -LiteralPath $out,$err -ErrorAction SilentlyContinue) -join "`n"
$result -split "`n" | Select-String -Pattern 'checks|failures|FAIL|SCRIPT ERROR|ERROR:|STARTUP|PACING|CAPTURE|Godot Engine' | ForEach-Object { $_.Line }
if ($process.ExitCode -ne 0 -or $result -match '(?m)^(SCRIPT ERROR|FAIL|ERROR:)') { throw "$name failed; logs: $logs" }
