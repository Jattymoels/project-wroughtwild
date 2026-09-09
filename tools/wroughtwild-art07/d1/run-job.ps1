param([Parameter(Mandatory)][string]$Job)
$ErrorActionPreference='Stop'
$d1Job=Get-Content -LiteralPath $Job -Raw | ConvertFrom-Json
$d1Output=[IO.Path]::GetFullPath($d1Job.output)
if (Test-Path -LiteralPath $d1Output) { throw 'Use a fresh job log directory.' }
New-Item -ItemType Directory -Path $d1Output | Out-Null
$d1Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d1Owns=$false
$d1App=$env:APPDATA
$d1Blender=$env:BLENDER_USER_RESOURCES
$d1Started=Get-Date
try {
    if ($d1Job.gpu) {
        $d1Owns=$d1Mutex.WaitOne(0)
        if (-not $d1Owns) { throw 'ART-07 GPU slot busy; retry later with fresh logs.' }
        $d1Other=Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }
        if ($d1Other) { $d1Other | Select-Object Id,ProcessName | ConvertTo-Json | Set-Content "$d1Output/busy.json"; throw 'Existing art/playtest process; do not interrupt it.' }
        & nvidia-smi --query-gpu=name,driver_version,utilization.gpu,memory.used --format=csv | Set-Content "$d1Output/gpu.csv"
    }
    $env:APPDATA=if ($d1Job.appdata) { [IO.Path]::GetFullPath($d1Job.appdata) } else { Join-Path $d1Output 'appdata' }
    $env:BLENDER_USER_RESOURCES=Join-Path $d1Output 'blender-user'
    New-Item -ItemType Directory -Force $env:APPDATA,$env:BLENDER_USER_RESOURCES | Out-Null
    # Paths are resolved local JSON data, passed as quoted process arguments, never shell code.
    $d1Args=($d1Job.arguments | ForEach-Object { if ($_ -match '"') { throw 'Embedded quote in argument' }; '"'+$_+'"' }) -join ' '
    $d1Process=Start-Process -FilePath $d1Job.executable -ArgumentList $d1Args -WorkingDirectory $d1Job.cwd -WindowStyle Hidden -RedirectStandardOutput "$d1Output/stdout.log" -RedirectStandardError "$d1Output/stderr.log" -PassThru
    $d1Handle=$d1Process.Handle
    while (-not $d1Process.WaitForExit(1000)) {
        if (((Get-Date)-$d1Started).TotalSeconds -gt $d1Job.timeout_seconds) {
            Stop-Process -Id $d1Process.Id -Force
            throw 'This D1 process timed out; inspect its logs.'
        }
    }
    $d1Result=@{pid=$d1Process.Id;start=$d1Started.ToString('o');end=(Get-Date).ToString('o');seconds=((Get-Date)-$d1Started).TotalSeconds;exit_code=$d1Process.ExitCode;job=$d1Job}
    $d1Result | ConvertTo-Json -Depth 10 | Set-Content "$d1Output/process.json"
    $d1Text=(Get-Content "$d1Output/stdout.log","$d1Output/stderr.log") -join "`n"
    $d1Text -split "`n" | Select-String 'D1_|checks|failures|SCRIPT ERROR|ERROR:|Traceback|Error:' | ForEach-Object { $_.Line }
    if ($d1Process.ExitCode -ne 0 -or $d1Text -match '(?m)^(SCRIPT ERROR|ERROR:|Traceback|FAIL)') { throw "D1 job failed; $d1Output" }
    Write-Output "D1_JOB_OK $($d1Result.seconds)s $d1Output"
} finally {
    $env:APPDATA=$d1App; $env:BLENDER_USER_RESOURCES=$d1Blender
    if ($d1Owns) { $d1Mutex.ReleaseMutex() }
    $d1Mutex.Dispose()
}
