param([Parameter(Mandatory)][string[]]$Jobs,[ValidateRange(0,30)][int]$WaitSeconds=0)
$ErrorActionPreference='Stop'
$d2BatchMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d2BatchOwns=$false
try {
    $d2BatchOwns=$d2BatchMutex.WaitOne($WaitSeconds*1000)
    if (-not $d2BatchOwns) { throw 'ART-07 slot busy; no batch started.' }
    $d2Other=Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }
    if ($d2Other) {
        $d2Allowed=$true
        foreach ($d2JobPath in $Jobs) { $d2Spec=Get-Content -Raw -LiteralPath $d2JobPath | ConvertFrom-Json; if (-not $d2Spec.allow_headless_peers -or $d2Spec.arguments -contains '--benchmark') { $d2Allowed=$false } }
        $d2Peers=@(Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -in $d2Other.Id })
        if ($d2Peers.Count -ne @($d2Other).Count) { $d2Allowed=$false }
        foreach ($d2Peer in $d2Peers) { if ($d2Peer.Name -notmatch '(?i)godot' -or $d2Peer.CommandLine -notmatch '(?:^|\s|\")--headless(?:\"|\s|$)') { $d2Allowed=$false } }
        if (-not $d2Allowed) { throw 'Existing art/playtest process; no batch started.' }
    }
    foreach ($d2JobPath in $Jobs) { & (Join-Path $PSScriptRoot 'run-job.ps1') -Job $d2JobPath }
} finally {
    if ($d2BatchOwns) { $d2BatchMutex.ReleaseMutex() }
    $d2BatchMutex.Dispose()
}
