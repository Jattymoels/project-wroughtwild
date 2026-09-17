$ErrorActionPreference='Stop'
$rfRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path.Replace('\','/')
$rfOut="$rfRoot/build/land04"
$rfCompiler='C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$rfCmake='C:/Program Files/CMake/bin/cmake.exe'
foreach($dir in @('user','local','temp','native')) {New-Item -ItemType Directory -Path "$rfOut/$dir" -Force | Out-Null}
$rfPrior=@{};foreach($key in @('PATH','APPDATA','LOCALAPPDATA','TEMP','TMP')){$rfPrior[$key]=[Environment]::GetEnvironmentVariable($key,'Process')}
try {
$env:PATH=(Split-Path $rfCompiler)+';'+$env:PATH
$env:APPDATA="$rfOut/user"; $env:LOCALAPPDATA="$rfOut/local"; $env:TEMP="$rfOut/temp"; $env:TMP="$rfOut/temp"
& $rfCmake -S $PSScriptRoot -B "$rfOut/native" -G 'MinGW Makefiles' "-DCMAKE_CXX_COMPILER=$rfCompiler"
if($LASTEXITCODE -ne 0){throw 'LAND04 native configure failed'}
$rfBuild=Start-Process -FilePath $rfCmake -ArgumentList @('--build',"$rfOut/native",'-j','6') -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput "$rfOut/native/build.log" -RedirectStandardError "$rfOut/native/build.err.log"
if($rfBuild.ExitCode -ne 0){Get-Content "$rfOut/native/build.log","$rfOut/native/build.err.log" -Tail 35;throw 'LAND04 native build failed'}
$rfDll="$rfOut/native/bin/libwroughtwild_sim.windows.x86_64.dll"
Copy-Item -LiteralPath $rfDll -Destination "$rfRoot/game/bin/libwroughtwild_sim.windows.x86_64.dll"
$rfFiles=@(& git -c "safe.directory=$rfRoot" -C $rfRoot ls-files --cached --others --exclude-standard sim game/extensions/wroughtwild_sim data/tuning)
$rfFiles+=@('sim/src/worldgen_frontier_v7.inc','tools/wroughtwild-land04/CMakeLists.txt','tools/wroughtwild-land04/build-native.ps1')
$rfSources=@{}; foreach($p in ($rfFiles | Sort-Object -Unique)) {$rfSources[$p]=(Get-FileHash -LiteralPath "$rfRoot/$p").Hash.ToLowerInvariant()}
@{base_revision=(& git -c "safe.directory=$rfRoot" -C $rfRoot rev-parse HEAD);dll=$rfDll;dll_sha256=(Get-FileHash -LiteralPath $rfDll).Hash.ToLowerInvariant();sources=$rfSources;compiler=$rfCompiler;abi='owner depot Godot 4.5 existing ABI';built=(Get-Date).ToString('o')} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$rfOut/native/provenance.json" -Encoding utf8
Write-Output "LAND04_BUILT $rfDll"
Get-FileHash -LiteralPath $rfDll

} finally {foreach($key in $rfPrior.Keys){[Environment]::SetEnvironmentVariable($key,$rfPrior[$key],'Process')}}
