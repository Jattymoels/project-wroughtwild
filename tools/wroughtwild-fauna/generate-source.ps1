param([Parameter(Mandatory)][string]$InputImage, [Parameter(Mandatory)][string]$Output, [ValidateSet('stag')][string]$Asset='stag')
$ErrorActionPreference = 'Stop'
$faunaRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$faunaImage = (Resolve-Path -LiteralPath $InputImage).Path
$faunaOutput = [IO.Path]::GetFullPath($Output)
if (Test-Path -LiteralPath $faunaOutput) { throw 'Use a fresh generation folder.' }
New-Item -ItemType Directory -Path $faunaOutput | Out-Null
$faunaInstall = Get-Content (Join-Path $faunaRepo 'tools/wroughtwild-trellis/install-manifest.json') -Raw | ConvertFrom-Json
$faunaArguments = @('--image', $faunaImage, '--output', (Join-Path $faunaOutput ($Asset+'.glb')), '--models', (Join-Path $faunaRepo 'build/trellis-local/models'), '--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
$faunaRecord = [ordered]@{input_sha256=(Get-FileHash $faunaImage).Hash.ToLowerInvariant(); arguments=$faunaArguments; runtime=$faunaInstall.runtime; version=$faunaInstall.version; model_revision=$faunaInstall.model_revision; started_utc=[DateTime]::UtcNow.ToString('o')}
$faunaTimer = [Diagnostics.Stopwatch]::StartNew()
& (Join-Path $faunaRepo 'build/trellis-local/runtime/trellis-cli.exe') @faunaArguments *> (Join-Path $faunaOutput 'generation.log')
$faunaRecord.exit_code = $LASTEXITCODE
$faunaRecord.seconds = $faunaTimer.Elapsed.TotalSeconds
if ($LASTEXITCODE -eq 0) { $faunaRecord.glb_sha256 = (Get-FileHash (Join-Path $faunaOutput ($Asset+'.glb'))).Hash.ToLowerInvariant() }
$faunaRecord | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $faunaOutput 'generation.json')
if ($faunaRecord.exit_code -ne 0) { throw 'Stag generation failed; inspect its log.' }
Write-Output "FAUNA_SOURCE_GENERATED $Asset"
