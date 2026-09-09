param(
    [Parameter(Mandatory)][string]$Godot,
    [Parameter(Mandatory)][string]$Project,
    [ValidateSet('Import','Check','Capture','Benchmark','Review')][string]$Mode = 'Check',
    [switch]$Visible
)
$ErrorActionPreference = 'Stop'
$faunaProject = (Resolve-Path -LiteralPath $Project).Path
$faunaEngine = (Resolve-Path -LiteralPath $Godot).Path
if (!(Test-Path -LiteralPath (Join-Path $faunaProject 'wolf.json')) -and !(Test-Path -LiteralPath (Join-Path $faunaProject 'stag.json'))) { throw 'Not an isolated fauna study.' }
$faunaPriorAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $faunaProject 'user'
    New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
    $faunaArguments = @('--path',('"' + $faunaProject + '"'))
    switch ($Mode) {
        'Import' { $faunaArguments += @('--headless','--editor','--import','--quit') }
        'Check' { $faunaArguments += @('--headless','--','--check') }
        'Capture' { $faunaArguments += @('--rendering-method','forward_plus','--','--capture') }
        'Benchmark' { $faunaArguments += @('--rendering-method','forward_plus','--','--benchmark') }
        'Review' { $faunaArguments += @('--rendering-method','forward_plus') }
    }
    $faunaLog = Join-Path $faunaProject ('run-' + $Mode.ToLowerInvariant() + '.log')
    $faunaError = $faunaLog + '.err'
    $faunaOptions = @{FilePath=$faunaEngine; ArgumentList=$faunaArguments; PassThru=$true; RedirectStandardOutput=$faunaLog; RedirectStandardError=$faunaError}
    if (!$Visible) { $faunaOptions.WindowStyle = 'Hidden' }
    $faunaProcess = Start-Process @faunaOptions
    if ($Mode -eq 'Review') { Write-Output "Review PID $($faunaProcess.Id); close its own window when finished."; return }
    $faunaDeadline = [DateTime]::UtcNow.AddMinutes(5)
    while (!$faunaProcess.WaitForExit(500)) {
        $faunaLiveText = (Get-Content -LiteralPath $faunaLog -Raw -ErrorAction SilentlyContinue) + (Get-Content -LiteralPath $faunaError -Raw -ErrorAction SilentlyContinue)
        if ($faunaLiveText -match 'SCRIPT ERROR|SHADER ERROR' -or [DateTime]::UtcNow -gt $faunaDeadline) {
            Stop-Process -Id $faunaProcess.Id
            throw "Own review PID $($faunaProcess.Id) failed or exceeded five minutes; inspect $faunaLog / $faunaError"
        }
    }
    if ($faunaProcess.ExitCode -ne 0) { throw "Godot failed: $faunaLog / $faunaError" }
    $faunaText = (Get-Content -LiteralPath $faunaLog -Raw) + (Get-Content -LiteralPath $faunaError -Raw)
    if ($faunaText -match 'SCRIPT ERROR|SHADER ERROR|Error importing|Failed loading resource|Error loading image') { throw "Godot reported an import, script or shader error: $faunaLog / $faunaError" }
    $faunaMarker = @{Check='FAUNA_ENGINE_CHECKS_OK';Capture='FAUNA_CAPTURES_OK';Benchmark='FAUNA_BENCHMARK_OK'}[$Mode]
    if ($faunaMarker -and !$faunaText.Contains($faunaMarker)) { throw "Missing completion marker $faunaMarker" }
    Write-Output "$Mode passed: $faunaLog"
} finally { $env:APPDATA = $faunaPriorAppData }
