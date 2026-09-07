param(
    [ValidateSet('baseline','current')][string]$Phase = 'current',
    [ValidateSet('home','home-reliability','interaction-feedback','footsteps-ambience','forge-readability','workshop-usability','placement-reliability','building-loads','quiet-ambience','foundry-clarity')][string]$ReviewSet = 'home',
    [string[]]$Scenes = @('home_station_placement','home_material_joins','home_headroom','home_workshop_review'),
    [string[]]$Scripts = @(),
    [int]$Seed = 77,
    [switch]$Prepare,
    [switch]$Import,
    [switch]$Rendered,
    [string]$ExtraArguments = '',
    [int]$TimeoutSeconds = 420,
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
# Bounded home/interaction checks and captures. Copies and user data stay in ignored build/;
# only a process launched by this invocation can be stopped on timeout.
$ErrorActionPreference = 'Stop'
$homeRepo = Split-Path $PSScriptRoot
$homeRoot = Join-Path $homeRepo ('build/' + $ReviewSet)
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
    $homeFixtures = switch ($ReviewSet) {
        'foundry-clarity' { @('foundry_flow_review') }
        'quiet-ambience' { @('ambient_quiet_review') }
        'building-loads' { @('building_load_review','building_load_boundaries') }
        'placement-reliability' { @('placement_transactions','placement_performance_review','placement_scenery','placement_generated_fixtures') }
        'home-reliability' { @('home_terrain_placement','home_station_clearance','home_door_persistence','home_workshop_review') }
        'interaction-feedback' { @('interaction_route') }
        'footsteps-ambience' { @('footsteps_route') }
        'forge-readability' { @('forge_readability_review') }
        'workshop-usability' { @('workshop_readability_review') }
        default { @('home_station_placement','home_headroom','home_workshop_review') }
    }
    foreach ($homeFile in ($homeFixtures | ForEach-Object { "$_.gd"; "$_.tscn" })) {
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
    foreach ($homeScript in $Scripts) {
        if ($homeScript -notmatch '^[a-zA-Z0-9_]+$') { throw 'Script must be a test basename.' }
        Invoke-HomeCheck "$homeScript-script" "--headless --script res://tests/$homeScript.gd"
    }
    foreach ($homeScene in $Scenes) {
        if ($homeScene -notmatch '^[a-zA-Z0-9_]+$') { throw 'Scene must be a test basename.' }
        $homeFlags = if ($Rendered) { '--resolution 1440x900 --position -9999,-9999' } else { '--headless' }
        # This legacy driver asserts process-owned trial rewards on the next
        # physics step. Keep one process frame between its numbered steps.
        if ($homeScene -eq 'integration') { $homeFlags += ' --fixed-fps 60' }
        # Audio samples are exported for review; isolated checks never use the owner's speakers.
        if ($ReviewSet -in @('interaction-feedback','footsteps-ambience','forge-readability','workshop-usability','building-loads','quiet-ambience','foundry-clarity')) { $homeFlags += ' --audio-driver Dummy' }
        $homeMode = if ($Rendered) { 'rendered' } else { 'headless' }
        $homeVariant = if ($ExtraArguments -match '--journey-class=([a-zA-Z0-9_]+)') { '-' + $Matches[1] } elseif ($ExtraArguments -match '--load-baseline') { '-baseline-restart' } elseif ($ExtraArguments -match '--placement-restore-only|--soak-resume|--load-restore-only|--audio-restore-only|--foundry-restore-only') { '-restart' } else { '' }
        Invoke-HomeCheck "$homeScene-$Seed-$homeMode$homeVariant" "$homeFlags res://tests/$homeScene.tscn -- --home-seed=$Seed --home-phase=$Phase $ExtraArguments"
    }
} finally { $env:APPDATA = $priorHomeAppData }
