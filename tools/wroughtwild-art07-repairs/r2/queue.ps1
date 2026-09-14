# Bounded queue for this task's supplied specs. The shared runner remains authoritative.
param([Parameter(Mandatory)][string[]]$Specs)
$ErrorActionPreference='Stop'
$repairRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$repairSlot=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$repairOwns=$false
try {
 Write-Output 'R2_WAITING_FOR_EXISTING_GPU_MUTEX'
 $repairOwns=$repairSlot.WaitOne(600000)
 if(-not $repairOwns){Write-Output 'R2_DEFERRED_GPU_SLOT_BUSY';exit 2}
 Write-Output 'R2_GPU_MUTEX_ACQUIRED'
 foreach($repairSpec in $Specs){& (Join-Path $repairRoot 'tools/wroughtwild-art07-repairs/run.ps1') -Spec $repairSpec}
} finally {
 if($repairOwns){$repairSlot.ReleaseMutex()}
 $repairSlot.Dispose()
}
