param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
# Bounded, visible retries; never owns the slot while waiting on somebody else.
$ErrorActionPreference='Stop'
for($d6Attempt=0;$d6Attempt -lt 120;$d6Attempt++) {
  try {
    & (Join-Path $PSScriptRoot 'gpu-slot.ps1') -Program $Program -JobArguments $JobArguments -Log $Log
    exit 0
  } catch {
    if ($_.Exception.Message -notmatch 'GPU slot busy|Existing GPU art/game process') { throw }
    if ($d6Attempt % 10 -eq 0) { Write-Output ('D6 waiting for shared art slot: '+$_.Exception.Message) }
    Start-Sleep -Seconds 3
  }
}
throw 'D6 queue timed out without launching; other work was preserved.'
