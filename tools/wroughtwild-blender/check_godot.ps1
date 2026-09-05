param(
    [Parameter(Mandatory=$true)][string]$Study,
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$studyPath = (Resolve-Path -LiteralPath $Study).Path
$allowed = [IO.Path]::GetFullPath((Join-Path $repo 'build/blender-study')) + [IO.Path]::DirectorySeparatorChar
if (-not $studyPath.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Study must be inside this checkout build/blender-study folder'
}
$review = Join-Path $studyPath 'godot-review'
New-Item -ItemType Directory -Force -Path $review | Out-Null
Get-ChildItem -LiteralPath $studyPath -Filter '*.glb' | Copy-Item -Destination $review
Copy-Item -LiteralPath (Join-Path $studyPath 'report.json') -Destination $review
$report = Get-Content -LiteralPath (Join-Path $studyPath 'report.json') -Raw | ConvertFrom-Json
$checkScript = switch ($report.study) { 'nature' { 'nature_checks.gd' }; 'furnishings' { 'furnishings_checks.gd' }; 'mobs' { 'mobs_checks.gd' }; default { 'godot_checks.gd' } }
$previewScript = switch ($report.study) { 'nature' { 'nature_preview.gd' }; 'furnishings' { 'furnishings_preview.gd' }; 'mobs' { 'mobs_preview.gd' }; default { 'godot_preview.gd' } }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot $checkScript) -Destination $review
Copy-Item -LiteralPath (Join-Path $PSScriptRoot $previewScript) -Destination $review
if ($report.study -in @('nature', 'furnishings')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'nature_collision_import.gd') -Destination $review
}
if ($report.study -eq 'furnishings') {
    # Compare against the actual game's collision function, independently of
    # Blender's report and the proxy import recipe. No sim extension is needed.
    Copy-Item -LiteralPath (Join-Path $repo 'game/scripts/piece_mesh.gd') -Destination $review
    Copy-Item -LiteralPath (Join-Path $repo 'game/scenes/station_site.tscn') -Destination (Join-Path $review 'station_source.txt')
    Copy-Item -LiteralPath (Join-Path $repo 'data/tuning/construction.json') -Destination (Join-Path $review 'construction.json')
}
if ($report.study -eq 'mobs') {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'mobs_collision_import.gd') -Destination $review
    Copy-Item -LiteralPath (Join-Path $repo 'game/art/character_look.gd') -Destination (Join-Path $review 'character_source.gd')
    foreach ($actor in @('enemy', 'boss', 'player')) {
        Copy-Item -LiteralPath (Join-Path $repo "game/scenes/$actor.tscn") -Destination (Join-Path $review "$($actor)_source.txt")
    }
    Copy-Item -LiteralPath (Join-Path $repo 'data/tuning/combat_realtime.json') -Destination $review
}
$renderMethod = if ($report.study -in @('nature', 'furnishings', 'mobs')) { 'forward_plus' } else { 'gl_compatibility' }
@"
config_version=5
[application]
config/name="Wroughtwild Blender asset checks"
[rendering]
renderer/rendering_method="$renderMethod"
"@ | Set-Content -LiteralPath (Join-Path $review 'project.godot') -Encoding UTF8
& $Godot --headless --path $review --log-file (Join-Path $review 'import.log') --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
# Resource/furnishing proxies represent the game's existing primitive boxes.
$needsReimport = $false
foreach ($settings in Get-ChildItem -LiteralPath $review -Filter '*_collision.glb.import' | Where-Object { $report.study -in @('nature', 'furnishings', 'mobs') }) {
    $before = Get-Content -LiteralPath $settings.FullName -Raw
    $importScript = if ($report.study -eq 'mobs') { 'mobs_collision_import.gd' } else { 'nature_collision_import.gd' }
    $after = $before.Replace('import_script/path=""', "import_script/path=`"res://$importScript`"")
    if ($after -ne $before) {
        Set-Content -LiteralPath $settings.FullName -Value $after -Encoding UTF8 -NoNewline
        # Godot's filesystem cache can miss settings rewritten within the same
        # timestamp second. Invalidate only this generated scene, so the next
        # import must run the new primitive-body script.
        $cachePath = [IO.Path]::GetFullPath((Join-Path $review '.godot/imported'))
        foreach ($cached in Get-ChildItem -LiteralPath $cachePath -Filter "$($settings.BaseName)-*.scn") {
            if ($cached.DirectoryName -ne $cachePath) { throw 'Unexpected import cache location' }
            Remove-Item -LiteralPath $cached.FullName
        }
        $needsReimport = $true
    }
}
if ($needsReimport) {
    & $Godot --headless --path $review --log-file (Join-Path $review 'collision-import.log') --import
    if ($LASTEXITCODE -ne 0) { throw 'Godot primitive collision import failed' }
}
& $Godot --headless --path $review --log-file (Join-Path $review 'checks.log') --script "res://$checkScript"
if ($LASTEXITCODE -ne 0) { throw 'Godot mesh/collision checks failed' }
# Native editor warnings about the sandbox's user settings directory must not
# become PowerShell's script exit status after all checked processes succeed.
exit 0
