param(
    [ValidateSet('baseline','current')][string]$Phase = 'current',
    [string[]]$Scenes = @('home_station_placement','home_material_joins','home_headroom','home_workshop_review'),
    [int]$Seed = 77,
    [switch]$Prepare,
    [switch]$Import,
    [switch]$Rendered,
    [string]$ExtraArguments = '',
    [int]$TimeoutSeconds = 420,
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
# Bounded INT-03 checks/captures. Copies and user data stay in ignored build/;
# only a process launched by this invocation can be stopped on timeout.
$ErrorActionPreference = 'Stop'
$homeRepo = Split-Path $PSScriptRoot
$homeRoot = Join-Path $homeRepo 'build/home'
$homeCopy = Join-Path $homeRoot $Phase
$homeGame = Join-Path $homeCopy 'game'
$homeLogs = Join-Path $homeRoot ('logs/' + $Phase)
New-Item -ItemType Directory -Force -Path $homeLogs | Out-Null
if ($Prepare) {
    if ($Phase -eq 'baseline' -and (Test-Path -LiteralPath (Join-Path $homeGame 'project.godot'))) {
        throw 'The preserved baseline already exists; do not overwrite it with current source.'
    }
    foreach ($homeFolder in @('game','data')) {
        & robocopy (Join-Path $homeRepo $homeFolder) (Join-Path $homeCopy $homeFolder) /E /XD .godot /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "Copy failed: $homeFolder" }
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $homeGame 'project.godot'))) { throw 'Prepare the isolated project first.' }
if ($Phase -eq 'baseline') {
    # Replay only the new common review/reproduction fixtures against untouched production.
    foreach ($homeFile in @('home_station_placement.gd','home_station_placement.tscn','home_headroom.gd','home_headroom.tscn','home_workshop_review.gd','home_workshop_review.tscn')) {
        if (Test-Path -LiteralPath (Join-Path $homeRepo "game/tests/$homeFile")) {
            Copy-Item -LiteralPath (Join-Path $homeRepo "game/tests/$homeFile") -Destination (Join-Path $homeGame "tests/$homeFile")
        }
    }
}
foreach ($homeFolder in @('cataclysm','codex-aesthetic','strange-frontier')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $homeCopy "build/$homeFolder") | Out-Null
}
$homeAppData = Join-Path $homeRoot ('appdata/' + $Phase)
New-Item -ItemType Directory -Force -Path $homeAppData | Out-Null
$priorHomeAppData = $env:APPDATA
try {
    $env:APPDATA = $homeAppData
    function Invoke-HomeCheck([string]$Name,[string]$Arguments) {
        $homeOut = Join-Path $homeLogs ($Name + '.out.log')
        $homeErr = Join-Path $homeLogs ($Name + '.err.log')
        $homeProcess = Start-Process -FilePath $Godot -ArgumentList "--path `"$homeGame`" $Arguments" -WindowStyle Hidden -RedirectStandardOutput $homeOut -RedirectStandardError $homeErr -PassThru
        $homeHandle = $homeProcess.Handle
        $homeWatch = [Diagnostics.Stopwatch]::StartNew()
        while (-not $homeProcess.WaitForExit(1000)) {
            $homeEarlyError = (Get-Content -LiteralPath $homeErr -ErrorAction SilentlyContinue) -match '^(SCRIPT ERROR|ERROR:)'
            if ($homeWatch.Elapsed.TotalSeconds -gt $TimeoutSeconds -or $homeEarlyError) {
                foreach ($homeChild in (Get-CimInstance Win32_Process -Filter "ParentProcessId = $($homeProcess.Id)")) {
                    Stop-Process -Id $homeChild.ProcessId -Force -ErrorAction SilentlyContinue
                }
                Stop-Process -Id $homeProcess.Id -Force -ErrorAction SilentlyContinue
                if ($homeEarlyError) { throw "$Name reported a script/runtime error; see $homeLogs" }
                throw "$Name timed out; see $homeLogs"
            }
        }
        $homeText = (Get-Content -LiteralPath $homeOut,$homeErr -ErrorAction SilentlyContinue) -join "`n"
        $homeText -split "`n" | Select-String -Pattern 'checks|HOME_|FAIL|SCRIPT ERROR|ERROR:' | ForEach-Object { $_.Line }
        if ($homeProcess.ExitCode -ne 0 -or $homeText -match '(?m)^(SCRIPT ERROR|ERROR:|FAIL)') { throw "$Name failed ($($homeProcess.ExitCode)); see $homeLogs" }
        Write-Output "PASS $Phase $Name"
    }
    if ($Import) { Invoke-HomeCheck 'import' '--headless --import' }
    foreach ($homeScene in $Scenes) {
        if ($homeScene -notmatch '^[a-zA-Z0-9_]+$') { throw 'Scene must be a test basename.' }
        $homeFlags = if ($Rendered) { '--resolution 1440x900 --position -9999,-9999' } else { '--headless' }
        $homeMode = if ($Rendered) { 'rendered' } else { 'headless' }
        $homeVariant = if ($ExtraArguments -match '--journey-class=([a-zA-Z0-9_]+)') { '-' + $Matches[1] } else { '' }
        Invoke-HomeCheck "$homeScene-$Seed-$homeMode$homeVariant" "$homeFlags res://tests/$homeScene.tscn -- --home-seed=$Seed --home-phase=$Phase $ExtraArguments"
    }
} finally { $env:APPDATA = $priorHomeAppData }
