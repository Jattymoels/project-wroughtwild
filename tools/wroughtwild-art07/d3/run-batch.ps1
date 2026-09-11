param([Parameter(Mandatory)][string[]]$Jobs,[ValidateRange(0,45)][int]$WaitSeconds=0)
$ErrorActionPreference='Stop'
$d3BatchMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d3BatchOwns=$false
try {
    $d3Deadline=(Get-Date).AddSeconds($WaitSeconds)
    do {
        $d3BatchOwns=$d3BatchMutex.WaitOne(0)
        if ($d3BatchOwns) {
            $d3Other=Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }
            if (-not $d3Other) { break }
            $d3BatchMutex.ReleaseMutex(); $d3BatchOwns=$false
        }
        if ((Get-Date) -ge $d3Deadline) { throw 'ART-07 slot/process busy; no batch started.' }
        Start-Sleep -Milliseconds 500
    } while (-not $d3BatchOwns)
    foreach ($d3JobPath in $Jobs) { & (Join-Path $PSScriptRoot 'run-job.ps1') -Job $d3JobPath }
} finally {
    if ($d3BatchOwns) { $d3BatchMutex.ReleaseMutex() }
    $d3BatchMutex.Dispose()
}
