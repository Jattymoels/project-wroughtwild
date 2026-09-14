# R4 bounded GPU deferral only; every engine child uses the unchanged shared runner.
param([Parameter(Mandatory)][string[]]$Specs)
$ErrorActionPreference='Stop'
$r4Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$r4Held=$false
try {
 $r4Held=$r4Mutex.WaitOne(60000)
 if(-not $r4Held){Write-Output 'R4_DEFERRED: shared GPU remains occupied; no child launched.';exit 3}
 foreach($r4Spec in $Specs){& (Join-Path $PSScriptRoot '../run.ps1') -Spec $r4Spec}
} finally {
 if($r4Held){$r4Mutex.ReleaseMutex()}
 $r4Mutex.Dispose()
}
