param(
    [Parameter(Mandatory)][string]$Surface,
    [Parameter(Mandatory)][string]$Rig,
    [Parameter(Mandatory)][string]$Far,
    [Parameter(Mandatory)][string]$Output
)
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $Output) { throw "Review output already exists: $Output" }
New-Item -ItemType Directory -Path $Output | Out-Null
foreach ($name in @('project.godot','review.tscn','review.gd','boar_scar.gdshader','boar-study.json')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $Output
}
foreach ($name in @('base.png','orm.png','scar-mask.png','surface-report.json')) {
    Copy-Item -LiteralPath (Join-Path $Surface $name) -Destination $Output
}
foreach ($name in @('normal.png','boar-near.glb','boar-mid.glb','boar-far.glb','rig-report.json')) {
    Copy-Item -LiteralPath (Join-Path $Rig $name) -Destination $Output
}
if ($Far) {
    foreach ($name in @('boar-far.glb','far-base.png','far-orm.png','far-scar.png','far-normal.png','far-report.json')) {
        Copy-Item -LiteralPath (Join-Path $Far $name) -Destination $Output
    }
}
# This is a separate Godot project: no game autoloads, extension or save paths.
foreach ($file in Get-ChildItem -LiteralPath $Output -Filter '*.glb') {
    @'
[remap]
importer="scene"
type="PackedScene"
[params]
meshes/generate_lods=false
animation/fps=100
'@ | Set-Content -LiteralPath ($file.FullName + '.import')
}
foreach ($file in Get-ChildItem -LiteralPath $Output -Filter '*.png') {
    @'
[remap]
importer="texture"
type="CompressedTexture2D"
[params]
compress/mode=0
mipmaps/generate=true
detect_3d/compress_to=0
'@ | Set-Content -LiteralPath ($file.FullName + '.import')
}
Write-Output (Resolve-Path -LiteralPath $Output).Path
