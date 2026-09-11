param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
# Bounded, visible retries; never owns the slot while waiting on somebody else.
$ErrorActionPreference='Stop'
for($f2Attempt=0;$f2Attempt -lt 120;$f2Attempt++) {
  try {
    & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program $Program -JobArguments $JobArguments -Log $Log
    exit 0
  } catch {
    if ($_.Exception.Message -notmatch 'GPU slot busy|Existing GPU art/game process') { throw }
    if ($f2Attempt % 10 -eq 0) { Write-Output ('F2 waiting for shared art slot: '+$_.Exception.Message) }
    Start-Sleep -Seconds 3
  }
}
throw 'F2 queue timed out without launching; other work was preserved.'
