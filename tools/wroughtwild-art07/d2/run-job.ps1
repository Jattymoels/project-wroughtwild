param([Parameter(Mandatory)][string]$Job)
$ErrorActionPreference='Stop'
$d2Job=Get-Content -LiteralPath $Job -Raw | ConvertFrom-Json
$d2Output=[IO.Path]::GetFullPath($d2Job.output)
if (Test-Path -LiteralPath $d2Output) { throw 'Use a fresh job log directory.' }
New-Item -ItemType Directory -Path $d2Output | Out-Null
$d2Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d2Owns=$false
$d2App=$env:APPDATA
$d2Blender=$env:BLENDER_USER_RESOURCES
$d2Started=Get-Date
try {
    if ($d2Job.gpu) {
        $d2Owns=$d2Mutex.WaitOne(0)
        if (-not $d2Owns) { throw 'ART-07 GPU slot busy; retry later with fresh logs.' }
        $d2Other=Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }
        if ($d2Other) {
            $d2Peers=@(Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -in $d2Other.Id })
            $d2Peers | Select-Object ProcessId,Name,CommandLine | ConvertTo-Json | Set-Content "$d2Output/peer-processes.json"
            $d2Allowed=$d2Job.allow_headless_peers -and ($d2Job.arguments -notcontains '--benchmark') -and $d2Peers.Count -eq @($d2Other).Count
            foreach ($d2Peer in $d2Peers) { if ($d2Peer.Name -notmatch '(?i)godot' -or $d2Peer.CommandLine -notmatch '(?:^|\s|\")--headless(?:\"|\s|$)') { $d2Allowed=$false } }
            if (-not $d2Allowed) { throw 'Existing art/playtest process; do not interrupt it.' }
        }
        & nvidia-smi --query-gpu=name,driver_version,utilization.gpu,memory.used --format=csv | Set-Content "$d2Output/gpu.csv"
        if ($d2Job.arguments -contains '--benchmark') {
            $d2Compilers=Get-Process | Where-Object { $_.ProcessName -match 'cc1plus|g\+\+|cmake|ninja' }
            if ($d2Compilers) { throw 'Compiler/build work active; benchmark deferred.' }
        }
    }
    $env:APPDATA=if ($d2Job.appdata) { [IO.Path]::GetFullPath($d2Job.appdata) } else { Join-Path $d2Output 'appdata' }
    $env:BLENDER_USER_RESOURCES=Join-Path $d2Output 'blender-user'
    New-Item -ItemType Directory -Force $env:APPDATA,$env:BLENDER_USER_RESOURCES | Out-Null
    # Paths are resolved local JSON data, passed as quoted process arguments, never shell code.
    $d2Args=($d2Job.arguments | ForEach-Object { if ($_ -match '"') { throw 'Embedded quote in argument' }; '"'+$_+'"' }) -join ' '
    $d2Process=Start-Process -FilePath $d2Job.executable -ArgumentList $d2Args -WorkingDirectory $d2Job.cwd -WindowStyle Hidden -RedirectStandardOutput "$d2Output/stdout.log" -RedirectStandardError "$d2Output/stderr.log" -PassThru
    $d2Handle=$d2Process.Handle
    while (-not $d2Process.WaitForExit(1000)) {
        if (((Get-Date)-$d2Started).TotalSeconds -gt $d2Job.timeout_seconds) {
            Stop-Process -Id $d2Process.Id -Force
            throw 'This D2 process timed out; inspect its logs.'
        }
    }
    $d2Result=@{pid=$d2Process.Id;start=$d2Started.ToString('o');end=(Get-Date).ToString('o');seconds=((Get-Date)-$d2Started).TotalSeconds;exit_code=$d2Process.ExitCode;job=$d2Job}
    $d2Result | ConvertTo-Json -Depth 10 | Set-Content "$d2Output/process.json"
    $d2Text=(Get-Content "$d2Output/stdout.log","$d2Output/stderr.log") -join "`n"
    $d2Text -split "`n" | Select-String 'D2_|checks|failures|SCRIPT ERROR|ERROR:|Traceback|Error:' | ForEach-Object { $_.Line }
    $d2CheckedText=$d2Text -replace '(?m)^ERROR: Condition "ret != 0" is true\. Returning: ERR_CANT_OPEN\r?\n\s+at: load_default_certificates[^\r\n]*',''
    if ($d2Process.ExitCode -ne 0 -or $d2CheckedText -match '(?m)^(SCRIPT ERROR|ERROR:|Traceback|FAIL)') { throw "D2 job failed; $d2Output" }
    Write-Output "D2_JOB_OK $($d2Result.seconds)s $d2Output"
} finally {
    $env:APPDATA=$d2App; $env:BLENDER_USER_RESOURCES=$d2Blender
    if ($d2Owns) { $d2Mutex.ReleaseMutex() }
    $d2Mutex.Dispose()
}
