param(
    [string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
    [string]$Fixture='D:/Wroughtwild/work/mob02-ram/build/mob02/fixture',
    [string]$Output='D:/Wroughtwild/work/mob02-ram/build/mob02/evidence'
)
$ErrorActionPreference='Stop'
$ramMutex=[System.Threading.Mutex]::new($false,'Local\WroughtwildArtRender')
$ramOwnsLock=$false
$ramProcess=$null
try {
    try { $ramOwnsLock=$ramMutex.WaitOne(0) }
    catch [System.Threading.AbandonedMutexException] {
        $ramOwnsLock=$true
        $ramPossibleOrphans=Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^Godot|^blender$' }
        if ($ramPossibleOrphans) { throw 'Abandoned render mutex with an existing renderer process; inspect before capture.' }
    }
    if (-not $ramOwnsLock) { Write-Output 'MOB02_RENDER_BUSY'; exit 75 }
    New-Item -ItemType Directory -Force -Path "$Output/frames","$Output/appdata" | Out-Null
    $env:APPDATA="$Output/appdata"
    $env:MOB02_OUTPUT=$Output
    $ramProcess=Start-Process -FilePath $Godot -WindowStyle Hidden -PassThru -ArgumentList @('--path',$Fixture,'--rendering-method','forward_plus','--fixed-fps','24','--position','-16000,-16000','--','--capture') -RedirectStandardOutput "$Output/render-stdout.log" -RedirectStandardError "$Output/render-stderr.log"
    Write-Output "MOB02_RENDER_PID=$($ramProcess.Id)"
    if (-not $ramProcess.WaitForExit(180000)) {
        $ramProcess.Kill()
        $ramProcess.WaitForExit()
        throw 'Bounded capture timed out; owned renderer stopped.'
    }
    $ramProcess.Refresh()
    if ($ramProcess.ExitCode -ne 0) { throw "Capture exited $($ramProcess.ExitCode)" }
    Write-Output 'MOB02_RENDER_COMPLETE'
}
finally {
    if ($ramProcess -and -not $ramProcess.HasExited) {
        $ramProcess.Kill()
        $ramProcess.WaitForExit()
    }
    if ($ramOwnsLock) { $ramMutex.ReleaseMutex() }
    $ramMutex.Dispose()
}
