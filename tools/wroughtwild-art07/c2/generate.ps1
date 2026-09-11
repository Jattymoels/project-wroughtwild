param([Parameter(Mandatory)][string]$InputImage,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$artDepot='C:/Users/Matty/Dev/project-wroughtwild'
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/c2'))
$artOutput=[IO.Path]::GetFullPath($Output)
if(-not $artOutput.StartsWith($artRoot+[IO.Path]::DirectorySeparatorChar)){throw 'Output must be within C2 build.'}
if(Test-Path -LiteralPath $artOutput){throw 'Use fresh generation output.'}
$artManifest=Get-Content "$artDepot/tools/wroughtwild-trellis/install-manifest.json" -Raw | ConvertFrom-Json
foreach($artWeight in $artManifest.weights){$artPath=Join-Path "$artDepot/build/trellis-local/models" $artWeight.name;if((Get-Item -LiteralPath $artPath).Length -ne $artWeight.bytes -or (Get-FileHash -LiteralPath $artPath -Algorithm SHA256).Hash.ToLower() -ne $artWeight.sha256){throw "Model mismatch: $($artWeight.name)"}}
$artCli="$artDepot/build/trellis-local/runtime/trellis-cli.exe"
if((Get-FileHash -LiteralPath $artCli -Algorithm SHA256).Hash.ToLower() -ne 'e3d075612388a42fcb9bea73377feac4149e3a463cff2d2e11b24975e85d427d'){throw 'CLI mismatch.'}
New-Item -ItemType Directory -Path $artOutput | Out-Null
$artInput=(Resolve-Path -LiteralPath $InputImage).Path
$artArgs=@('--image',$artInput,'--output',(Join-Path $artOutput 'source.glb'),'--models',"$artDepot/build/trellis-local/models",'--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
& "$PSScriptRoot/run-job.ps1" -Program $artCli -Arguments $artArgs -Log (Join-Path $artOutput 'generation.log') -Gpu
@{input=$artInput;input_sha256=(Get-FileHash -LiteralPath $artInput -Algorithm SHA256).Hash.ToLower();models_verified=$artManifest.weights.Count;manifest=$artManifest;cli_sha256=(Get-FileHash -LiteralPath $artCli -Algorithm SHA256).Hash.ToLower();arguments=$artArgs} | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $artOutput 'provenance.json')
