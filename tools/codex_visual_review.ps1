# Codex, 5 Sep 2026. Reproduce the aesthetic comparison with stock Godot.
param(
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
    [switch]$Checks,
    [switch]$Octagon,
    [switch]$Landforms,
    [switch]$Workshop,
    [switch]$Terrain,
    [switch]$Props,
    [switch]$Crafted,
    [switch]$Roofs,
    [switch]$Woodland,
    [switch]$Traversal,
    [switch]$Weathered,
    [switch]$Grounding,
    [switch]$FieldRoute,
    [switch]$Characters,
    [switch]$Motion,
    [switch]$Continuation,
    [switch]$Stations,
    [switch]$Buildings
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot
$project = Join-Path $repo 'game'
$logs = Join-Path $repo 'build/codex-aesthetic/logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'codex_aesthetic_gallery.html') -Destination (Join-Path $repo 'build/codex-aesthetic/index.html')

function Invoke-GodotReview([string]$Name, [string]$Arguments, [int]$Seconds = 55) {
    $outLog = Join-Path $logs ($Name + '.out.log')
    $errLog = Join-Path $logs ($Name + '.err.log')
    Write-Output "Codex check: $Name"
    $process = Start-Process -FilePath $Godot -ArgumentList "--path `"$project`" $Arguments" -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru
    $processHandle = $process.Handle # Retain the exit code after Windows closes the process.
    if (-not $process.WaitForExit($Seconds * 1000)) {
        # The Windows console wrapper may own a child Godot process. Stop
        # only this invocation, never an editor/game belonging to the owner.
        $children = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($process.Id)"
        foreach ($child in $children) { Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue }
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "$Name exceeded $Seconds seconds; see $logs"
    }
    $text = (Get-Content -LiteralPath $outLog,$errLog -ErrorAction SilentlyContinue) -join "`n"
    $text -split "`n" | Select-String -Pattern 'CODEX_|checks|FAIL|SCRIPT ERROR|ERROR:|Godot Engine|Vulkan' | ForEach-Object { $_.Line }
    # Existing unit tests deliberately exercise invalid input and leave some
    # off-tree render fixtures at exit. Match the original pipeline's exit
    # contract for that suite, but always reject parse errors/failed checks.
    $unexpectedEngineError = $Name -ne 'unit' -and $text -match '(?m)^ERROR:'
    if ($process.ExitCode -ne 0 -or $text -match '(?m)^(SCRIPT ERROR|FAIL)' -or $unexpectedEngineError) {
        throw "$Name failed (exit $($process.ExitCode)); see $logs"
    }
}

if ($Checks) {
    try { Invoke-GodotReview 'import' '--headless --import' }
    catch { Invoke-GodotReview 'import-retry' '--headless --import' }
    Invoke-GodotReview 'unit' '--headless --script res://tests/run_tests.gd'
    Invoke-GodotReview 'art' '--headless --script res://tests/art_checks.gd'
    foreach ($scene in @('integration','horde','grammar','feel')) {
        Invoke-GodotReview $scene "--headless res://tests/$scene.tscn"
    }
    Invoke-GodotReview 'smoke' '--headless --quit-after 120'
    Invoke-GodotReview 'faceted-terrain' '--headless res://tests/faceted_terrain.tscn'
    Invoke-GodotReview 'crafted-traversal' '--headless res://tests/crafted_traversal.tscn'
    Invoke-GodotReview 'roof-workshop-headless' '--headless res://experiments/roof_workshop.tscn'
    Invoke-GodotReview 'woodland-headless' '--headless res://experiments/woodland_comparison.tscn'
    Invoke-GodotReview 'weathered-save' '--headless res://tests/weathered_save.tscn'
    Invoke-GodotReview 'presentation' '--headless res://tests/presentation_checks.tscn'
    Invoke-GodotReview 'material-transitions' '--headless res://tests/material_transitions.tscn'
    Invoke-GodotReview 'creature-motion' '--headless res://tests/creature_motion_checks.tscn'
    Invoke-GodotReview 'frontier-continuation' '--headless res://tests/frontier_continuation_checks.tscn'
    Invoke-GodotReview 'stations-headless' '--headless res://experiments/station_review.tscn'
    Invoke-GodotReview 'buildings-headless' '--headless res://experiments/building_review.tscn'
    Write-Output 'All headless checks passed (Codex PowerShell invocation of the existing pipeline).'
} elseif ($Buildings) {
    Invoke-GodotReview 'buildings-import' '--headless --import'
    Invoke-GodotReview 'buildings-headless' '--headless res://experiments/building_review.tscn'
    Invoke-GodotReview 'buildings-rendered' '--position -9999,-9999 res://experiments/building_review.tscn'
} elseif ($Stations) {
    Invoke-GodotReview 'stations-import' '--headless --import'
    Invoke-GodotReview 'stations-headless' '--headless res://experiments/station_review.tscn'
    Invoke-GodotReview 'stations-rendered' '--position -9999,-9999 res://experiments/station_review.tscn'
} elseif ($Continuation) {
    Invoke-GodotReview 'continuation-import' '--headless --import'
    Invoke-GodotReview 'frontier-continuation' '--headless res://tests/frontier_continuation_checks.tscn'
    Invoke-GodotReview 'continuation-review' '--position -9999,-9999 res://experiments/frontier_continuation_review.tscn'
    Invoke-GodotReview 'frontier-continuation-rendered' '--position -9999,-9999 res://tests/frontier_continuation_checks.tscn'
} elseif ($Motion) {
    Invoke-GodotReview 'motion-import' '--headless --import'
    Invoke-GodotReview 'creature-motion' '--headless res://tests/creature_motion_checks.tscn'
    Invoke-GodotReview 'presentation' '--headless res://tests/presentation_checks.tscn'
    Invoke-GodotReview 'motion-review' '--position -9999,-9999 res://experiments/creature_motion_review.tscn'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'codex_creature_motion_player.html') -Destination (Join-Path $repo 'build/codex-aesthetic/creature-motion/index.html')
} elseif ($Characters) {
    Invoke-GodotReview 'presentation' '--headless res://tests/presentation_checks.tscn'
    Invoke-GodotReview 'characters' '--position -9999,-9999 res://experiments/character_review.tscn'
} elseif ($Weathered) {
    Invoke-GodotReview 'material-transitions' '--headless res://tests/material_transitions.tscn'
    Invoke-GodotReview 'landform-weathered' '--position -9999,-9999 --quit-after 400 res://experiments/landform_comparison.tscn -- --landform-look --weathered-look'
    Invoke-GodotReview 'woodland-weathered' '--position -9999,-9999 res://experiments/woodland_comparison.tscn -- --weathered-look'
} elseif ($Grounding) {
    Invoke-GodotReview 'grounding' '--position -9999,-9999 res://tests/scenery_grounding.tscn'
    Invoke-GodotReview 'weathered-save' '--headless res://tests/weathered_save.tscn'
} elseif ($FieldRoute) {
    Invoke-GodotReview 'field-route' '--position -9999,-9999 res://experiments/field_route.tscn'
} elseif ($Crafted) {
    Invoke-GodotReview 'landform-faceted' '--position -9999,-9999 --quit-after 400 res://experiments/landform_comparison.tscn -- --landform-look --frontier-look --faceted-look'
    Invoke-GodotReview 'landform-crafted' '--position -9999,-9999 --quit-after 400 res://experiments/landform_comparison.tscn -- --landform-look --crafted-look'
} elseif ($Roofs) {
    Invoke-GodotReview 'roof-workshop-headless' '--headless res://experiments/roof_workshop.tscn'
    Invoke-GodotReview 'roof-workshop-windowed' '--position -9999,-9999 res://experiments/roof_workshop.tscn'
    Invoke-GodotReview 'roof-workshop-playable' '--position -9999,-9999 res://experiments/roof_workshop.tscn -- --workshop-play --workshop-smoke'
} elseif ($Woodland) {
    Invoke-GodotReview 'woodland' '--position -9999,-9999 res://experiments/woodland_comparison.tscn'
} elseif ($Traversal) {
    Invoke-GodotReview 'crafted-traversal' '--headless res://tests/crafted_traversal.tscn'
} elseif ($Props) {
    Invoke-GodotReview 'prop-repair' '--position -9999,-9999 res://experiments/prop_repair_comparison.tscn'
} elseif ($Terrain) {
    Invoke-GodotReview 'faceted-terrain' '--headless res://tests/faceted_terrain.tscn'
} elseif ($Workshop) {
    Invoke-GodotReview 'workshop-headless' '--headless res://experiments/workshop_lab.tscn'
    Invoke-GodotReview 'workshop-windowed' '--position -9999,-9999 res://experiments/workshop_lab.tscn'
} elseif ($Landforms) {
    Invoke-GodotReview 'landform-control' '--position -9999,-9999 --quit-after 400 res://experiments/landform_comparison.tscn -- --frontier-look'
    Invoke-GodotReview 'landform-candidate' '--position -9999,-9999 --quit-after 400 res://experiments/landform_comparison.tscn -- --frontier-look --landform-look'
    Invoke-GodotReview 'landform-faceted' '--position -9999,-9999 --quit-after 400 res://experiments/landform_comparison.tscn -- --frontier-look --landform-look --faceted-look'
} elseif ($Octagon) {
    Invoke-GodotReview 'octagon-headless' '--headless res://experiments/octagon_lab.tscn'
    Invoke-GodotReview 'octagon-windowed' '--position -9999,-9999 res://experiments/octagon_lab.tscn'
} else {
    Invoke-GodotReview 'baseline' '--position -9999,-9999 --quit-after 400 res://experiments/aesthetic_comparison.tscn -- --legacy-look'
    Invoke-GodotReview 'frontier' '--position -9999,-9999 --quit-after 400 res://experiments/aesthetic_comparison.tscn -- --frontier-look'
}
