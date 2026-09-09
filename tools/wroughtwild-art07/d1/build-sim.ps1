param([Parameter(Mandatory)][string]$Snapshot,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$d1Worker=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$d1Out=[IO.Path]::GetFullPath($Output)
if (-not $d1Out.StartsWith((Join-Path $d1Worker 'build/art07/d1')+[IO.Path]::DirectorySeparatorChar)) { throw 'Output must remain in the D1 build tree.' }
if (Test-Path -LiteralPath $d1Out) { throw 'Use fresh sim output.' }
New-Item -ItemType Directory $d1Out | Out-Null
$d1Compiler=Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$d1PriorPath=$env:PATH
try {
    $env:PATH=(Split-Path $d1Compiler)+';'+$env:PATH
    $d1Sources=@((Join-Path $Snapshot 'tests/sim/test_main.cpp'))+@(Get-ChildItem -LiteralPath (Join-Path $Snapshot 'sim/src') -Filter '*.cpp' | ForEach-Object FullName)
    & $d1Compiler -std=c++17 -Wall -Wextra -Werror -O1 -I (Join-Path $Snapshot 'sim/include') @d1Sources -o "$d1Out/sim_tests.exe" *> "$d1Out/compile.log"
    if ($LASTEXITCODE -ne 0) { throw 'Current sim compilation failed.' }
    & "$d1Out/sim_tests.exe" (Join-Path $Snapshot 'data/tuning') *> "$d1Out/tests.log"
    if ($LASTEXITCODE -ne 0) { throw 'Current sim tests failed.' }
    Get-Content "$d1Out/tests.log" -Tail 4
} finally { $env:PATH=$d1PriorPath }
