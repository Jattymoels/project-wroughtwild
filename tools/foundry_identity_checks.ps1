param(
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
    [string]$Scene = 'foundry_offence_identity',
    [switch]$Import,
    [switch]$Rendered,
    [switch]$Script,
    [switch]$Prepare,
    [string]$NativeLibrary = ''
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot
$project = Join-Path $repo 'build/foundry-identity/review/game'
$logs = Join-Path $repo 'build/foundry-identity/logs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$env:APPDATA = Join-Path $repo 'build/foundry-identity/appdata'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
if ($Prepare) {
    New-Item -ItemType Directory -Path $project -Force | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $repo 'game') -Force | Where-Object { $_.Name -notin @('.godot', 'bin') } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $project -Recurse -Force
    }
    Copy-Item -LiteralPath (Join-Path $repo 'data') -Destination (Split-Path $project) -Recurse -Force
    $projectFile = Join-Path $project 'project.godot'
    $projectText = [IO.File]::ReadAllText($projectFile).Replace('[application]', "[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"WroughtwildFoundryReview`"")
    [IO.File]::WriteAllText($projectFile, $projectText)
    $reviewLibrary = Join-Path $project 'bin/libwroughtwild_sim.windows.x86_64.dll'
    if ($NativeLibrary -or -not (Test-Path -LiteralPath $reviewLibrary)) {
        if (-not $NativeLibrary) { $NativeLibrary = Join-Path $repo 'game/bin/libwroughtwild_sim.windows.x86_64.dll' }
        if (-not (Test-Path -LiteralPath $NativeLibrary)) { throw 'Build the native extension first, or supply -NativeLibrary with its compiled DLL.' }
        New-Item -ItemType Directory -Path (Split-Path $reviewLibrary) -Force | Out-Null
        Copy-Item -LiteralPath $NativeLibrary -Destination $reviewLibrary -Force
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $project 'project.godot'))) { throw 'Prepare the isolated review copy first; see docs/prototype/foundry-all-inputs-2026-09-06.md.' }
$name = if ($Import) { 'import' } else { $Scene }
$out = Join-Path $logs ($name + '.out.log')
$err = Join-Path $logs ($name + '.err.log')
$arguments = if ($Import) { '--headless --import' } elseif ($Script) { "--headless --script res://tests/$Scene.gd" } elseif ($Rendered) { "--position -9999,-9999 res://experiments/$Scene.tscn" } else { "--headless res://tests/$Scene.tscn" }
$process = Start-Process -FilePath $Godot -ArgumentList "--path `"$project`" $arguments" -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
$retainedHandle = $process.Handle
if (-not $process.WaitForExit(120000)) {
    # Only this helper's owned process tree. Never an existing game/editor.
    $children = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($process.Id)"
    foreach ($child in $children) { Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue }
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    throw "$name timed out; logs: $logs"
}
$result = (Get-Content -LiteralPath $out,$err -ErrorAction SilentlyContinue) -join "`n"
$result -split "`n" | Select-String -Pattern 'checks|failures|FAIL|SCRIPT ERROR|ERROR:|IDENTITY|Godot Engine' | ForEach-Object { $_.Line }
if ($process.ExitCode -ne 0 -or $result -match '(?m)^(SCRIPT ERROR|FAIL|ERROR:)') { throw "$name failed; logs: $logs" }
