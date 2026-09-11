param([Parameter(Mandatory)][string]$InputImage,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$f2Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$f2Depot='C:/Users/Matty/Dev/project-wroughtwild'
$f2Output=[IO.Path]::GetFullPath($Output)
if(-not $f2Output.StartsWith((Join-Path $f2Root 'build/art07/f2')+[IO.Path]::DirectorySeparatorChar)){throw 'Output outside F2'}
if(Test-Path -LiteralPath $f2Output){throw 'Fresh output required'}
$f2Input=(Resolve-Path -LiteralPath $InputImage).Path
$f2Manifest=Get-Content -LiteralPath "$f2Depot/tools/wroughtwild-trellis/install-manifest.json" -Raw | ConvertFrom-Json
$f2Models="$f2Depot/build/trellis-local/models"
$f2Checks=@()
foreach($f2Entry in $f2Manifest.weights){
  $f2Path=Join-Path $f2Models $f2Entry.name
  $f2Hash=(Get-FileHash -LiteralPath $f2Path).Hash.ToLowerInvariant()
  if($f2Hash -ne $f2Entry.sha256){throw "Pinned model mismatch: $f2Path"}
  $f2Checks+=@{path=$f2Path;sha256=$f2Hash}
}
New-Item -ItemType Directory -Path $f2Output | Out-Null
$f2Args=@('--image',$f2Input,'--output',(Join-Path $f2Output 'source.glb'),'--models',$f2Models,'--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
@{input=$f2Input;input_sha256=(Get-FileHash -LiteralPath $f2Input).Hash.ToLowerInvariant();runtime=$f2Manifest;verified_models=$f2Checks;arguments=$f2Args} | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $f2Output 'provenance.json')
& (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program "$f2Depot/build/trellis-local/runtime/trellis-cli.exe" -JobArguments $f2Args -Log (Join-Path $f2Output 'generation.log')
if(-not (Test-Path -LiteralPath (Join-Path $f2Output 'source.glb'))){throw 'No generated source'}
Get-ChildItem -LiteralPath $f2Output -File | Get-FileHash | Select-Object Path,Hash | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $f2Output 'output-hashes.json')
