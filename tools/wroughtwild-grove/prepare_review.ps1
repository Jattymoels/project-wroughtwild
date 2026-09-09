param([Parameter(Mandatory)][string]$Tree,[Parameter(Mandatory)][string]$Kit,[Parameter(Mandatory)][string]$Boar,[Parameter(Mandatory)][string]$Rock,[Parameter(Mandatory)][string]$Normal,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$groveOutput=[IO.Path]::GetFullPath($Output)
if(Test-Path -LiteralPath $groveOutput){throw 'Use a new isolated review directory.'}
New-Item -ItemType Directory -Path $groveOutput | Out-Null
foreach($name in @('project.godot','review.tscn','review.gd','grove_surface.gdshader','water.gdshader','grove.json')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $groveOutput}
Get-ChildItem -LiteralPath $Tree -File | Where-Object {$_.Extension -in @('.glb','.png','.json')} | Copy-Item -Destination $groveOutput
Get-ChildItem -LiteralPath $Kit -File | Where-Object {$_.Extension -in @('.glb','.json')} | Copy-Item -Destination $groveOutput
Get-ChildItem -LiteralPath $Rock -File | Where-Object {$_.Extension -in @('.png','.json')} | Copy-Item -Destination $groveOutput
Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../../docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png') -Destination $groveOutput
Copy-Item -LiteralPath (Join-Path $Normal 'tree-normal.png') -Destination $groveOutput
foreach($name in @('boar-mid.glb','base.png','orm.png','scar-mask.png','normal.png','boar_scar.gdshader','boar-study.json')){Copy-Item -LiteralPath (Join-Path $Boar $name) -Destination $groveOutput}
foreach($file in Get-ChildItem -LiteralPath $groveOutput -Filter '*.glb'){
@'
[remap]
importer="scene"
type="PackedScene"
[params]
meshes/generate_lods=false
animation/fps=100
'@ | Set-Content -LiteralPath ($file.FullName+'.import')
}
foreach($file in Get-ChildItem -LiteralPath $groveOutput -Filter '*.png'){
@'
[remap]
importer="texture"
type="CompressedTexture2D"
[params]
compress/mode=0
mipmaps/generate=true
detect_3d/compress_to=0
'@ | Set-Content -LiteralPath ($file.FullName+'.import')
}
Write-Output "Prepared $groveOutput"
