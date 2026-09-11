param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Logs,[string]$From='placement')
$ErrorActionPreference='Stop'
$e2Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/e2'))
$e2Game=[IO.Path]::GetFullPath($Game)
$e2Logs=[IO.Path]::GetFullPath($Logs)
foreach($e2Path in @($e2Game,$e2Logs)) {if(-not $e2Path.StartsWith($e2Root+[IO.Path]::DirectorySeparatorChar)){throw 'Checks must stay in E2 build'}}
if(Test-Path -LiteralPath $e2Logs){throw 'Fresh logs required'}
New-Item -ItemType Directory -Path $e2Logs | Out-Null
$e2Jobs=@(
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
$e2Started=$false
foreach($e2Job in $e2Jobs) {
 if($e2Job.name -eq $From){$e2Started=$true}
 if(-not $e2Started){continue}
 $e2Args=@('--headless','--audio-driver','Dummy','--path',$e2Game,('res://tests/'+$e2Job.scene+'.tscn'))
 # Audio expires on real time. Fixed-fps headless races its mixer and is not
 # a valid completion-audio lifetime test. Keep the original assertions.
 if($e2Job.name -ne 'manual-feedback'){$e2Args=@('--fixed-fps','60')+$e2Args}
 if($e2Job.extra.Count){$e2Args+=@('--')+$e2Job.extra}
 & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' -JobArguments $e2Args -Log (Join-Path $e2Logs ($e2Job.name+'.log'))
 Get-Content (Join-Path $e2Logs ($e2Job.name+'.log')) | Select-Object -Last 4
}
