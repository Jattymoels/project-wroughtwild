# Install the pinned community Windows port of TRELLIS.2 inside ignored build/.
# Run with PowerShell 7. No system Python, WSL, service, driver or PATH changes.
#requires -Version 7.0
[CmdletBinding()]
param([switch]$SkipModels)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$destination = Join-Path $repository 'build/trellis-local'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'install-manifest.json') -Raw | ConvertFrom-Json
$downloads = Join-Path $destination 'downloads'
$models = Join-Path $destination 'models'
New-Item -ItemType Directory -Force -Path $downloads, $models | Out-Null

function Get-VerifiedFile($entry, [string]$directory) {
    if ([IO.Path]::GetFileName($entry.name) -ne $entry.name) { throw 'Unexpected manifest filename.' }
    $target = Join-Path $directory $entry.name
    if (-not (Test-Path -LiteralPath $target)) {
        $partial = $target + '.part'
        Write-Output ('Downloading ' + $entry.name + ' (' + [math]::Round($entry.bytes / 1GB, 2) + ' GiB)')
        $url = $entry.url
        if ($url.StartsWith('https://huggingface.co/')) { $url += '?download=true' }
        & curl.exe --fail --location --silent --show-error --connect-timeout 30 --speed-time 120 --speed-limit 1024 --retry 2 --continue-at - --output $partial $url
        if ($LASTEXITCODE -ne 0) { throw ('Download failed: ' + $entry.name) }
        if ((Get-Item -LiteralPath $partial).Length -ne $entry.bytes) { throw ('Size mismatch: ' + $entry.name) }
        if ((Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) {
            throw ('Checksum mismatch; file retained for inspection: ' + $entry.name)
        }
        Move-Item -LiteralPath $partial -Destination $target
    }
    if ((Get-Item -LiteralPath $target).Length -ne $entry.bytes -or
        (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) {
        throw ('Existing file does not match pinned manifest: ' + $entry.name)
    }
    Write-Output ('Verified ' + $entry.name)
}

function Expand-CheckedArchive([string]$archive, [string]$directory) {
    if (Test-Path -LiteralPath $directory) {
        if (-not (Test-Path -LiteralPath (Join-Path $directory '.extracted'))) {
            throw ('Incomplete or unrelated directory; inspect before continuing: ' + $directory)
        }
        return
    }
    # Refuse archive entries which could write outside the requested directory.
    $prefix = [IO.Path]::GetFullPath($directory).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        foreach ($entry in $zip.Entries) {
            $resolved = [IO.Path]::GetFullPath((Join-Path $directory $entry.FullName))
            if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                throw ('Unsafe archive entry: ' + $entry.FullName)
            }
        }
    } finally { $zip.Dispose() }
    Expand-Archive -LiteralPath $archive -DestinationPath $directory
    Set-Content -LiteralPath (Join-Path $directory '.extracted') -Value $manifest.version
}

foreach ($package in $manifest.packages) { Get-VerifiedFile $package $downloads }
Expand-CheckedArchive (Join-Path $downloads 'trellis-cuda-windows-x64.zip') (Join-Path $destination 'runtime')
Expand-CheckedArchive (Join-Path $downloads 'trellis-studio-windows-x64-portable.zip') (Join-Path $destination 'studio')
if (-not $SkipModels) {
    foreach ($weight in $manifest.weights) { Get-VerifiedFile $weight $models }
}
$studioData = Join-Path $destination 'studio/data'
New-Item -ItemType Directory -Force -Path $studioData | Out-Null
$configPath = Join-Path $studioData 'config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    [ordered]@{
        serverBin = (Join-Path $destination 'runtime/trellis-server.exe')
        modelsDir = $models
        backend = 'cuda'
        gpu = 0
        host = '127.0.0.1'
        port = 8743
        outputDir = (Join-Path $destination 'studio/data/output')
    } | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8NoBOM
}
Write-Output ('Installation files verified: ' + $destination)
Write-Output 'GPU execution and model generation must be checked separately.'
