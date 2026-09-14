# Queue in at most six 45-second waits, then call the unchanged shared runner.
# Reentrant ownership on this same PowerShell thread closes the preflight race.
# The shared runner still performs every process/path check and records each job.
param([Parameter(Mandatory)][string]$Spec, [string]$From='')
$ErrorActionPreference='Stop'
$r6QueueMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$r6QueueHeld=$false
try {
    for($r6Wait=0;$r6Wait -lt 6 -and -not $r6QueueHeld;$r6Wait++) {
        $r6QueueHeld=$r6QueueMutex.WaitOne(45000)
        if(-not $r6QueueHeld){Write-Output 'R6_QUEUE waiting for the existing GPU owner; no process launched.'}
    }
    if(-not $r6QueueHeld){Write-Output 'R6_DEFERRED shared GPU remained busy; no process launched.';return}
    & (Join-Path $PSScriptRoot '../run.ps1') -Spec $Spec -From $From
} finally {
    if($r6QueueHeld){$r6QueueMutex.ReleaseMutex()}
    $r6QueueMutex.Dispose()
}
