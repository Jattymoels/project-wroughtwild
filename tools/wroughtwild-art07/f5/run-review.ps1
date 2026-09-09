param(
 [Parameter(Mandatory)][string]$Project,
 [ValidateSet('import','check','restart','capture','benchmark','open')][string]$Mode='check',
 [switch]$Compatibility,[string]$Tag='v01'
)
$ErrorActionPreference='Stop'
$artProject=(Resolve-Path -LiteralPath $Project).Path
$artRun=Split-Path $artProject
$artLogs=Join-Path $artRun 'logs'
New-Item -ItemType Directory -Path $artLogs -Force | Out-Null
$artName="$Mode-$($Compatibility.IsPresent)-$Tag"
$artLog=Join-Path $artLogs "$artName.log"
$artError=Join-Path $artLogs "$artName-errors.log"
if(Test-Path -LiteralPath $artLog){throw 'Use a fresh log tag.'}
$artOldAppdata=$env:APPDATA
$artMutex=$null;$artOwnsGpu=$false
try{
 # Short private path avoids Windows MAX_PATH failures in Godot's long shader cache names.
 $artRoot=(Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
 $artHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($artProject))).Substring(0,8).ToLowerInvariant()
 $env:APPDATA=Join-Path $artRoot "build/art07/f5/u/$artHash"
 $artPrevious=Join-Path $artRun 'review-appdata'
 New-Item -ItemType Directory -Path (Split-Path $env:APPDATA) -Force | Out-Null
 if(-not (Test-Path -LiteralPath $env:APPDATA) -and (Test-Path -LiteralPath $artPrevious)){Copy-Item -LiteralPath $artPrevious -Destination $env:APPDATA -Recurse}
 New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
 $artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
 $artArguments=@('--path',$artProject,'--resolution','1600x1000','--audio-driver','Dummy')
 if($Mode -eq 'import'){$artArguments+=@('--headless','--editor','--import','--quit')}
 elseif($Mode -in @('check','restart')){
  $artArguments+=@('--headless','--script','res://check_native.gd','--quit-after','5000')
  if($Mode -eq 'restart'){$artArguments+=@('--','--restart')}
 }elseif($Mode -in @('capture','benchmark')){$artArguments+=@('--quit-after','18000','--',"--$Mode")}
 if($Compatibility){
  $artArguments=@('--rendering-method','gl_compatibility')+$artArguments
  if($Mode -in @('capture','benchmark')){$artArguments+='--compatibility-proof'}
 }
 if($Mode -in @('capture','benchmark','open')){
  $artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
  $artOwnsGpu=$artMutex.WaitOne(0)
  if(-not $artOwnsGpu){throw 'ART-07 GPU slot busy; retry later with CPU work in between.'}
  $artOthers=@(Get-Process | Where-Object {$_.ProcessName -match 'godot|blender|trellis'})
  if($artOthers.Count){throw "Existing renderer/generator process present: $($artOthers.Id -join ','). Preserve it."}
  & nvidia-smi | Set-Content (Join-Path $artLogs "$artName-gpu-before.txt")
 }
 $artStart=[DateTime]::UtcNow
 $artProcess=Start-Process -FilePath $artGodot -ArgumentList $artArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $artLog -RedirectStandardError $artError
 $artTimer=[Diagnostics.Stopwatch]::StartNew()
 while(-not $artProcess.WaitForExit(1000)){
  if($artTimer.Elapsed.TotalSeconds -gt 600 -and $Mode -ne 'open'){Stop-Process -Id $artProcess.Id;throw 'Own process timed out.'}
  $artText=Get-Content -LiteralPath $artError -Raw
  if($artText -match 'SCRIPT ERROR:|Parse Error:|Assertion failed'){Stop-Process -Id $artProcess.Id;throw "Own process failed; inspect $artError"}
 }
 $artProcess.Refresh()
 $artExit=$artProcess.ExitCode
 @{pid=$artProcess.Id;project=$artProject;mode=$Mode;arguments=$artArguments;started_utc=$artStart.ToString('o');seconds=$artTimer.Elapsed.TotalSeconds;exit_code=$artExit;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $artLogs "$artName-process.json")
 $artErrors=Get-Content -LiteralPath $artError -Raw
 $artErrors=$artErrors -replace 'ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates \(platform/windows/os_windows.cpp:2468\)\r?\n',''
 if($artExit -ne 0 -or $artErrors -match 'ERROR:|SCRIPT ERROR:'){throw "Own process exited $artExit; inspect $artError"}
 Write-Output "F5_REVIEW_OK $Mode $artProject"
}finally{
 $env:APPDATA=$artOldAppdata
 if($artOwnsGpu){$artMutex.ReleaseMutex()}
 if($null -ne $artMutex){$artMutex.Dispose()}
}
