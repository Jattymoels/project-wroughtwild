param([Parameter(Mandatory)][string]$Snapshot,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$d2Worker=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$d2Out=[IO.Path]::GetFullPath($Output)
if (-not $d2Out.StartsWith((Join-Path $d2Worker 'build/art07/d2')+[IO.Path]::DirectorySeparatorChar)) { throw 'Output must remain in the D2 build tree.' }
if (Test-Path -LiteralPath $d2Out) { throw 'Use fresh sim output.' }
New-Item -ItemType Directory $d2Out | Out-Null
$d2Compiler=Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$d2PriorPath=$env:PATH
try {
    $env:PATH=(Split-Path $d2Compiler)+';'+$env:PATH
    $d2Sources=@((Join-Path $Snapshot 'tests/sim/test_main.cpp'))+@(Get-ChildItem -LiteralPath (Join-Path $Snapshot 'sim/src') -Filter '*.cpp' | ForEach-Object FullName)
    & $d2Compiler -std=c++17 -Wall -Wextra -Werror -O1 -I (Join-Path $Snapshot 'sim/include') @d2Sources -o "$d2Out/sim_tests.exe" *> "$d2Out/compile.log"
    if ($LASTEXITCODE -ne 0) { throw 'Current sim compilation failed.' }
    & "$d2Out/sim_tests.exe" (Join-Path $Snapshot 'data/tuning') *> "$d2Out/tests.log"
    if ($LASTEXITCODE -ne 0) { throw 'Current sim tests failed.' }
    Get-Content "$d2Out/tests.log" -Tail 4
} finally { $env:PATH=$d2PriorPath }
