param([Parameter(Mandatory)][string]$WolfReview,[Parameter(Mandatory)][string]$StagReview,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
if (Test-Path -LiteralPath $Output) { throw 'Use a fresh gallery output.' }
$faunaRepo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$faunaGrove=Join-Path $faunaRepo 'build/grove-art02/emberroot-handoff/review'
New-Item -ItemType Directory -Path $Output | Out-Null
foreach ($file in Get-ChildItem -LiteralPath $faunaGrove -File) {
    if ($file.Extension -notin @('.import','.log','.uid')) { Copy-Item -LiteralPath $file.FullName -Destination $Output }
}
# Preserve ART-02. Adapt only the copied entry point so this gallery owns its run.
$faunaBase=Get-Content (Join-Path $Output 'review.gd') -Raw
$faunaBase=$faunaBase.Replace('"--capture"','"--grove-capture"').Replace('"--check"','"--grove-check"').Replace('"--benchmark"','"--grove-benchmark"')
$faunaBase=$faunaBase.Replace("`telse:`n`t`tInput.mouse_mode", "`telif args.is_empty():`n`t`tInput.mouse_mode").Replace("`telse:`r`n`t`tInput.mouse_mode", "`telif args.is_empty():`r`n`t`tInput.mouse_mode")
$faunaBase | Set-Content (Join-Path $Output 'grove_base.gd')
Copy-Item (Join-Path $PSScriptRoot 'grove_gallery.gd') (Join-Path $Output 'review.gd')
Copy-Item (Join-Path $PSScriptRoot 'fauna_scar.gdshader') $Output
foreach ($faunaPair in @(@('wolf',$WolfReview),@('stag',$StagReview))) {
    $faunaName=$faunaPair[0]; $faunaReview=$faunaPair[1]
    foreach ($name in @('base.png','orm.png','normal.png','scar-mask.png','rig-report.json')) { Copy-Item (Join-Path $faunaReview $name) (Join-Path $Output ($faunaName+'-'+$name)) }
    foreach ($name in @(($faunaName+'-mid.glb'),($faunaName+'.json'))) { Copy-Item (Join-Path $faunaReview $name) $Output }
}
Copy-Item (Join-Path $faunaRepo 'game/assets/authored/mobs/marsh_wisp.glb') (Join-Path $Output 'moth.glb')
foreach ($file in Get-ChildItem -LiteralPath $Output -Filter '*.glb') {
    @'
[remap]
importer="scene"
type="PackedScene"
[params]
meshes/generate_lods=false
animation/fps=100
'@ | Set-Content -LiteralPath ($file.FullName+'.import')
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
'@ | Set-Content -LiteralPath ($file.FullName+'.import')
}
Write-Output (Resolve-Path -LiteralPath $Output).Path
