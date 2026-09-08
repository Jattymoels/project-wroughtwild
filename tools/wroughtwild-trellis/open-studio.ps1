# Open the local interactive app after the installation is complete.
$ErrorActionPreference = 'Stop'
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$local = Join-Path $repository 'build/trellis-local'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'install-manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest.weights) {
    $file = Join-Path $local ('models/' + $entry.name)
    if (-not (Test-Path -LiteralPath $file) -or (Get-Item -LiteralPath $file).Length -ne $entry.bytes) {
        throw ('Installation incomplete: ' + $entry.name)
    }
}
$previousWebviewFolder = $env:WEBVIEW2_USER_DATA_FOLDER
try {
    $env:WEBVIEW2_USER_DATA_FOLDER = Join-Path $local 'studio/data/webview2'
    $studioProcess = Start-Process -FilePath (Join-Path $local 'studio/trellis-studio.exe') -WorkingDirectory (Join-Path $local 'studio') -WindowStyle Normal -PassThru
    if ($studioProcess.WaitForExit(2000)) {
        throw ('Trellis Studio closed during startup (exit ' + $studioProcess.ExitCode + '). Run the launcher from your normal desktop session; the native window cannot initialize in the restricted agent sandbox.')
    }
} finally { $env:WEBVIEW2_USER_DATA_FOLDER = $previousWebviewFolder }
