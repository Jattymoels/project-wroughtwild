param([Parameter(Mandatory)][string]$InputImage, [Parameter(Mandatory)][string]$Output, [ValidateSet('tree','rock')][string]$Asset='tree')
$ErrorActionPreference = 'Stop'
$groveRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$groveImage = (Resolve-Path -LiteralPath $InputImage).Path
$groveOutput = [IO.Path]::GetFullPath($Output)
if (Test-Path -LiteralPath $groveOutput) { throw 'Use a fresh generation folder.' }
New-Item -ItemType Directory -Path $groveOutput | Out-Null
$groveInstall = Get-Content (Join-Path $groveRepo 'tools/wroughtwild-trellis/install-manifest.json') -Raw | ConvertFrom-Json
$groveArguments = @('--image', $groveImage, '--output', (Join-Path $groveOutput ($Asset+'.glb')), '--models', (Join-Path $groveRepo 'build/trellis-local/models'), '--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
$groveRecord = [ordered]@{input_sha256=(Get-FileHash $groveImage).Hash.ToLowerInvariant(); arguments=$groveArguments; runtime=$groveInstall.runtime; version=$groveInstall.version; model_revision=$groveInstall.model_revision; started_utc=[DateTime]::UtcNow.ToString('o')}
$groveTimer = [Diagnostics.Stopwatch]::StartNew()
& (Join-Path $groveRepo 'build/trellis-local/runtime/trellis-cli.exe') @groveArguments *> (Join-Path $groveOutput 'generation.log')
$groveRecord.exit_code = $LASTEXITCODE
$groveRecord.seconds = $groveTimer.Elapsed.TotalSeconds
if ($LASTEXITCODE -eq 0) { $groveRecord.glb_sha256 = (Get-FileHash (Join-Path $groveOutput ($Asset+'.glb'))).Hash.ToLowerInvariant() }
$groveRecord | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $groveOutput 'generation.json')
if ($groveRecord.exit_code -ne 0) { throw 'Tree generation failed; inspect its log.' }
Write-Output "GROVE_SOURCE_GENERATED $Asset"
