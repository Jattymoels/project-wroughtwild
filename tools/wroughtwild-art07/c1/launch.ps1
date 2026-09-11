param([Parameter(Mandatory)][string]$CopyTo,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[ValidateSet('review','capture','motion','benchmark','native')][string]$Stage='review')
$ErrorActionPreference='Stop'
# This launcher belongs at the handoff root. Never import into the canonical package.
$artPackage=$PSScriptRoot
$artCopy=[IO.Path]::GetFullPath($CopyTo)
if(Test-Path -LiteralPath $artCopy){throw 'Choose a fresh copy directory.'}
if($artCopy.StartsWith($artPackage+[IO.Path]::DirectorySeparatorChar)){throw 'Copy must be outside the canonical handoff.'}
$artPython='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $artPython (Join-Path $artPackage 'recipes/copy_verify.py') $artPackage $artCopy
if($LASTEXITCODE -ne 0){throw 'Package verification failed.'}
$artPrevious=$env:APPDATA;$artPreviousLocal=$env:LOCALAPPDATA
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artHeld=$false
try {
 $artHeld=$artMutex.WaitOne(0)
 if(-not $artHeld -or (Get-Process | Where-Object {$_.ProcessName -match 'godot|blender|trellis'})){throw 'Art slot or another renderer is busy; nothing was interrupted.'}
 $env:APPDATA=Join-Path $artCopy 'isolated-user';$env:LOCALAPPDATA=Join-Path $artCopy 'isolated-local'
 New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 $artProject=Join-Path $artCopy 'review'
 if($Stage -eq 'native'){$artProject=Join-Path $artCopy 'native/game'}
 $artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
 function Invoke-C1([string[]]$JobArgs,[string]$Name){
  $quoted=($JobArgs | ForEach-Object {'"'+$_.Replace('"','\"')+'"'}) -join ' '
  $proc=Start-Process $artGodot -ArgumentList $quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $artCopy ($Name+'.log')) -RedirectStandardError (Join-Path $artCopy ($Name+'.stderr'))
  $proc.WaitForExit();$proc.Refresh();if($proc.ExitCode -ne 0){throw "C1 $Name failed. Inspect its log."}
 }
 Invoke-C1 @('--headless','--editor','--path',$artProject,'--import') 'import'
 $artArgs=@('--audio-driver','Dummy','--path',$artProject,'--rendering-method',$Renderer)
 if($Stage -notin @('review','benchmark')){$artArgs+=@('--fixed-fps','60')}
 if($Stage -eq 'native'){$artArgs+='res://c1/native_review.tscn'}elseif($Stage -ne 'review'){$artArgs+=@('--',('--'+$Stage))}
 Invoke-C1 $artArgs $Stage
} finally {$env:APPDATA=$artPrevious;$env:LOCALAPPDATA=$artPreviousLocal;if($artHeld){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
