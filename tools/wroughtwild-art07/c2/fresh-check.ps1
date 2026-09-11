param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$CopyTo,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
$artPython='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$artEngine='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$artBlender='C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
& $artPython "$PSScriptRoot/verify_package.py" $Package $CopyTo
if($LASTEXITCODE -ne 0){throw 'Fresh-copy hash verification failed.'}
foreach($artKind in @('review','native/game')){
 $artName=$artKind.Replace('/','-')
 & "$PSScriptRoot/run-job.ps1" -Program $artEngine -Arguments @('--headless','--editor','--path',(Join-Path $CopyTo $artKind),'--import') -Log (Join-Path $Logs ($artName+'-import.log'))
}
& "$PSScriptRoot/run-job.ps1" -Program $artBlender -Arguments @('--background','--threads','8','--python-exit-code','1','--python',"$PSScriptRoot/audit.py",'--',(Join-Path $CopyTo 'source'),(Join-Path $Logs 'fresh-audit.json')) -Log (Join-Path $Logs 'blender-reopen.log')
foreach($artMode in @('flow','partial','final')){
 $artArgs=@('--headless','--path',(Join-Path $CopyTo 'native/game'),'--audio-driver','Dummy','--fixed-fps','60','res://c2/native_review.tscn')
 if($artMode -ne 'flow'){$artArgs+=@('--',('--restore-'+$artMode))}
 & "$PSScriptRoot/run-job.ps1" -Program $artEngine -Arguments $artArgs -Log (Join-Path $Logs ('native-'+$artMode+'.log'))
}
& "$PSScriptRoot/run-stage.ps1" -Project (Join-Path $CopyTo 'review') -Logs (Join-Path $Logs 'capture') -Stage Capture
& $artPython "$PSScriptRoot/verify_package.py" $Package
if($LASTEXITCODE -ne 0){throw 'Canonical handoff changed during fresh-copy review.'}
Write-Output 'C2_FRESH_HANDOFF_CHECKED'
