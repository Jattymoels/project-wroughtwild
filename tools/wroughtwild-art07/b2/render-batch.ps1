param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Logs,[ValidateSet('Capture','Benchmark')][string]$Phase='Capture')
$ErrorActionPreference='Stop'
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
try {
 $artDeadline=(Get-Date).AddSeconds(55)
 do {
  $artOwns=$artMutex.WaitOne(0)
  if($artOwns -and (Get-Process | Where-Object {$_.ProcessName -match 'godot|blender|trellis'})){$artMutex.ReleaseMutex();$artOwns=$false}
  if(-not $artOwns){Start-Sleep -Milliseconds 1000}
 } while(-not $artOwns -and (Get-Date) -lt $artDeadline)
 if(-not $artOwns){throw 'GPU slot busy after bounded wait'}
 $artStarted=Get-Date
 $artModes=if($Phase -eq 'Capture'){@('capture','motion')}else{@('benchmark')}
 foreach($artRenderer in @('forward_plus','gl_compatibility')){
  foreach($artMode in $artModes){
   & "$PSScriptRoot/run-job.ps1" -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -Arguments @('--path',$Project,'--audio-driver','Dummy','--rendering-method',$artRenderer,'--',"--$artMode") -Log (Join-Path $Logs "$artRenderer-$artMode.log")
  }
 }
 @{gpu_mutex='Local\Wroughtwild-Art07-GPU';phase=$Phase;started=$artStarted.ToString('o');ended=(Get-Date).ToString('o');exclusive_sequence=$true;no_existing_render_process_at_start=$true} | ConvertTo-Json | Set-Content (Join-Path $Logs "$Phase-slot.json")
} finally {if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
