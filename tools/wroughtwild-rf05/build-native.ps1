$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$rfOut="$rfRoot/build/rf05"
$rfCompiler='C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$rfCmake='C:/Program Files/CMake/bin/cmake.exe'
foreach($dir in @('user','local','temp','native')) {New-Item -ItemType Directory -Path "$rfOut/$dir" -Force | Out-Null}
$rfPrior=@{};foreach($key in @('PATH','APPDATA','LOCALAPPDATA','TEMP','TMP')){$rfPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
try {
$env:PATH=(Split-Path $rfCompiler)+';'+$env:PATH
$env:APPDATA="$rfOut/user"; $env:LOCALAPPDATA="$rfOut/local"; $env:TEMP="$rfOut/temp"; $env:TMP="$rfOut/temp"
& $rfCmake -S $PSScriptRoot -B "$rfOut/native" -G 'MinGW Makefiles' "-DCMAKE_CXX_COMPILER=$rfCompiler"
if($LASTEXITCODE -ne 0){throw 'RF05 native configure failed'}
& $rfCmake --build "$rfOut/native" -j 6 *> "$rfOut/native/build.log"
if($LASTEXITCODE -ne 0){Get-Content "$rfOut/native/build.log" -Tail 35;throw 'RF05 native build failed'}
$rfDll="$rfOut/native/bin/libwroughtwild_sim.windows.x86_64.dll"
Copy-Item -LiteralPath $rfDll -Destination "$rfRoot/game/bin/libwroughtwild_sim.windows.x86_64.dll"
$rfFiles=@(& git -C $rfRoot ls-files --cached --others --exclude-standard sim game/extensions/wroughtwild_sim data/tuning)
$rfFiles+=@('sim/src/worldgen_frontier_v7.inc','tools/wroughtwild-rf05/CMakeLists.txt','tools/wroughtwild-rf05/build-native.ps1')
$rfSources=@{}; foreach($p in ($rfFiles | Sort-Object -Unique)) {$rfSources[$p]=(Get-FileHash -LiteralPath "$rfRoot/$p").Hash.ToLowerInvariant()}
@{base_revision=(& git -C $rfRoot rev-parse HEAD);dll=$rfDll;dll_sha256=(Get-FileHash -LiteralPath $rfDll).Hash.ToLowerInvariant();sources=$rfSources;compiler=$rfCompiler;abi='owner depot Godot 4.5 existing ABI';built=(Get-Date).ToString('o')} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$rfOut/native/provenance.json" -Encoding utf8
Write-Output "RF05_BUILT $rfDll"
Get-FileHash -LiteralPath $rfDll

} finally {foreach($key in $rfPrior.Keys){[Environment]::SetEnvironmentVariable($key,$rfPrior[$key],'Process')}}
