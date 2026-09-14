# Own one finite R3 batch; every engine job still runs through the unchanged R runner.
# The same reentrant mutex stays owned between jobs, preventing the observed gap race.
param([Parameter(Mandatory)][string]$Spec,[string]$From='',[string[]]$Then=@())
$ErrorActionPreference='Stop'
$repairRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
if ((& git -C $repairRoot branch --show-current).Trim() -ne 'codex/art07-r3') { throw 'R3 branch required.' }
$repairBuild=[IO.Path]::GetFullPath((Join-Path $repairRoot 'build/art07-repairs/r3'))
$repairSpec=[IO.Path]::GetFullPath((Join-Path (Get-Location) $Spec))
if (-not $repairSpec.StartsWith($repairBuild+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Spec outside R3.' }
$repairLog=Join-Path (Split-Path $repairSpec) ('orchestration-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'.json')
$repairMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$repairOwns=$false
$repairResult=@{spec=$repairSpec;from=$From;then=$Then;start=[DateTime]::UtcNow.ToString('o');processes_before=@();status='not_launched';failure='';shared_runner='tools/wroughtwild-art07-repairs/run.ps1';wrapper_pid=$PID}
try {
 $repairWaitStarted=[DateTime]::UtcNow
 Write-Output 'R3_WAITING_GPU continuous finite wait, up to 900s; no engine launched'
 # The outer tool yields while this one wait is pending, so status remains readable.
 # Avoid repeatedly abandoning the wait between other workers' finite batches.
 $repairOwns=$repairMutex.WaitOne(900000)
 Write-Output ("R3_GPU_WAIT_SECONDS "+[math]::Round(([DateTime]::UtcNow-$repairWaitStarted).TotalSeconds))
 if (-not $repairOwns) { $repairResult.failure='Shared GPU mutex busy; deferred without launching.'; Write-Output 'R3_DEFERRED_MUTEX'; return }
 $repairProcesses=@(Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(blender|godot.*|trellis.*|cc1plus|g\+\+|cmake|mingw32-make|cl|ninja)\.exe$'} | Select-Object ProcessId,ParentProcessId,Name,CommandLine)
 $repairResult.processes_before=$repairProcesses
 if ($repairProcesses.Count) { $repairResult.failure='Existing art/game/compiler process; deferred without launching.'; Write-Output 'R3_DEFERRED_PROCESS'; return }
 $repairResult.status='running'
 & (Join-Path $repairRoot 'tools/wroughtwild-art07-repairs/run.ps1') -Spec $repairSpec -From $From
 foreach($repairNext in $Then) {
  $repairNextPath=[IO.Path]::GetFullPath((Join-Path (Get-Location) $repairNext))
  if (-not $repairNextPath.StartsWith($repairBuild+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Next spec outside R3.' }
  & (Join-Path $repairRoot 'tools/wroughtwild-art07-repairs/run.ps1') -Spec $repairNextPath
 }
 $repairResult.status='completed'
} catch { $repairResult.status='failed';$repairResult.failure=$_.Exception.Message;throw }
finally {
 $repairResult.end=[DateTime]::UtcNow.ToString('o')
 $repairResult | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $repairLog -Encoding utf8
 if ($repairOwns) { $repairMutex.ReleaseMutex() }
 $repairMutex.Dispose()
}
