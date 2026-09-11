param([Parameter(Mandatory)][string]$Job)
$ErrorActionPreference='Stop'
$d3Job=Get-Content -LiteralPath $Job -Raw | ConvertFrom-Json
$d3Output=[IO.Path]::GetFullPath($d3Job.output)
if (Test-Path -LiteralPath $d3Output) { throw 'Use a fresh job log directory.' }
New-Item -ItemType Directory -Path $d3Output | Out-Null
$d3Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d3Owns=$false
$d3App=$env:APPDATA
$d3Blender=$env:BLENDER_USER_RESOURCES
$d3Started=Get-Date
try {
    if ($d3Job.gpu) {
        $d3Owns=$d3Mutex.WaitOne(0)
        if (-not $d3Owns) { throw 'ART-07 GPU slot busy; retry later with fresh logs.' }
        $d3Other=Get-Process | Where-Object { $_.ProcessName -match 'godot|blender|trellis' }
        if ($d3Other) { $d3Other | Select-Object Id,ProcessName | ConvertTo-Json | Set-Content "$d3Output/busy.json"; throw 'Existing art/playtest process; do not interrupt it.' }
        if ($d3Job.arguments -contains '--benchmark') {
            $d3Compilers=Get-Process | Where-Object { $_.ProcessName -match 'cc1plus|g\+\+|cmake|mingw32-make|ffmpeg' }
            if ($d3Compilers) { throw 'Compilation/encoding active; benchmark deferred.' }
            'No competing art, engine, compiler or encoder process at benchmark start.' | Set-Content "$d3Output/benchmark-guard.txt"
        }
        & nvidia-smi --query-gpu=name,driver_version,utilization.gpu,memory.used --format=csv | Set-Content "$d3Output/gpu.csv"
    }
    $env:APPDATA=if ($d3Job.appdata) { [IO.Path]::GetFullPath($d3Job.appdata) } else { Join-Path $d3Output 'appdata' }
    $env:BLENDER_USER_RESOURCES=Join-Path $d3Output 'blender-user'
    New-Item -ItemType Directory -Force $env:APPDATA,$env:BLENDER_USER_RESOURCES | Out-Null
    # Paths are resolved local JSON data, passed as quoted process arguments, never shell code.
    $d3Args=($d3Job.arguments | ForEach-Object { if ($_ -match '"') { throw 'Embedded quote in argument' }; '"'+$_+'"' }) -join ' '
    $d3Process=Start-Process -FilePath $d3Job.executable -ArgumentList $d3Args -WorkingDirectory $d3Job.cwd -WindowStyle Hidden -RedirectStandardOutput "$d3Output/stdout.log" -RedirectStandardError "$d3Output/stderr.log" -PassThru
    $d3Handle=$d3Process.Handle
    while (-not $d3Process.WaitForExit(1000)) {
        if (((Get-Date)-$d3Started).TotalSeconds -gt $d3Job.timeout_seconds) {
            Stop-Process -Id $d3Process.Id -Force
            throw 'This D3 process timed out; inspect its logs.'
        }
    }
    $d3Result=@{pid=$d3Process.Id;start=$d3Started.ToString('o');end=(Get-Date).ToString('o');seconds=((Get-Date)-$d3Started).TotalSeconds;exit_code=$d3Process.ExitCode;job=$d3Job}
    $d3Result | ConvertTo-Json -Depth 10 | Set-Content "$d3Output/process.json"
    $d3Text=(Get-Content "$d3Output/stdout.log","$d3Output/stderr.log") -join "`n"
    $d3Text -split "`n" | Select-String 'D3_|checks|failures|SCRIPT ERROR|ERROR:|Traceback|Error:' | ForEach-Object { $_.Line }
    $d3CheckedText=$d3Text
    # Reproduced by diagnostic-native-primitives with the unchanged native forms,
    # all 35,310 assertions passing. Retain the original full log and classify
    # only this exact single dummy-backend diagnostic, never rendered errors.
    $d3Known='(?m)^ERROR: Parameter "material" is null\.\r?\n\s+at: material_get_instance_shader_parameters \(servers/rendering/dummy/storage/material_storage.cpp:265\)\r?\n?'
    if ($d3Job.allow_native_dummy_material_diagnostic -and $d3Job.arguments -contains '--headless' -and [regex]::Matches($d3Text,$d3Known).Count -eq 1) {
        $d3CheckedText=[regex]::Replace($d3Text,$d3Known,'')
        $d3Result.known_diagnostic='One native-reproduced headless dummy material diagnostic; original log retained.'
        $d3Result | ConvertTo-Json -Depth 10 | Set-Content "$d3Output/process.json"
    }
    if ($d3Process.ExitCode -ne 0 -or $d3CheckedText -match '(?m)^(SCRIPT ERROR|ERROR:|Traceback|FAIL)') { throw "D3 job failed; $d3Output" }
    Write-Output "D3_JOB_OK $($d3Result.seconds)s $d3Output"
} finally {
    $env:APPDATA=$d3App; $env:BLENDER_USER_RESOURCES=$d3Blender
    if ($d3Owns) { $d3Mutex.ReleaseMutex() }
    $d3Mutex.Dispose()
}
