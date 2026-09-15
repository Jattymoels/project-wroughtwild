param([string]$Scene='res://tests/mob01_porcupine.tscn',[string]$Log='actors',[switch]$Capture)
$ErrorActionPreference='Stop'
$mobRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$env:APPDATA="$mobRoot/build/mob01/appdata"
$env:LOCALAPPDATA="$mobRoot/build/mob01/localappdata"
$env:TEMP="$mobRoot/build/mob01/temp"
$mutex=$null
$held=$false
$testExit=1
$madeOverride=$false
New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
try {
 $arguments=@('--path',"$mobRoot/game",'--audio-driver','Dummy',$Scene)
 if($Capture) {
  $mutex=[System.Threading.Mutex]::new($false,'Local\WroughtwildArtRender')
  try {$held=$mutex.WaitOne(0)} catch [System.Threading.AbandonedMutexException] {$held=$true}
  if(-not $held) {Write-Output 'RENDER_BUSY';exit 2}
  if(Test-Path -LiteralPath "$mobRoot/game/override.cfg") {throw 'Existing override must be preserved'}
  "[display]`nwindow/size/no_focus=true`nwindow/size/viewport_width=1024`nwindow/size/viewport_height=768" | Set-Content -LiteralPath "$mobRoot/game/override.cfg"
  $madeOverride=$true
  $arguments+=@('--rendering-method','forward_plus','--fixed-fps','60','--','--r8-no-mouse-capture','--mob01-capture')
 } else {$arguments+=@('--headless','--','--r8-no-mouse-capture')}
 $process=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput "$mobRoot/build/mob01/$Log.out.log" -RedirectStandardError "$mobRoot/build/mob01/$Log.err.log"
 if(-not $process.WaitForExit(90000)) {$process.Kill($true); $process.WaitForExit(); throw 'Owned test timed out and its process tree was stopped'}
 $testExit=$process.ExitCode
 Write-Output "EXIT=$testExit"
 Get-Content -LiteralPath "$mobRoot/build/mob01/$Log.out.log" -Tail 8
 Get-Content -LiteralPath "$mobRoot/build/mob01/$Log.err.log" -Tail 24
} finally {
 if($held) {
  if($madeOverride -and (Test-Path -LiteralPath "$mobRoot/game/override.cfg")) {Remove-Item -LiteralPath "$mobRoot/game/override.cfg"}
  $mutex.ReleaseMutex()
 }
 if($null -ne $mutex) {$mutex.Dispose()}
}

exit $testExit
