param([string]$Revision='0f35e87c6a23e3197bec968fa4443c8e134317b3', [Parameter(Mandatory)][string]$Output, [Parameter(Mandatory)][string]$Depot)
$ErrorActionPreference='Stop'
$artRepo=[IO.Path]::GetFullPath($Depot)
$artOutput=[IO.Path]::GetFullPath($Output)
$e2Worker=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
if (-not $artOutput.StartsWith((Join-Path $e2Worker 'build/art07/e2')+[IO.Path]::DirectorySeparatorChar)) { throw 'Output must remain in the E2 build tree.' }
if (Test-Path -LiteralPath $artOutput) { throw 'Use a fresh native baseline directory.' }
New-Item -ItemType Directory -Path $artOutput | Out-Null
$artSnapshot=Join-Path $artOutput 'snapshot'
New-Item -ItemType Directory -Path $artSnapshot | Out-Null
& git -c "safe.directory=$artRepo" -C $artRepo archive --format=zip --output="$artOutput/baseline.zip" $Revision sim data game/extensions/wroughtwild_sim game/bin/wroughtwild_sim.gdextension
if ($LASTEXITCODE -ne 0) { throw 'Frozen native archive failed.' }
Expand-Archive -LiteralPath "$artOutput/baseline.zip" -DestinationPath $artSnapshot
$artCompiler=Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe'
$artPriorPath=$env:PATH
try {
$env:PATH=(Split-Path $artCompiler)+';'+$env:PATH
$artR=$artRepo.Replace('\','/')
$artS=$artSnapshot.Replace('\','/')
$artO=$artOutput.Replace('\','/')
# Reuse only the existing godot-cpp ABI library/headers. Every game/native rule
# source comes from the recorded commit, never the concurrent working tree.
$artCmake=@"
cmake_minimum_required(VERSION 3.22)
project(art07_e2_native LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
file(GLOB RULES "$artS/sim/src/*.cpp")
add_library(wroughtwild_sim SHARED "$artS/game/extensions/wroughtwild_sim/src/register_types.cpp" "$artS/game/extensions/wroughtwild_sim/src/wroughtwild_sim.cpp" `$`{RULES`})
target_include_directories(wroughtwild_sim PRIVATE "$artS/sim/include" "$artS/game/extensions/wroughtwild_sim/src" "$artR/third_party/godot-cpp/include" "$artR/build/gdext/godot-cpp/gen/include" "$artR/third_party/godot-cpp/gdextension")
target_compile_definitions(wroughtwild_sim PRIVATE DEBUG_ENABLED GDEXTENSION HOT_RELOAD_ENABLED THREADS_ENABLED WINDOWS_ENABLED)
target_compile_options(wroughtwild_sim PRIVATE -O2 -Wall -Wextra -fno-gnu-unique)
target_link_libraries(wroughtwild_sim PRIVATE "$artR/build/gdext/bin/libgodot-cpp.windows.template_debug.x86_64.a" kernel32 user32 gdi32 winspool shell32 ole32 oleaut32 uuid comdlg32 advapi32)
target_link_options(wroughtwild_sim PRIVATE -static -static-libgcc -static-libstdc++ -Wl,--no-undefined)
set_target_properties(wroughtwild_sim PROPERTIES PREFIX "lib" OUTPUT_NAME "wroughtwild_sim.windows.x86_64" RUNTIME_OUTPUT_DIRECTORY "$artO/bin")
"@
$artCmake | Set-Content -Encoding utf8 "$artOutput/CMakeLists.txt"
& cmake -S $artOutput -B "$artOutput/compile" -G 'MinGW Makefiles' "-DCMAKE_CXX_COMPILER=$artCompiler"
if ($LASTEXITCODE -ne 0) { throw 'Isolated native configuration failed.' }
& cmake --build "$artOutput/compile" -j 4 *> "$artOutput/build.log"
if ($LASTEXITCODE -ne 0) { throw 'Isolated native build failed; inspect build.log.' }
@{revision=$Revision; dll_sha256=(Get-FileHash "$artOutput/bin/libwroughtwild_sim.windows.x86_64.dll").Hash.ToLowerInvariant(); godot_cpp_sha256=(Get-FileHash "$artRepo/build/gdext/bin/libgodot-cpp.windows.template_debug.x86_64.a").Hash.ToLowerInvariant()} | ConvertTo-Json | Set-Content "$artOutput/provenance.json"
Write-Output 'E2_NATIVE_BUILD_OK'
} finally { $env:PATH=$artPriorPath }
