param(
    [Parameter(Mandatory)][string]$Godot,
    [Parameter(Mandatory)][string]$Project,
    [ValidateSet('Import','Check','Capture','Benchmark','Review')][string]$Mode = 'Check',
    [switch]$Visible
)
$ErrorActionPreference = 'Stop'
$boarProject = (Resolve-Path -LiteralPath $Project).Path
$boarEngine = (Resolve-Path -LiteralPath $Godot).Path
if (!(Test-Path -LiteralPath (Join-Path $boarProject 'boar-study.json'))) { throw 'Not an isolated boar study.' }
$boarPriorAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $boarProject 'user'
    New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
    $boarArguments = @('--path',('"' + $boarProject + '"'))
    switch ($Mode) {
        'Import' { $boarArguments += @('--headless','--editor','--import','--quit') }
        'Check' { $boarArguments += @('--headless','--','--check') }
        'Capture' { $boarArguments += @('--rendering-method','forward_plus','--','--capture') }
        'Benchmark' { $boarArguments += @('--rendering-method','forward_plus','--','--benchmark') }
        'Review' { $boarArguments += @('--rendering-method','forward_plus') }
    }
    $boarLog = Join-Path $boarProject ('run-' + $Mode.ToLowerInvariant() + '.log')
    $boarError = $boarLog + '.err'
    $boarOptions = @{FilePath=$boarEngine; ArgumentList=$boarArguments; PassThru=$true; RedirectStandardOutput=$boarLog; RedirectStandardError=$boarError}
    if (!$Visible) { $boarOptions.WindowStyle = 'Hidden' }
    $boarProcess = Start-Process @boarOptions
    if ($Mode -eq 'Review') { Write-Output "Review PID $($boarProcess.Id); close its own window when finished."; return }
    if (!$boarProcess.WaitForExit(180000)) { throw "Review PID $($boarProcess.Id) exceeded three minutes; inspect it without stopping other Godot processes." }
    if ($boarProcess.ExitCode -ne 0) { throw "Godot failed: $boarLog / $boarError" }
    $boarText = (Get-Content -LiteralPath $boarLog -Raw) + (Get-Content -LiteralPath $boarError -Raw)
    if ($boarText -match 'SCRIPT ERROR|SHADER ERROR|Error importing|Failed loading resource|Error loading image') { throw "Godot reported an import, script or shader error: $boarLog / $boarError" }
    $boarMarker = @{Check='BOAR_ENGINE_CHECKS_OK';Capture='BOAR_CAPTURES_OK';Benchmark='BOAR_BENCHMARK_OK'}[$Mode]
    if ($boarMarker -and !$boarText.Contains($boarMarker)) { throw "Missing completion marker $boarMarker" }
    Write-Output "$Mode passed: $boarLog"
} finally { $env:APPDATA = $boarPriorAppData }
