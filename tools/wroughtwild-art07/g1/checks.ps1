param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Output,[string]$Suite='focused',[string]$From='',[string]$Renderer='')
$ErrorActionPreference='Stop'
$g1Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe'
$g1Output=[IO.Path]::GetFullPath($Output)
New-Item -ItemType Directory -Path $g1Output -ErrorAction Stop | Out-Null
$g1Cases= switch($Suite) {
 'focused' { @(
  @{name='unit';scene='tests/run_tests.gd';extra=@()},
  @{name='placement';scene='tests/placement_transactions.tscn';extra=@()},
  @{name='placement-restart';scene='tests/placement_transactions.tscn';extra=@('--placement-restore-only')},
  @{name='local-scenery';scene='tests/placement_scenery.tscn';extra=@()},
  @{name='home';scene='tests/home_workshop_review.tscn';extra=@()},
  @{name='e3';scene='e3/review.tscn';extra=@()},
  @{name='e3-restart';scene='e3/review.tscn';extra=@('--restore')}
 ) }
 'sources' {
  foreach($g1Id in @('b1','b3','c1','c2','c3','c4','c5')) {
   @{name=$g1Id;scene="$g1Id/native_review.tscn";extra=@()}
   if($g1Id -in @('c1','c2','c3','c4','c5')) { @{name="$g1Id-partial";scene="$g1Id/native_review.tscn";extra=@('--restore-partial')} }
  }
 }
 'devices' {
  foreach($g1Id in @('f1','f2','f3')) {
   @{name=$g1Id;scene="$g1Id/review.tscn";extra=$(if($g1Id -eq 'f2'){@('--check')}else{@()})}
   @{name="$g1Id-restart";scene="$g1Id/review.tscn";extra=@('--restart')}
  }
  @{name='f4';scene='f4/review.tscn';extra=@()}
  @{name='f4-restart';scene='f4/review.tscn';extra=@('--restore')}
  @{name='f4-exhausted';scene='f4/review.tscn';extra=@('--restore-exhausted')}
 }
 'shapes' {
  foreach($g1Id in @('d1','d2','d3')) {
   @{name=$g1Id;scene="art07_$g1Id/checks.tscn";extra=@()}
   @{name="$g1Id-restart";scene="art07_$g1Id/checks.tscn";extra=@("--$g1Id-restore")}
  }
 }
 'signals' { @(
  @{name='white';scene='tests/living_frontier_flow.tscn';extra=@()},
  @{name='blue';scene='tests/living_frontier_wave2_flow.tscn';extra=@('--lf2-bootstrap')},
  @{name='green';scene='tests/living_frontier_green_flow.tscn';extra=@()},
  @{name='red';scene='tests/living_frontier_heat_flow.tscn';extra=@()},
  @{name='red-restart';scene='tests/living_frontier_heat_flow.tscn';extra=@('--heat-restore')}
 ) }
 'stations' {
  foreach($g1Id in @('e1','e2')) {
   @{name=$g1Id;scene="$g1Id/review.tscn";extra=@('--check')}
   @{name="$g1Id-restart";scene="$g1Id/review.tscn";extra=@('--restore')}
  }
 }
 default {throw 'Unknown suite'}
}
$g1Started=($From -eq '')
foreach($g1Case in $g1Cases) {
 if($g1Case.name -eq $From){$g1Started=$true}
 if(-not $g1Started){continue}
 $g1Args=@('--fixed-fps','60','--path',[IO.Path]::GetFullPath($Game))
 if($Renderer -eq '' -or $g1Case.scene.EndsWith('.gd')) {$g1Args=@('--headless')+$g1Args} else {$g1Args=@('--rendering-method',$Renderer)+$g1Args}
 if($g1Case.scene.EndsWith('.gd')) {$g1Args+=@('--script')}
 $g1Args+=@(('res://'+$g1Case.scene))
 if($g1Case.extra.Count) {$g1Args+=@('--')+$g1Case.extra}
 & "$PSScriptRoot/gpu-slot.ps1" -Program $g1Godot -JobArguments $g1Args -Log (Join-Path $g1Output ($g1Case.name+'.log'))
 Write-Output ("G1_CHECK_PASSED "+$g1Case.name)
}
