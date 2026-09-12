param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
$e1Deadline=(Get-Date).AddMinutes(20)
foreach($e1Renderer in @('forward_plus','gl_compatibility')){
 $e1Done=$false
 while(-not $e1Done){
  try{
   & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -JobArguments @('--audio-driver','Dummy','--path',$Game,'--rendering-method',$e1Renderer,'res://e1/review.tscn','--','--benchmark') -Log (Join-Path $Logs ($e1Renderer+'-benchmark.log'))
   $e1Done=$true
  }catch{
   if($_.Exception.Message -notmatch 'GPU slot busy|Existing GPU art/game process'){throw}
   if((Get-Date) -gt $e1Deadline){throw 'E1 benchmark wait expired; no other process was interrupted'}
   Write-Output ('E1 benchmark deferred; existing job retained at '+(Get-Date).ToString('o'))
   Start-Sleep -Seconds 15
  }
 }
}
