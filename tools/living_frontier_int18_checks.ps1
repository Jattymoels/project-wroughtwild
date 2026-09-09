param([ValidateSet('baseline','crossfire','relentless_boss')][string]$Case='baseline', [ValidateSet('rough','sound','ember','control')][string]$Kit='rough', [switch]$Restart, [switch]$Preentry, [switch]$Visuals)
$int18Options=@{}+$PSBoundParameters
. "$PSScriptRoot/living_frontier_checks.ps1"
$lfLogs=Join-Path $lfRoot 'build/int18-a'
New-Item -ItemType Directory -Force $lfLogs | Out-Null
$env:APPDATA=Join-Path $lfLogs 'appdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
$int18Args=@('--headless','--fixed-fps','60')
if ($int18Options.Visuals) { $int18Args=@('--position','-9999,-9999','--resolution','1280x720','--audio-driver','Dummy','--fixed-fps','60') }
$int18Args+=@('res://tests/laboratory_pressure_runs.tscn','--',('--case='+$Case),('--kit='+$Kit))
$int18Name=if ($Kit -ne 'rough') { $Kit+'-'+$Case } else { $Case }
if ($int18Options.Restart) { $int18Args+='--restart'; $int18Name+='-restart' }
if ($int18Options.Preentry) { $int18Args+='--preentry'; $int18Name+='-preentry' }
if ($int18Options.Visuals) { $int18Args+='--visuals'; $int18Name+='-visuals' }
Invoke-LFEngine $int18Name $int18Args
