# A reproducible, local-only image-to-3D attempt. Every invocation gets fresh output.
#requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet(512, 1024, 1536)][int]$Resolution = 1024,
    [ValidateRange(1, 2147483647)][int]$Seed = 42,
    [switch]$GeometryOnly
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$local = Join-Path $repository 'build/trellis-local'
$image = Join-Path $repository 'docs/art/leyline-studies/2026-09-08/wolf-image3d/input-three-quarter-v01.png'
$expectedImageHash = '603da99abb16c5a34295ab8e5bf8117cd0fea05bb0f8b9cb24c9765eb80b2126'
if ((Get-FileHash -LiteralPath $image).Hash.ToLowerInvariant() -ne $expectedImageHash) {
    throw 'The comparison input changed. Inspect it before generating.'
}
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'install-manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest.weights) {
    if ($GeometryOnly -and $entry.name.StartsWith('tex_')) { continue }
    $file = Join-Path $local ('models/' + $entry.name)
    if (-not (Test-Path -LiteralPath $file) -or (Get-Item -LiteralPath $file).Length -ne $entry.bytes) {
        throw ('Finish install.ps1 first: ' + $entry.name)
    }
}
$output = Join-Path $local ('output/wolf-' + $Resolution + '-seed' + $Seed + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $output | Out-Null
$glb = Join-Path $output 'wolf.glb'
$arguments = @('--image', $image, '--output', $glb, '--models', (Join-Path $local 'models'),
    '--gpu', '0', '--require-gpu', '--res', "$Resolution", '--seed', "$Seed",
    '--bg-removal', 'birefnet', '--dump-bg', '--webp', 'off', '--threads', '8')
if ($GeometryOnly) { $arguments += '--no-texture' }
$record = [ordered]@{
    runtime = $manifest.runtime
    runtime_version = $manifest.version
    release_target_commit = $manifest.release_target_commit
    model_repository = $manifest.model_repository
    model_revision = $manifest.model_revision
    input_sha256 = $expectedImageHash
    geometry_only = [bool]$GeometryOnly
    arguments = $arguments
    status = 'started'
    started_utc = [DateTime]::UtcNow.ToString('o')
}
$report = Join-Path $output 'generation.json'
$record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $report -Encoding utf8NoBOM
Write-Output ('Generating locally; progress log: ' + (Join-Path $output 'generation.log'))
$timer = [Diagnostics.Stopwatch]::StartNew()
& (Join-Path $local 'runtime/trellis-cli.exe') @arguments *> (Join-Path $output 'generation.log')
$result = $LASTEXITCODE
$record['seconds'] = $timer.Elapsed.TotalSeconds
$record['exit_code'] = $result
$record['status'] = 'failed'
if ($result -eq 0 -and (Test-Path -LiteralPath $glb)) {
    $record['glb_sha256'] = (Get-FileHash -LiteralPath $glb).Hash.ToLowerInvariant()
    $record['glb_bytes'] = (Get-Item -LiteralPath $glb).Length
    $reader = [IO.BinaryReader]::new([IO.File]::OpenRead($glb))
    try {
        if ($reader.ReadUInt32() -ne 0x46546c67 -or $reader.ReadUInt32() -ne 2) { throw 'Invalid GLB header.' }
        if ($reader.ReadUInt32() -ne $record.glb_bytes) { throw 'GLB length mismatch.' }
        $jsonLength = $reader.ReadUInt32()
        if ($jsonLength -gt 16MB -or $reader.ReadUInt32() -ne 0x4e4f534a) { throw 'Invalid GLB JSON chunk.' }
        $asset = ([Text.Encoding]::UTF8.GetString($reader.ReadBytes($jsonLength)) | ConvertFrom-Json).asset
        # The published binary may report a different build commit from the tag target.
        $record['export_asset_metadata'] = $asset
        $record['status'] = 'exported; Blender inspection pending'
    } catch {
        $record['validation_error'] = $_.Exception.Message
        $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $report -Encoding utf8NoBOM
        throw
    } finally { $reader.Dispose() }
}
$record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $report -Encoding utf8NoBOM
if ($record.status -eq 'failed') { throw ('Generation failed; inspect ' + $report) }
Write-Output ('TRELLIS_WOLF_EXPORTED ' + $glb)
