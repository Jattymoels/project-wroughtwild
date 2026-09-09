param([Parameter(Mandatory)][string[]]$Jobs)
$ErrorActionPreference='Stop'
$d1BatchMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d1BatchOwns=$false
try {
    $d1BatchOwns=$d1BatchMutex.WaitOne(0)
    if (-not $d1BatchOwns) { throw 'ART-07 slot busy; no batch started.' }
    $d1Other=Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }
    if ($d1Other) { throw 'Existing art/playtest process; no batch started.' }
    foreach ($d1JobPath in $Jobs) { & (Join-Path $PSScriptRoot 'run-job.ps1') -Job $d1JobPath }
} finally {
    if ($d1BatchOwns) { $d1BatchMutex.ReleaseMutex() }
    $d1BatchMutex.Dispose()
}
