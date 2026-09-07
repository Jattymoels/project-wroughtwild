param(
    [ValidateSet('baseline','current')][string]$Phase = 'current',
    [string[]]$Scenes = @('exploration_review'),
    [int]$Seed = 77,
    [switch]$Prepare,
    [switch]$Import,
    [switch]$Rendered,
    [string]$ExtraArguments = '',
    [int]$TimeoutSeconds = 420,
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
# Bounded INT-02 checks/captures. Copies and user data stay in ignored build/;
# only a process launched by this invocation can be stopped on timeout.
$ErrorActionPreference = 'Stop'
$storyRepo = Split-Path $PSScriptRoot
$storyRoot = Join-Path $storyRepo 'build/exploration'
$storyCopy = Join-Path $storyRoot $Phase
$storyGame = Join-Path $storyCopy 'game'
$storyLogs = Join-Path $storyRoot ('logs/' + $Phase)
New-Item -ItemType Directory -Force -Path $storyLogs | Out-Null
if ($Prepare) {
    if ($Phase -eq 'baseline' -and (Test-Path -LiteralPath (Join-Path $storyGame 'project.godot'))) {
        throw 'The preserved baseline already exists; do not overwrite it with current source.'
    }
    foreach ($storyFolder in @('game','data')) {
        & robocopy (Join-Path $storyRepo $storyFolder) (Join-Path $storyCopy $storyFolder) /E /XD .godot /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "Copy failed: $storyFolder" }
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $storyGame 'project.godot'))) { throw 'Prepare the isolated project first.' }
if ($Phase -eq 'baseline') {
    # Replay only the new common camera fixture against untouched production.
    foreach ($storyFile in @('exploration_review.gd','exploration_review.tscn')) {
        Copy-Item -LiteralPath (Join-Path $storyRepo "game/tests/$storyFile") -Destination (Join-Path $storyGame "tests/$storyFile")
    }
}
foreach ($storyFolder in @('cataclysm','codex-aesthetic','strange-frontier')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $storyCopy "build/$storyFolder") | Out-Null
}
$storyAppData = Join-Path $storyRoot ('appdata/' + $Phase)
New-Item -ItemType Directory -Force -Path $storyAppData | Out-Null
$priorStoryAppData = $env:APPDATA
try {
    $env:APPDATA = $storyAppData
    function Invoke-StoryCheck([string]$Name,[string]$Arguments) {
        $storyOut = Join-Path $storyLogs ($Name + '.out.log')
        $storyErr = Join-Path $storyLogs ($Name + '.err.log')
        $storyProcess = Start-Process -FilePath $Godot -ArgumentList "--path `"$storyGame`" $Arguments" -WindowStyle Hidden -RedirectStandardOutput $storyOut -RedirectStandardError $storyErr -PassThru
        $storyHandle = $storyProcess.Handle
        $storyWatch = [Diagnostics.Stopwatch]::StartNew()
        while (-not $storyProcess.WaitForExit(1000)) {
            if ($storyWatch.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
                foreach ($storyChild in (Get-CimInstance Win32_Process -Filter "ParentProcessId = $($storyProcess.Id)")) {
                    Stop-Process -Id $storyChild.ProcessId -Force -ErrorAction SilentlyContinue
                }
                Stop-Process -Id $storyProcess.Id -Force -ErrorAction SilentlyContinue
                throw "$Name timed out; see $storyLogs"
            }
        }
        $storyText = (Get-Content -LiteralPath $storyOut,$storyErr -ErrorAction SilentlyContinue) -join "`n"
        $storyText -split "`n" | Select-String -Pattern 'checks|EXPLORATION_|FAIL|SCRIPT ERROR|ERROR:' | ForEach-Object { $_.Line }
        if ($storyProcess.ExitCode -ne 0 -or $storyText -match '(?m)^(SCRIPT ERROR|ERROR:|FAIL)') { throw "$Name failed ($($storyProcess.ExitCode)); see $storyLogs" }
        Write-Output "PASS $Phase $Name"
    }
    if ($Import) { Invoke-StoryCheck 'import' '--headless --import' }
    foreach ($storyScene in $Scenes) {
        if ($storyScene -notmatch '^[a-zA-Z0-9_]+$') { throw 'Scene must be a test basename.' }
        $storyFlags = if ($Rendered) { '--resolution 1440x900 --position -9999,-9999' } else { '--headless' }
        $storyMode = if ($Rendered) { 'rendered' } else { 'headless' }
        $storyVariant = if ($ExtraArguments -match '--story-profile=([a-zA-Z0-9_]+)') { '-' + $Matches[1] } else { '' }
        Invoke-StoryCheck "$storyScene-$Seed-$storyMode$storyVariant" "$storyFlags res://tests/$storyScene.tscn -- --story-seed=$Seed --story-phase=$Phase $ExtraArguments"
    }
} finally { $env:APPDATA = $priorStoryAppData }
