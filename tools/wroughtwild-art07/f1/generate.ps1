param([ValidateSet('lanternheart','stormglass')][string]$Subject,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$f1Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$f1Build=[IO.Path]::GetFullPath((Join-Path $f1Root 'build/art07/f1'))
$f1Out=[IO.Path]::GetFullPath($Output)
if (-not $f1Out.StartsWith($f1Build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must remain within F1 build.' }
if(Test-Path -LiteralPath $f1Out){throw 'Use a fresh generation directory.'}
$f1Input=Join-Path $f1Root "docs/art/leyline-studies/2026-09-09/art07/f1/$Subject-input-v01.png"
$f1Depot='C:/Users/Matty/Dev/project-wroughtwild'
New-Item -ItemType Directory -Path $f1Out | Out-Null
$f1Arguments=@('--image',$f1Input,'--output',(Join-Path $f1Out 'source.glb'),'--models',(Join-Path $f1Depot 'build/trellis-local/models'),'--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
& (Join-Path $PSScriptRoot 'queued-job.ps1') -Program (Join-Path $f1Depot 'build/trellis-local/runtime/trellis-cli.exe') -JobArguments $f1Arguments -Log (Join-Path $f1Out 'generation.log')
Get-ChildItem -LiteralPath $f1Out -File | ForEach-Object { @{path=$_.Name;bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()} } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $f1Out 'files.json')
