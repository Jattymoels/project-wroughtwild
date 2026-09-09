param(
    [Parameter(Mandatory)][ValidateSet('cinder_archer','stone_husk','shrieker','gloom_crawler','bog_lurker','hollow_knight')][string]$Asset,
    [Parameter(Mandatory)][string]$InputImage,
    [Parameter(Mandatory)][string]$Output
)
$ErrorActionPreference = 'Stop'
$rosterRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$rosterImage = (Resolve-Path -LiteralPath $InputImage).Path
$rosterOutput = [IO.Path]::GetFullPath($Output)
$rosterBuild = [IO.Path]::GetFullPath((Join-Path $rosterRepo 'build')) + [IO.Path]::DirectorySeparatorChar
if (-not $rosterOutput.StartsWith($rosterBuild, [StringComparison]::OrdinalIgnoreCase)) { throw 'Generation must use an ignored project build folder.' }
if (Test-Path -LiteralPath $rosterOutput) { throw 'Use a fresh generation folder.' }
New-Item -ItemType Directory -Path $rosterOutput | Out-Null
$rosterInstall = Get-Content (Join-Path $rosterRepo 'tools/wroughtwild-trellis/install-manifest.json') -Raw | ConvertFrom-Json
$rosterArgs = @('--image', $rosterImage, '--output', (Join-Path $rosterOutput ($Asset+'.glb')), '--models', (Join-Path $rosterRepo 'build/trellis-local/models'), '--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
$rosterRecord = [ordered]@{asset=$Asset; input_sha256=(Get-FileHash $rosterImage).Hash.ToLowerInvariant(); arguments=$rosterArgs; runtime=$rosterInstall.runtime; version=$rosterInstall.version; model_revision=$rosterInstall.model_revision; started_utc=[DateTime]::UtcNow.ToString('o'); status='running'}
$rosterRecord | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $rosterOutput 'generation.json') -Encoding utf8
$rosterTimer = [Diagnostics.Stopwatch]::StartNew()
& (Join-Path $rosterRepo 'build/trellis-local/runtime/trellis-cli.exe') @rosterArgs *> (Join-Path $rosterOutput 'generation.log')
$rosterRecord.exit_code = $LASTEXITCODE
$rosterRecord.seconds = $rosterTimer.Elapsed.TotalSeconds
$rosterRecord.status = if ($LASTEXITCODE -eq 0) { 'source_generated_not_rigged' } else { 'failed' }
if ($LASTEXITCODE -eq 0) { $rosterRecord.glb_sha256 = (Get-FileHash (Join-Path $rosterOutput ($Asset+'.glb'))).Hash.ToLowerInvariant() }
$rosterRecord.input_unchanged = ((Get-FileHash $rosterImage).Hash.ToLowerInvariant() -eq $rosterRecord.input_sha256)
$rosterRecord | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $rosterOutput 'generation.json') -Encoding utf8
if ($rosterRecord.exit_code -ne 0) { throw "Generation failed for $Asset; inspect its log." }
if (-not $rosterRecord.input_unchanged) { throw 'Generation input changed.' }
Write-Output "ROSTER_SOURCE_GENERATED $Asset"
