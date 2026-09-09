param([Parameter(Mandatory)][string]$Output,[string]$Revision='8aec10ef3b1df190e23fc4f32bc910877e8ded86')
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$destination=[IO.Path]::GetFullPath($(if([IO.Path]::IsPathRooted($Output)){$Output}else{Join-Path $repo $Output}))
if(-not $destination.StartsWith((Join-Path $repo 'build')+[IO.Path]::DirectorySeparatorChar)){throw 'Output must be a fresh directory beneath this repository build/'}
if(Test-Path -LiteralPath $destination){throw 'Use a fresh output directory'}
New-Item -ItemType Directory -Path $destination | Out-Null
$archive=Join-Path $destination 'game-baseline.zip'
& git -C $repo archive --format=zip "--output=$archive" $Revision game data
if($LASTEXITCODE -ne 0){throw 'Cannot archive pinned game/data'}
Expand-Archive -LiteralPath $archive -DestinationPath $destination
$native=Join-Path $destination 'native'
& (Join-Path $repo 'tools/wroughtwild-workshop/build-native.ps1') -Revision $Revision -Output $native
Copy-Item -LiteralPath (Join-Path $native 'bin/libwroughtwild_sim.windows.x86_64.dll') -Destination (Join-Path $destination 'game/bin')
$art=Join-Path $destination 'game/art05';New-Item -ItemType Directory -Path $art | Out-Null
Copy-Item (Join-Path $PSScriptRoot '*.gd'),(Join-Path $PSScriptRoot '*.tscn'),(Join-Path $PSScriptRoot 'route.json') $art
Copy-Item (Join-Path $repo 'tools/wroughtwild-boar/boar_scar.gdshader'),(Join-Path $repo 'tools/wroughtwild-workshop/red_scar.gdshader') $art
Copy-Item (Join-Path $repo 'build/workshop-art04/red-handoff/review/paid-checkpoint.json') (Join-Path $art 'paid-component-checkpoint.json')
& 'C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' (Join-Path $PSScriptRoot 'cook_assets.py') (Join-Path $destination 'game')
if($LASTEXITCODE -ne 0){throw 'Asset cooking failed'}
& (Join-Path $PSScriptRoot 'run.ps1') -Project (Join-Path $destination 'game') -Import
Write-Output "ART05_PREPARED $destination"
