param(
    [ValidateSet('baseline','current')][string]$Phase = 'current',
    [ValidateSet('world','travel','scheduling','focus')][string]$ReviewSuite = 'world',
    [Alias('Scene')][string[]]$Scenes = @('world_performance_review'),
    [ValidateSet('frontier_v5','frontier_v6')][string]$Profile = 'frontier_v6',
    [int]$Seed = 1,
    [string]$ReviewName = 'review',
    [switch]$Prepare,
    [switch]$Import,
    [switch]$Rendered,
    [string]$NativeLibrary = '',
    [string]$ExtraArguments = '',
    [int]$TimeoutSeconds = 420,
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
# Common INT-07B/D/E/F routes and existing correctness scenes, in separate cold
# processes. Never write to the owner's user data or replace baseline production.
$ErrorActionPreference = 'Stop'
if ($ReviewName -notmatch '^[a-z0-9_-]+$') { throw 'ReviewName must be a simple directory name.' }
foreach ($worldScene in $Scenes) {
    if ($worldScene -notmatch '^[A-Za-z0-9_]+$') { throw 'Scene names must be simple test basenames.' }
}
$worldRepo = Split-Path $PSScriptRoot
$worldRoot = Join-Path $worldRepo "build/$ReviewSuite-performance"
$worldCopy = Join-Path $worldRoot $Phase
$worldGame = Join-Path $worldCopy 'game'
$worldLabel = "$Profile-$Seed-$ReviewName"
$worldLogs = Join-Path $worldRoot "logs/$Phase/$worldLabel"
$worldOutput = Join-Path $worldRoot "captures/$Phase/$worldLabel"
New-Item -ItemType Directory -Force -Path $worldLogs,$worldOutput | Out-Null
if ($Prepare) {
    if ($Phase -eq 'baseline') { throw 'Preserve the suite baseline separately (world: f08806e; travel: 2500db8; scheduling: e370970; focus: b06da19); this runner never prepares it from current source.' }
    foreach ($worldFolder in @('game','data')) {
        & robocopy (Join-Path $worldRepo $worldFolder) (Join-Path $worldCopy $worldFolder) /E /XD .godot /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "Copy failed: $worldFolder" }
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $worldGame 'project.godot'))) { throw 'Prepare/preserve the isolated project first.' }
if ($NativeLibrary) {
    if ($Phase -eq 'baseline') { throw 'The preserved baseline DLL cannot be replaced through this runner.' }
    Copy-Item -LiteralPath $NativeLibrary -Destination (Join-Path $worldGame 'bin/libwroughtwild_sim.windows.x86_64.dll') -Force
}
# Only these common test sources cross into the immutable baseline copy.
foreach ($worldFixture in @('world_performance_review','world_mesh_equivalence','terrain_preparation')) {
    foreach ($worldExtension in @('gd','tscn')) {
        Copy-Item -LiteralPath (Join-Path $worldRepo "game/tests/$worldFixture.$worldExtension") -Destination (Join-Path $worldGame "tests/$worldFixture.$worldExtension") -Force
    }
}
if ($ReviewSuite -in @('travel','scheduling','focus')) {
    foreach ($worldFile in @('travel_performance_review.gd','travel_performance_review.tscn','travel_profile_terrain.gd','resource_presentation_review.gd','resource_presentation_review.tscn','leyline_mesh_equivalence.gd','leyline_mesh_equivalence.tscn')) {
        Copy-Item -LiteralPath (Join-Path $worldRepo "game/tests/$worldFile") -Destination (Join-Path $worldGame "tests/$worldFile") -Force
    }
}
foreach ($worldFolder in @('cataclysm','codex-aesthetic','strange-frontier')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $worldCopy "build/$worldFolder") | Out-Null
}
$worldAppData = Join-Path $worldRoot "appdata/$Phase/$worldLabel"
New-Item -ItemType Directory -Force -Path $worldAppData | Out-Null
$priorWorldAppData = $env:APPDATA
try {
    $env:APPDATA = $worldAppData
    function Invoke-WorldReview([string]$Name, [string]$Arguments) {
        $worldOutLog = Join-Path $worldLogs "$Name.out.log"
        $worldErrLog = Join-Path $worldLogs "$Name.err.log"
        $worldProcess = Start-Process -FilePath $Godot -ArgumentList "--path `"$worldGame`" --audio-driver Dummy $Arguments" -WindowStyle Hidden -RedirectStandardOutput $worldOutLog -RedirectStandardError $worldErrLog -PassThru
        $worldRetainedHandle = $worldProcess.Handle
        $worldWatch = [Diagnostics.Stopwatch]::StartNew()
        $worldFailure = ''
        while (-not $worldProcess.WaitForExit(1000)) {
            $worldErrorText = Get-Content -LiteralPath $worldErrLog -Raw -ErrorAction SilentlyContinue
            if ($worldErrorText -match '(?m)^(SCRIPT ERROR|ERROR:|FAIL)') { $worldFailure = 'reported a script/runtime error'; break }
            if ($worldWatch.Elapsed.TotalSeconds -gt $TimeoutSeconds) { $worldFailure = 'timed out'; break }
        }
        if ($worldFailure) {
            # Only this invocation's owned process and its direct children.
            Get-CimInstance Win32_Process -Filter "ParentProcessId = $($worldProcess.Id)" | ForEach-Object {
                Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            }
            Stop-Process -Id $worldProcess.Id -Force -ErrorAction SilentlyContinue
            throw "$Name $worldFailure; logs: $worldLogs"
        }
        $worldWatch.Stop()
        $worldText = (Get-Content -LiteralPath $worldOutLog,$worldErrLog -ErrorAction SilentlyContinue) -join "`n"
        $worldText -split "`n" | Select-String -Pattern 'checks|failures|FAIL|SCRIPT ERROR|ERROR:|WORLD_PERFORMANCE|WIDE_TERRAIN|Godot Engine' | ForEach-Object { $_.Line }
        if ($worldProcess.ExitCode -ne 0 -or $worldText -match '(?m)^(SCRIPT ERROR|ERROR:|FAIL)') { throw "$Name failed; logs: $worldLogs" }
        @{ phase=$Phase; profile=$Profile; seed=$Seed; review=$ReviewName; operation=$Name; process_elapsed_ms=$worldWatch.Elapsed.TotalMilliseconds; exit_code=$worldProcess.ExitCode } |
            ConvertTo-Json | Set-Content -LiteralPath (Join-Path $worldLogs "$Name.process.json") -Encoding UTF8
    }
    if ($Import) { Invoke-WorldReview 'import' '--headless --import' }
    foreach ($worldScene in $Scenes) {
        Invoke-WorldReview "$worldScene-parse" "--headless --check-only --script res://tests/$worldScene.gd"
        $worldDisplay = if ($Rendered) { '--resolution 1440x900 --position -9999,-9999' } else { '--headless' }
        $worldMode = if ($Rendered) { 'rendered' } else { 'headless' }
        $worldArgs = "--review-phase=$Phase --review-profile=$Profile --review-seed=$Seed --stream-profile=$Profile --review-output=`"$worldOutput`""
        Invoke-WorldReview "$worldScene-$worldMode" "$worldDisplay res://tests/$worldScene.tscn -- $worldArgs $ExtraArguments"
    }
} finally {
    $env:APPDATA = $priorWorldAppData
}
