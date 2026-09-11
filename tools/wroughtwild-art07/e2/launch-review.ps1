param([ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',
 [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe',
 [switch]$Check)
# Human-invoked launcher: copy and import away from immutable canonical files.
$ErrorActionPreference='Stop'
$e2Manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
$e2Launch=Join-Path $env:TEMP ('Wroughtwild-E2-'+[guid]::NewGuid().ToString('N'))
foreach($e2Row in $e2Manifest.files){
 $e2Input=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot $e2Row.path))
 if(-not $e2Input.StartsWith($PSScriptRoot+[IO.Path]::DirectorySeparatorChar)){throw 'Package path escapes its root'}
 if((Get-FileHash -LiteralPath $e2Input).Hash.ToLowerInvariant() -ne $e2Row.sha256){throw ('Package hash mismatch: '+$e2Row.path)}
 $e2Output=Join-Path $e2Launch $e2Row.path
 New-Item -ItemType Directory -Force (Split-Path $e2Output) | Out-Null
 Copy-Item -LiteralPath $e2Input -Destination $e2Output
}
$e2Prior=$env:APPDATA
$e2Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$e2Owns=$false
try{
 $env:APPDATA=Join-Path $e2Launch 'user'
 & $Godot --headless --editor --import --path (Join-Path $e2Launch 'review/game')
 if($LASTEXITCODE -ne 0){throw 'Fresh E2 import failed'}
 $e2Owns=$e2Mutex.WaitOne(0)
 if(-not $e2Owns){throw 'Shared art slot busy; review copy preserved for later.'}
 $e2Busy=Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and $_.CommandLine -notmatch '--headless'}
 if($e2Busy){throw 'Another rendered art/game job is running; review copy preserved.'}
 $e2Arguments=@('--path',(Join-Path $e2Launch 'review/game'),'--rendering-method',$Renderer,'res://e2/review.tscn')
 if($Check){$e2Arguments+=@('--','--check')}
 & $Godot @e2Arguments
 if($LASTEXITCODE -ne 0){throw 'E2 review failed; inspect its console/evidence.'}
} finally {
 if($e2Owns){$e2Mutex.ReleaseMutex()};$e2Mutex.Dispose();$env:APPDATA=$e2Prior
 Write-Output ('E2 isolated review retained at '+$e2Launch)
}
