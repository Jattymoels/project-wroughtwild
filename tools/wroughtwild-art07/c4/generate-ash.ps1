param([Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$artDepot='C:/Users/Matty/Dev/project-wroughtwild'
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/c4'))
$artOut=[IO.Path]::GetFullPath($Output)
if(-not $artOut.StartsWith($artRoot+[IO.Path]::DirectorySeparatorChar) -or (Test-Path $artOut)){throw 'Fresh C4 output required'}
New-Item -ItemType Directory -Path $artOut | Out-Null
$artInput=(Resolve-Path (Join-Path $PSScriptRoot '../../../docs/art/leyline-studies/2026-09-09/art07/c4/ash-input-v01.png')).Path
$artCli=Join-Path $artDepot 'build/trellis-local/runtime/trellis-cli.exe'
$artArgs=@('--image',$artInput,'--output',(Join-Path $artOut 'source.glb'),'--models',(Join-Path $artDepot 'build/trellis-local/models'),'--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
& (Join-Path $PSScriptRoot 'run-job.ps1') -Program $artCli -Arguments $artArgs -Log (Join-Path $artOut 'generation.log') -Gpu
Get-ChildItem $artOut -File | ForEach-Object { @{file=$_.Name;bytes=$_.Length;sha256=(Get-FileHash $_.FullName).Hash.ToLowerInvariant()} } | ConvertTo-Json | Set-Content (Join-Path $artOut 'hashes.json')
