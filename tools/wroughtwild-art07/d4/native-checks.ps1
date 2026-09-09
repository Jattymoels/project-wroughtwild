param([Parameter(Mandatory)][string]$FreshOutput)
$ErrorActionPreference='Stop'
$d4Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$d4Out=[IO.Path]::GetFullPath($FreshOutput)
$d4Build=Join-Path $d4Root 'build/art07/d4'
if(-not $d4Out.StartsWith($d4Build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Output outside D4 build'}
if(Test-Path -LiteralPath $d4Out){throw 'Use fresh native output'}
New-Item -ItemType Directory -Path $d4Out | Out-Null
$d4Compiler='C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$d4PriorPath=$env:PATH
try {
  $env:PATH=(Split-Path $d4Compiler)+';'+$env:PATH
  $d4Sources=@('tests/sim/test_world_intensive.cpp','sim/src/worldgen.cpp','sim/src/worldgen_profiles.cpp','sim/src/tuning.cpp','sim/src/json.cpp','sim/src/lattice.cpp') | ForEach-Object { Join-Path $d4Root $_ }
  $d4Args=@('-std=c++17','-Wall','-Wextra','-Werror','-O1',('-I'+(Join-Path $d4Root 'sim/include')))+$d4Sources+@('-o',(Join-Path $d4Out 'world_intensive_tests.exe'))
  $d4Start=Get-Date
  & $d4Compiler @d4Args *> (Join-Path $d4Out 'compile.log')
  if($LASTEXITCODE -ne 0){throw 'Native compile failed'}
  & (Join-Path $d4Out 'world_intensive_tests.exe') (Join-Path $d4Root 'data/tuning') *> (Join-Path $d4Out 'test.log')
  if($LASTEXITCODE -ne 0){throw 'Native test failed'}
  $d4CoreArgs=@('-std=c++17','-Wall','-Wextra','-Werror','-O1',('-I'+(Join-Path $d4Root 'sim/include')),(Join-Path $d4Root 'tests/sim/test_main.cpp'))+@(Get-ChildItem (Join-Path $d4Root 'sim/src') -Filter '*.cpp' | ForEach-Object {$_.FullName})+@('-o',(Join-Path $d4Out 'sim_tests.exe'))
  & $d4Compiler @d4CoreArgs *> (Join-Path $d4Out 'core-compile.log')
  if($LASTEXITCODE -ne 0){throw 'Core compile failed'}
  & (Join-Path $d4Out 'sim_tests.exe') (Join-Path $d4Root 'data/tuning') *> (Join-Path $d4Out 'core-test.log')
  if($LASTEXITCODE -ne 0){throw 'Core tests failed'}
  @{revision=(& git -C $d4Root rev-parse HEAD);compiler=$d4Compiler;arguments=$d4Args;core_arguments=$d4CoreArgs;seconds=((Get-Date)-$d4Start).TotalSeconds;exit_code=0} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $d4Out 'command.json')
  Get-Content (Join-Path $d4Out 'test.log')
  Get-Content (Join-Path $d4Out 'core-test.log') | Select-Object -Last 5
} finally {$env:PATH=$d4PriorPath}
