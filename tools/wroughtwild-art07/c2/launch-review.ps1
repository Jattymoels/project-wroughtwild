param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$CopyTo,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$Native,[switch]$Visible)
$ErrorActionPreference='Stop'
$artPy='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $artPy "$PSScriptRoot/verify_package.py" $Package $CopyTo
if($LASTEXITCODE -ne 0){throw 'Package verification/copy failed.'}
$artProject=Join-Path $CopyTo $(if($Native){'native/game'}else{'review'})
$artPrior=$env:APPDATA;$artPriorLocal=$env:LOCALAPPDATA
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
try{
 $artOwns=$artMutex.WaitOne(0);if(-not $artOwns){throw 'GPU review slot busy.'}
 if(Get-Process | Where-Object{$_.ProcessName -match 'godot|blender|trellis'}){throw 'Existing renderer/generator; coordinate before launch.'}
 $env:APPDATA=Join-Path $CopyTo 'isolated-user';$env:LOCALAPPDATA=Join-Path $CopyTo 'isolated-local-user'
 New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 $artEngine='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
 & $artEngine --headless --editor --path $artProject --import
 if($LASTEXITCODE -ne 0){throw 'Fresh import failed.'}
 $artArgs=@('--path',('"'+$artProject+'"'),'--rendering-method',$Renderer)
 if($Native){$artArgs+=@('--fixed-fps','60','res://c2/native_review.tscn')}
 $artStyle=if($Visible){'Normal'}else{'Hidden'}
 $artProc=Start-Process -FilePath $artEngine -ArgumentList $artArgs -WindowStyle $artStyle -PassThru
 Write-Output "C2 review PID $($artProc.Id), isolated user $env:APPDATA"
 $artProc.WaitForExit()
}finally{$env:APPDATA=$artPrior;$env:LOCALAPPDATA=$artPriorLocal;if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
