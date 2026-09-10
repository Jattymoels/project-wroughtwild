param([string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
 [ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus')
$ErrorActionPreference='Stop'
$d5Package=$PSScriptRoot
$d5Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$d5Fresh=Join-Path ([IO.Path]::GetTempPath()) ('ww-d5-'+[guid]::NewGuid().ToString('N').Substring(0,8))
& $d5Python (Join-Path $d5Package 'recipes/verify_handoff.py') $d5Package $d5Fresh
if($LASTEXITCODE -ne 0){throw 'Package verification failed'}
$d5Prior=$env:APPDATA
try {
 $env:APPDATA=Join-Path $d5Fresh 'user'
 & $Godot --headless --path (Join-Path $d5Fresh 'review') --editor --import
 if($LASTEXITCODE -ne 0){throw 'Fresh import failed'}
 & $Godot --path (Join-Path $d5Fresh 'review') --rendering-method $Renderer
} finally {$env:APPDATA=$d5Prior}
