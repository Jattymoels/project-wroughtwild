param([Parameter(Mandatory)][string]$InputImage,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$artDepot='C:/Users/Matty/Dev/project-wroughtwild'
$artRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/b1'))
$artOutput=[IO.Path]::GetFullPath($Output)
if (-not $artOutput.StartsWith($artRoot+[IO.Path]::DirectorySeparatorChar) -or (Test-Path -LiteralPath $artOutput)) { throw 'Need fresh output beneath B1 build root.' }
$artManifest=Get-Content -Raw "$artDepot/tools/wroughtwild-trellis/install-manifest.json" | ConvertFrom-Json
foreach ($weight in $artManifest.weights) {
 $p=Join-Path "$artDepot/build/trellis-local/models" $weight.name
 if ((Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant() -ne $weight.sha256) { throw "Model mismatch: $p" }
}
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU'); $artOwns=$false
try {
 $artOwns=$artMutex.WaitOne(0)
 if (-not $artOwns) { throw 'GPU slot busy.' }
 if (Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }) { throw 'Existing GPU application: inspect before continuing.' }
 New-Item -ItemType Directory -Path $artOutput | Out-Null
 $artCli="$artDepot/build/trellis-local/runtime/trellis-cli.exe"
 $artArgs=@('--image',(Resolve-Path -LiteralPath $InputImage).Path,'--output',"$artOutput/pine.glb",'--models',"$artDepot/build/trellis-local/models",'--gpu','0','--require-gpu','--res','1024','--seed','42','--bg-removal','birefnet','--dump-bg','--webp','off','--threads','8')
 $artStart=Get-Date
 & $artCli @artArgs *> "$artOutput/generation.log"
 $artExit=$LASTEXITCODE
 $artFiles=@{}
 Get-ChildItem -LiteralPath $artOutput -File | ForEach-Object { $artFiles[$_.Name]=@{bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()} }
 @{input=(Resolve-Path $InputImage).Path;input_sha256=(Get-FileHash $InputImage).Hash.ToLowerInvariant();cli_sha256=(Get-FileHash $artCli).Hash.ToLowerInvariant();arguments=$artArgs;start=$artStart.ToString('o');duration_seconds=((Get-Date)-$artStart).TotalSeconds;exit=$artExit;model_revision=$artManifest.model_revision;files=$artFiles} | ConvertTo-Json -Depth 8 | Set-Content "$artOutput/generation.json"
 if ($artExit -ne 0) { throw 'Generation failed; see retained log.' }
} finally { if ($artOwns) { $artMutex.ReleaseMutex() }; $artMutex.Dispose() }
