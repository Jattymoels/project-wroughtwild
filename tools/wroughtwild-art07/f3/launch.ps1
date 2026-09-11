param([ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',
 [ValidateSet('import','interactive','checks','restore-cycle','restart','restart-depleted')][string]$Mode='interactive',
 [switch]$Show)
# Copy the sealed package first. This launcher belongs at the copied root.
$ErrorActionPreference='Stop'
$f3Package=[IO.Path]::GetFullPath($PSScriptRoot)
if(-not (Test-Path -LiteralPath (Join-Path $f3Package 'preimport-verification.json'))){throw 'Use the verified fresh-copy root, not the recipe directory.'}
$f3Project=Join-Path $f3Package 'review/game'
$f3Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$f3Prior=$env:APPDATA
$f3Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$f3Owns=$false
try {
 $env:APPDATA=Join-Path $f3Package 'user'
 $f3Args=@('--path',$f3Project,'--audio-driver','Dummy')
 if($Mode -eq 'interactive'){
  $f3Owns=$f3Mutex.WaitOne(0)
  if(-not $f3Owns){throw 'ART-07 GPU slot busy; launch later.'}
  $f3Busy=Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(blender|trellis.*|godot.*)\.exe$' -and $_.CommandLine -notmatch '--headless'}
  if($f3Busy){throw 'An existing art/game process is running; launch later.'}
  $f3Args+=@('--rendering-method',$Renderer)
 } else {$f3Args+=@('--headless','--fixed-fps','60')}
 if($Mode -eq 'import'){$f3Args+=@('--editor','--import')}else{$f3Args+=@('--',('--'+$Mode))}
 $f3Window=if($Show){'Normal'}else{'Hidden'}
 $f3Process=Start-Process -FilePath $f3Godot -ArgumentList @($f3Args|ForEach-Object{'"'+$_+'"'}) -WindowStyle $f3Window -PassThru
 $f3Process.WaitForExit()
 if($f3Process.ExitCode -ne 0){throw ('F3 review exit '+$f3Process.ExitCode)}
}finally{
 $env:APPDATA=$f3Prior
 if($f3Owns){$f3Mutex.ReleaseMutex()}
 $f3Mutex.Dispose()
}
