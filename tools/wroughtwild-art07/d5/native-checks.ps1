param([Parameter(Mandatory)][string]$FreshOutput)
$ErrorActionPreference='Stop'
$d5Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$d5Out=[IO.Path]::GetFullPath($FreshOutput)
$d5Build=Join-Path $d5Root 'build/art07/d5'
if(-not $d5Out.StartsWith($d5Build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Output outside D5 build'}
if(Test-Path -LiteralPath $d5Out){throw 'Use fresh native output'}
New-Item -ItemType Directory -Path $d5Out | Out-Null
$d5Compiler='C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$d5PriorPath=$env:PATH
try {
  $env:PATH=(Split-Path $d5Compiler)+';'+$env:PATH
  $d5Sources=@('tests/sim/test_world_intensive.cpp','sim/src/worldgen.cpp','sim/src/worldgen_profiles.cpp','sim/src/tuning.cpp','sim/src/json.cpp','sim/src/lattice.cpp') | ForEach-Object { Join-Path $d5Root $_ }
  $d5Args=@('-std=c++17','-Wall','-Wextra','-Werror','-O1',('-I'+(Join-Path $d5Root 'sim/include')))+$d5Sources+@('-o',(Join-Path $d5Out 'world_intensive_tests.exe'))
  $d5Start=Get-Date
  & $d5Compiler @d5Args *> (Join-Path $d5Out 'compile.log')
  if($LASTEXITCODE -ne 0){throw 'Native compile failed'}
  & (Join-Path $d5Out 'world_intensive_tests.exe') (Join-Path $d5Root 'data/tuning') *> (Join-Path $d5Out 'test.log')
  if($LASTEXITCODE -ne 0){throw 'Native test failed'}
  $d5CoreArgs=@('-std=c++17','-Wall','-Wextra','-Werror','-O1',('-I'+(Join-Path $d5Root 'sim/include')),(Join-Path $d5Root 'tests/sim/test_main.cpp'))+@(Get-ChildItem (Join-Path $d5Root 'sim/src') -Filter '*.cpp' | ForEach-Object {$_.FullName})+@('-o',(Join-Path $d5Out 'sim_tests.exe'))
  & $d5Compiler @d5CoreArgs *> (Join-Path $d5Out 'core-compile.log')
  if($LASTEXITCODE -ne 0){throw 'Core compile failed'}
  & (Join-Path $d5Out 'sim_tests.exe') (Join-Path $d5Root 'data/tuning') *> (Join-Path $d5Out 'core-test.log')
  if($LASTEXITCODE -ne 0){throw 'Core tests failed'}
  @{revision=(& git -C $d5Root rev-parse HEAD);compiler=$d5Compiler;arguments=$d5Args;core_arguments=$d5CoreArgs;seconds=((Get-Date)-$d5Start).TotalSeconds;exit_code=0} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $d5Out 'command.json')
  Get-Content (Join-Path $d5Out 'test.log')
  Get-Content (Join-Path $d5Out 'core-test.log') | Select-Object -Last 5
} finally {$env:PATH=$d5PriorPath}
