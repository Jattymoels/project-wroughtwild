param([ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',
 [ValidateSet('import','interactive','capture','checks','restore-cycle','restart','restart-depleted')][string]$Mode='interactive',
 [switch]$Show,[string]$Log)
# Copy the sealed package first. This launcher belongs at the copied root.
$ErrorActionPreference='Stop'
$f1Package=[IO.Path]::GetFullPath($PSScriptRoot)
if(-not (Test-Path -LiteralPath (Join-Path $f1Package 'preimport-verification.json'))){throw 'Use the verified fresh-copy root, not the recipe directory.'}
$f1Project=Join-Path $f1Package 'review/game'
$f1Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$f1LogRoot=Join-Path $f1Package 'logs'
New-Item -ItemType Directory -Path $f1LogRoot -Force | Out-Null
if(-not $Log){$Log=Join-Path $f1LogRoot ($Mode+'-'+$Renderer+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')}
$Log=[IO.Path]::GetFullPath($Log)
if(-not $Log.StartsWith($f1Package+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Launcher logs belong inside the disposable copy.'}
if(Test-Path -LiteralPath $Log){throw 'Use a fresh launcher log.'}
$f1Prior=$env:APPDATA
$f1Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$f1Owns=$false
try {
 $env:APPDATA=Join-Path $f1Package 'user'
 $f1Args=@('--path',$f1Project,'--audio-driver','Dummy')
 if($Mode -in @('interactive','capture')){
  $f1Owns=$f1Mutex.WaitOne(0)
  if(-not $f1Owns){throw 'ART-07 GPU slot busy; launch later.'}
  $f1Busy=Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(blender|trellis.*|godot.*)\.exe$' -and $_.CommandLine -notmatch '--headless'}
  if($f1Busy){throw 'An existing art/game process is running; launch later.'}
  $f1Args+=@('--rendering-method',$Renderer)
  if($Mode -eq 'capture'){$f1Args+=@('--fixed-fps','30')}
 } else {$f1Args+=@('--headless','--fixed-fps','60')}
 if($Mode -eq 'import'){$f1Args+=@('--editor','--import')}else{$f1Args+=@('--',('--'+$Mode))}
 $f1Window=if($Show){'Normal'}else{'Hidden'}
 $f1Start=Get-Date
 $f1Process=Start-Process -FilePath $f1Godot -ArgumentList @($f1Args|ForEach-Object{'"'+$_+'"'}) -WindowStyle $f1Window -PassThru -RedirectStandardOutput ($Log+'.stdout') -RedirectStandardError ($Log+'.stderr')
 $f1Process.WaitForExit()
 @(Get-Content -LiteralPath ($Log+'.stdout');Get-Content -LiteralPath ($Log+'.stderr')) | Set-Content -Encoding utf8 $Log
 @{program=$f1Godot;arguments=$f1Args;exit_code=$f1Process.ExitCode;seconds=((Get-Date)-$f1Start).TotalSeconds;pid=$f1Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($Log+'.json')
 if($f1Process.ExitCode -ne 0){throw ('F1 review exit '+$f1Process.ExitCode)}
 if(Select-String -LiteralPath $Log -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet){throw ('F1 logged an engine error: '+$Log)}
 Get-Content -LiteralPath $Log | Select-Object -Last 5
}finally{
 $env:APPDATA=$f1Prior
 if($f1Owns){$f1Mutex.ReleaseMutex()}
 $f1Mutex.Dispose()
}
