param([Parameter(Mandatory)][string]$Program,[Parameter(Mandatory)][string[]]$JobArguments,[Parameter(Mandatory)][string]$Log)
# Bounded cooperative retries; callers yield frequently for progress updates.
$ErrorActionPreference='Stop'
for($f3Attempt=0;$f3Attempt -lt 120;$f3Attempt++) {
  try { & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program $Program -JobArguments $JobArguments -Log $Log; exit 0 }
  catch {
    if($_.Exception.Message -notmatch 'GPU slot busy|Existing GPU art/game process'){throw}
    if($f3Attempt % 6 -eq 0){Write-Output ('F3 deferred: '+$_.Exception.Message)}
    Start-Sleep -Seconds 3
  }
}
throw 'F3 did not acquire the slot within six minutes; no job launched.'
