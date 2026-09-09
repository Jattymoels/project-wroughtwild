param([string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Supply -Godot with the path to Godot 4.5-stable.' }
$rosterReview = Join-Path $PSScriptRoot 'review'
if (-not (Test-Path -LiteralPath (Join-Path $rosterReview 'project.godot'))) { throw 'Run the packaged launcher next to its review folder.' }
$rosterPreviousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $PSScriptRoot 'user-data'
    & $Godot --headless --path $rosterReview --editor --import
    if ($LASTEXITCODE -ne 0) { throw 'Source review import failed.' }
    & $Godot --path $rosterReview
    if ($LASTEXITCODE -ne 0) { throw 'Source review failed; inspect the console output.' }
} finally {
    $env:APPDATA = $rosterPreviousAppData
}
