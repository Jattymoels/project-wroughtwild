param([ValidateSet('Import','State','Capture')][string]$Mode='State')
$ErrorActionPreference='Stop'
$mob03Root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$mob03Fixture=Join-Path $mob03Root 'build/mob03/fixture'
$mob03Evidence=Join-Path $mob03Root 'build/mob03/evidence'
$mob03Engine='C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe'
$mob03AppData=$env:APPDATA
$mob03LocalData=$env:LOCALAPPDATA
$mob03Mutex=$null
$mob03Locked=$false
$mob03Process=$null
try {
 if ($Mode -eq 'Capture') {
  $mob03Mutex=[Threading.Mutex]::new($false,'Local\WroughtwildArtRender')
  try { $mob03Locked=$mob03Mutex.WaitOne(0) }
  catch [Threading.AbandonedMutexException] {
   $mob03Locked=$true
   $mob03Orphans=@(Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(blender|Godot.*)\.exe$' -and $_.CommandLine -notmatch '--headless' -and $_.CommandLine -match 'render|capture'})
   if ($mob03Orphans.Count) {throw 'Abandoned render lock with a possible live renderer; inspect before retrying.'}
  }
  if (!$mob03Locked) {Write-Output 'MOB03_RENDER_BUSY';exit 75}
 }
 $env:APPDATA=Join-Path $mob03Fixture 'user'
 $env:LOCALAPPDATA=Join-Path $mob03Fixture 'local-user'
 New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 $mob03Args=@('--path',('"'+$mob03Fixture+'"'))
 if ($Mode -eq 'Import') {$mob03Args+=@('--headless','--editor','--import','--quit')}
 if ($Mode -eq 'State') {$mob03Args+=@('--headless')}
 if ($Mode -eq 'Capture') {$mob03Args+=@('--rendering-method','forward_plus','--position','5000,5000','--','--capture')}
 $mob03Log=Join-Path $mob03Evidence ($Mode.ToLowerInvariant()+'.log')
 $mob03Err=$mob03Log+'.err'
 $mob03Process=Start-Process -FilePath $mob03Engine -ArgumentList $mob03Args -WindowStyle Hidden -PassThru -RedirectStandardOutput $mob03Log -RedirectStandardError $mob03Err
 $mob03Deadline=[DateTime]::UtcNow.AddMinutes(3)
 while (!$mob03Process.WaitForExit(400)) {
  $mob03Diagnostics=(Get-Content -Raw -LiteralPath $mob03Err -ErrorAction SilentlyContinue)
  if ($mob03Diagnostics -match 'SCRIPT ERROR|SHADER ERROR|Parse Error' -or [DateTime]::UtcNow -gt $mob03Deadline) {
   Stop-Process -Id $mob03Process.Id
   throw "MOB03 $Mode stopped after error/timeout. Read $mob03Log and $mob03Err."
  }
 }
 $mob03Process.Refresh()
 $mob03Diagnostics=(Get-Content -Raw -LiteralPath $mob03Log)+(Get-Content -Raw -LiteralPath $mob03Err)
 if ($mob03Process.ExitCode -ne 0 -or $mob03Diagnostics -match 'SCRIPT ERROR|SHADER ERROR|Error importing|Failed loading resource') {throw "MOB03 $Mode failed. Read $mob03Log and $mob03Err."}
 if ($Mode -ne 'Import' -and $mob03Diagnostics -notmatch ('MOB03_'+$Mode.ToUpperInvariant()+'_OK')) {throw "MOB03 $Mode lacks a completion marker."}
 Write-Output "MOB03 $Mode completed; owned PID $($mob03Process.Id) exited."
 Get-Content -LiteralPath $mob03Log -Tail 4
} finally {
 if ($mob03Process -and !$mob03Process.HasExited) {Stop-Process -Id $mob03Process.Id}
 if ($mob03Locked) {$mob03Mutex.ReleaseMutex()}
 if ($mob03Mutex) {$mob03Mutex.Dispose()}
 $env:APPDATA=$mob03AppData
 $env:LOCALAPPDATA=$mob03LocalData
}
