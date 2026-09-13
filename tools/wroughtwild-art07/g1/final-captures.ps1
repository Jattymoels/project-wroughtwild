param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$g1Game=[IO.Path]::GetFullPath($Game)
$g1Output=[IO.Path]::GetFullPath($Output)
New-Item -ItemType Directory -Path $g1Output -ErrorAction Stop | Out-Null
foreach($g1Renderer in @('forward_plus','gl_compatibility')) {
 foreach($g1Case in @(@{id='c2';scene='c2/native_review.tscn';flags=@()},@{id='f1';scene='f1/review.tscn';flags=@('--capture')},@{id='f2';scene='f2/review.tscn';flags=@('--capture')},@{id='f3';scene='f3/review.tscn';flags=@('--capture')})) {
  $g1Args=@('--rendering-method',$g1Renderer,'--path',$g1Game,('res://'+$g1Case.scene))
  if($g1Case.flags.Count){$g1Args+=@('--')+$g1Case.flags}
  & "$PSScriptRoot/gpu-slot.ps1" -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments $g1Args -Log (Join-Path $g1Output ($g1Case.id+'-'+$g1Renderer+'.log'))
 }
 foreach($g1Mode in @('feeder','feeder-restore','feeder-exhausted','catalogue')) {
  & "$PSScriptRoot/render.ps1" -Game $g1Game -Output (Join-Path $g1Output ($g1Mode+'-'+$g1Renderer+'.log')) -Renderer $g1Renderer -Mode $g1Mode
 }
 & "$PSScriptRoot/render.ps1" -Game $g1Game -Output (Join-Path $g1Output ('baseline-'+$g1Renderer+'.log')) -Renderer $g1Renderer -Mode views -Baseline
}
