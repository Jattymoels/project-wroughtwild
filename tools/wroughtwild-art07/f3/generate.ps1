param([ValidateSet('pullstone','ventlung')][string]$Subject,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$f3Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$f3Build=[IO.Path]::GetFullPath((Join-Path $f3Root 'build/art07/f3'))
$f3Out=[IO.Path]::GetFullPath($Output)
if (-not $f3Out.StartsWith($f3Build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Output must remain within F3 build.' }
if(Test-Path -LiteralPath $f3Out){throw 'Use a fresh generation directory.'}
$f3Input=Join-Path $f3Root "docs/art/leyline-studies/2026-09-09/art07/f3/$Subject-input-v01.png"
$f3Depot='C:/Users/Matty/Dev/project-wroughtwild'
New-Item -ItemType Directory -Path $f3Out | Out-Null
$f3Arguments=@('--image',$f3Input,'--output',(Join-Path $f3Out 'source.glb'),'--models',(Join-Path $f3Depot 'build/trellis-local/models'),'--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
& (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program (Join-Path $f3Depot 'build/trellis-local/runtime/trellis-cli.exe') -JobArguments $f3Arguments -Log (Join-Path $f3Out 'generation.log')
Get-ChildItem -LiteralPath $f3Out -File | ForEach-Object { @{path=$_.Name;bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()} } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $f3Out 'files.json')
