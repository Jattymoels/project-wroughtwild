param([ValidateSet('import','check','restore','exhausted','play')][string]$Mode='play',
 [ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',
 [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe', [switch]$Show)
$ErrorActionPreference='Stop'
$f4Package=[IO.Path]::GetFullPath($PSScriptRoot)
if(-not(Test-Path -LiteralPath (Join-Path $f4Package 'preimport-verification.json'))){throw 'Launch only a fresh verified copy, not the sealed package.'}
$f4Prior=$env:APPDATA
$f4Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$f4Owns=$false
try {
 $env:APPDATA=Join-Path $f4Package 'user'
 $f4Save=Join-Path $env:APPDATA 'F4Native'
 New-Item -ItemType Directory -Force -Path $f4Save | Out-Null
 foreach($f4Name in @('f4-held.json','f4-exhausted.json')) {
  $f4Target=Join-Path $f4Save $f4Name
  if(-not(Test-Path -LiteralPath $f4Target)){Copy-Item -LiteralPath (Join-Path $f4Package ('checkpoints/'+$f4Name)) -Destination $f4Target}
 }
 $f4Args=@('--audio-driver','Dummy','--path',(Join-Path $f4Package 'review/game'),'--rendering-method',$Renderer)
 if($Mode -eq 'play'){
  $f4Owns=$f4Mutex.WaitOne(0);if(-not $f4Owns){throw 'ART-07 GPU slot busy; launch later.'}
  $f4Busy=Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(blender|trellis.*|godot.*)\.exe$' -and $_.CommandLine -notmatch '--headless'}
  if($f4Busy){throw 'An existing art/game process is active; launch later.'}
 }else{$f4Args=@('--headless','--fixed-fps','60')+$f4Args}
 if($Mode -eq 'import'){$f4Args+=@('--editor','--import')}else{
  $f4Flag=if($Mode -eq 'exhausted'){'restore-exhausted'}else{$Mode}
  $f4Args+=@('res://f4/review.tscn','--',('--'+$f4Flag))
 }
 $f4Logs=Join-Path $f4Package 'launch-logs';New-Item -ItemType Directory -Force -Path $f4Logs | Out-Null
 $f4Log=Join-Path $f4Logs ($Mode+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss-ffff'))
 $f4Window=if($Show){'Normal'}else{'Hidden'}
 $f4Start=Get-Date
 $f4Child=Start-Process -FilePath $Godot -ArgumentList @($f4Args|ForEach-Object{'"'+$_+'"'}) -WindowStyle $f4Window -PassThru -RedirectStandardOutput ($f4Log+'.out') -RedirectStandardError ($f4Log+'.err')
 $f4Child.WaitForExit()
 @{arguments=$f4Args;exit_code=$f4Child.ExitCode;seconds=((Get-Date)-$f4Start).TotalSeconds;appdata=$env:APPDATA} | ConvertTo-Json | Set-Content -LiteralPath ($f4Log+'.json')
 Get-Content -LiteralPath ($f4Log+'.out') | Select-Object -Last 4
 if($f4Child.ExitCode -ne 0 -or (Select-String -LiteralPath ($f4Log+'.err') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)){throw ('F4 launch failed; inspect '+$f4Log)}
}finally{$env:APPDATA=$f4Prior;if($f4Owns){$f4Mutex.ReleaseMutex()};$f4Mutex.Dispose()}
