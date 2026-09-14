# Manual owner launcher. The game uses normal mouse capture; all state is private.
param([Parameter(Mandatory)][string]$ManifestSha256,[Parameter(Mandatory)][string]$Target,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[string]$Package=$PSScriptRoot)
$ErrorActionPreference='Stop'
$r8Root='D:/project-wroughtwild-art07-r8'
$r8Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$r8Allowed=[IO.Path]::GetFullPath((Join-Path $r8Root 'build/art07-repairs/r8'))+[IO.Path]::DirectorySeparatorChar
$r8Target=[IO.Path]::GetFullPath($Target)
if(-not $r8Target.StartsWith($r8Allowed,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $r8Target)){throw 'Use an absent private version directory under this R8 build root.'}
$r8Hash=$ManifestSha256.ToLower()
if($r8Hash -notmatch '^[0-9a-f]{64}$'){throw 'Supply the independently recorded manifest SHA-256 from the R8 receipt.'}
& $r8Python -B (Join-Path $r8Root 'tools/wroughtwild-art07-repairs/r8/handoff.py') clone --package $Package --manifest-sha256 $r8Hash --target (Join-Path $r8Target 'runtime')
if($LASTEXITCODE -ne 0){throw 'Package verification/copy failed.'}
$r8Game=Join-Path $r8Target 'runtime/game'
$r8Engine=Join-Path $r8Target 'runtime/engine/Godot_v4.5-stable_win64.exe'
$r8Jobs=@(
 @{id='manual-import';program=$r8Engine;arguments=@('--headless','--editor','--path',$r8Game,'--import');log=(Join-Path $r8Target 'logs/manual-import.log');state=(Join-Path $r8Target 'users/import')},
 @{id='manual-play';program=$r8Engine;arguments=@('--rendering-method',$Renderer,'--path',$r8Game,'res://g1/play.tscn');log=(Join-Path $r8Target 'logs/manual-play.log');state=(Join-Path $r8Target 'users/play')}
)
$r8Spec=Join-Path $r8Target 'manual-jobs.json'
$r8Jobs | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $r8Spec -Encoding utf8
Write-Output 'Launching normal play controls with mouse capture. Escape releases the cursor. Save state stays under this fresh version users/play/ART07G1.'
& (Join-Path $r8Root 'tools/wroughtwild-art07-repairs/run.ps1') -Spec $r8Spec
