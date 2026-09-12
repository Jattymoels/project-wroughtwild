param([Parameter(Mandatory)][string]$Fresh)
$ErrorActionPreference='Stop'
$e1Fresh=[IO.Path]::GetFullPath($Fresh)
$e1Worker=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
if(-not $e1Fresh.StartsWith((Join-Path $e1Worker 'build/art07/e1')+[IO.Path]::DirectorySeparatorChar)){throw 'Fresh copy must stay in E1 build'}
$e1Game=Join-Path $e1Fresh 'review/game'
$e1LogRoot=Join-Path $e1Fresh 'verification-logs'
New-Item -ItemType Directory -Path $e1LogRoot | Out-Null
function Invoke-E1Queued {
 param([string]$Program,[string[]]$JobArguments,[string]$Log)
 $e1Deadline=(Get-Date).AddMinutes(20)
 while($true){
  try{
   & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program $Program -JobArguments $JobArguments -Log $Log
   return
  }catch{
   if($_.Exception.Message -notmatch 'GPU slot busy|Existing GPU art/game process'){throw}
   if((Get-Date) -gt $e1Deadline){throw 'E1 fresh verification wait expired'}
   Write-Output 'E1 verification deferred; existing GPU process retained'
   Start-Sleep -Seconds 15
  }
 }
}
$e1Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$e1Blender='C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
Invoke-E1Queued -Program $e1Godot -JobArguments @('--headless','--path',$e1Game,'--editor','--import') -Log (Join-Path $e1LogRoot 'import.log')
foreach($e1Mode in @('check','restore')){
 Invoke-E1Queued -Program $e1Godot -JobArguments @('--headless','--audio-driver','Dummy','--path',$e1Game,'res://e1/review.tscn','--',('--'+$e1Mode)) -Log (Join-Path $e1LogRoot ($e1Mode+'.log'))
}
Invoke-E1Queued -Program $e1Blender -JobArguments @('--background','--threads','8','--python-exit-code','1','--python',(Join-Path $e1Fresh 'recipes/blender_stations.py'),'--','--reopen',(Join-Path $e1Fresh 'source/e1_stations.blend'),(Join-Path $e1Fresh 'verified-blender')) -Log (Join-Path $e1LogRoot 'blender.log')
foreach($e1Renderer in @('forward_plus','gl_compatibility')){
 foreach($e1Mode in @('capture','restore')){
  $e1Args=@('--fixed-fps','60','--audio-driver','Dummy','--path',$e1Game,'--rendering-method',$e1Renderer,'res://e1/review.tscn','--',('--'+$e1Mode))
  if($e1Mode -eq 'restore'){$e1Args+=@('--capture')}
  Invoke-E1Queued -Program $e1Godot -JobArguments $e1Args -Log (Join-Path $e1LogRoot ($e1Renderer+'-'+$e1Mode+'.log'))
 }
}
