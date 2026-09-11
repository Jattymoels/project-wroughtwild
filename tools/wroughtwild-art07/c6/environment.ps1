param([Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
if(Test-Path -LiteralPath $Output){throw 'Use a fresh environment record.'}
$c6Tools=@('C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe','C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe','C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe')
$c6Hashes=@($c6Tools | ForEach-Object {@{path=$_;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLower()}})
$c6Concept='C:/Users/Matty/Dev/project-wroughtwild/docs/art/concepts/environment/2026-09-09-frontier/02-habitat-kits.png'
@{date=(Get-Date).ToString('o');tools=$c6Hashes;blender='4.5.9';godot='4.5.stable.official.876b29033';cpu=@(Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors);system=@(Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory);gpu=(& nvidia-smi --query-gpu=name,driver_version,memory.total,utilization.gpu,memory.used --format=csv,noheader);concept=@{path=$c6Concept;sha256=(Get-FileHash -LiteralPath $c6Concept -Algorithm SHA256).Hash.ToLower()};generation='No new imagegen or TRELLIS run. B3 approved packed roots and native architecture reused read-only.'} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Output
