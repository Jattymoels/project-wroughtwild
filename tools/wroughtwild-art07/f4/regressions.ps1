param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Logs,[string]$From='placement')
$ErrorActionPreference='Stop'
$f4Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f4'))
$f4Game=[IO.Path]::GetFullPath($Game)
$f4Logs=[IO.Path]::GetFullPath($Logs)
foreach($f4Path in @($f4Game,$f4Logs)) {if(-not $f4Path.StartsWith($f4Root+[IO.Path]::DirectorySeparatorChar)){throw 'Checks must stay in F4 build'}}
if(Test-Path -LiteralPath $f4Logs){throw 'Fresh logs required'}
New-Item -ItemType Directory -Path $f4Logs | Out-Null
$f4Jobs=@(
 @{name='placement';scene='placement_transactions';extra=@()},
 @{name='placement-restart';scene='placement_transactions';extra=@('--placement-restore-only')},
 @{name='stations';scene='home_station_placement';extra=@()},
 @{name='clearance';scene='home_station_clearance';extra=@()},
 @{name='manual-feedback';scene='workshop_feedback';extra=@()},
 @{name='feeder-body';scene='pressure_feeder_presentation';extra=@()},
 @{name='feeder-controls';scene='feeder_controls';extra=@()},
 @{name='feeder-visuals';scene='feeder_visuals';extra=@()},
 @{name='pressure-v5';scene='pressure_workshop';extra=@('--pressure-profile=frontier_v5')},
 @{name='pressure-v6';scene='pressure_workshop';extra=@('--pressure-profile=frontier_v6')},
 @{name='lf-bootstrap';scene='living_frontier_flow';extra=@()},
 @{name='lf-blue';scene='living_frontier_wave2_flow';extra=@('--lf2-bootstrap')},
 @{name='lf-green';scene='living_frontier_green_flow';extra=@()},
 @{name='lf-heat';scene='living_frontier_heat_flow';extra=@()},
 @{name='lf-heat-restart';scene='living_frontier_heat_flow';extra=@('--heat-restore')},
 @{name='lf-workshop';scene='living_frontier_workshop_flow';extra=@()},
 @{name='lf-workshop-restart';scene='living_frontier_workshop_flow';extra=@('--workshop-restore')}
)
$f4Started=$false
foreach($f4Job in $f4Jobs) {
 if($f4Job.name -eq $From){$f4Started=$true}
 if(-not $f4Started){continue}
 $f4Args=@('--headless','--audio-driver','Dummy','--path',$f4Game,('res://tests/'+$f4Job.scene+'.tscn'))
 # Audio expires on real time. Fixed-fps headless races its mixer and is not
 # a valid completion-audio lifetime test. Keep the original assertions.
 if($f4Job.name -ne 'manual-feedback'){$f4Args=@('--fixed-fps','60')+$f4Args}
 if($f4Job.extra.Count){$f4Args+=@('--')+$f4Job.extra}
 & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments $f4Args -Log (Join-Path $f4Logs ($f4Job.name+'.log'))
 Get-Content (Join-Path $f4Logs ($f4Job.name+'.log')) | Select-Object -Last 4
}
