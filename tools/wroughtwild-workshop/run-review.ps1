param([Parameter(Mandatory)][string]$Project, [ValidateSet('import','check','restart','capture','benchmark','open')][string]$Mode='capture', [switch]$Compatibility)
$ErrorActionPreference='Stop'
$artProject=(Resolve-Path -LiteralPath $Project).Path
$artRun=Split-Path $artProject
$env:APPDATA=Join-Path $artRun 'review-appdata'
$artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$artArguments=@('--path',$artProject,'--resolution','1600x1000')
if ($Mode -eq 'import') { $artArguments+=@('--headless','--editor','--import','--quit') }
elseif ($Mode -in @('check','restart')) { $artArguments+=@('--headless','--script','res://check_native.gd','--quit-after','5000'); if ($Mode -eq 'restart') { $artArguments+=@('--','--restart') } }
elseif ($Mode -eq 'capture') { $artArguments+=@('--quit-after','12000','--','--capture') }
elseif ($Mode -eq 'benchmark') { $artArguments+=@('--quit-after','12000','--','--benchmark') }
if ($Compatibility) {
    $artArguments=@('--rendering-method','gl_compatibility')+$artArguments
    if ($Mode -in @('capture','benchmark')) { $artArguments+='--compatibility-proof' }
}
$artLog=Join-Path $artRun ($Mode+'.log')
$artError=Join-Path $artRun ($Mode+'-errors.log')
$artProcess=Start-Process -FilePath $artGodot -ArgumentList $artArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $artLog -RedirectStandardError $artError
@{pid=$artProcess.Id;project=$artProject;mode=$Mode;started_utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content (Join-Path $artRun ($Mode+'-process.json'))
if ($Mode -eq 'open') { Write-Output "ART04_REVIEW_STARTED $($artProcess.Id)"; return }
$artTimer=[Diagnostics.Stopwatch]::StartNew()
while (-not $artProcess.WaitForExit(1000)) {
    if ($artTimer.Elapsed.TotalSeconds -gt 180) { Stop-Process -Id $artProcess.Id; throw "Own $Mode process exceeded three minutes; inspect $artLog and $artError." }
    if (Test-Path -LiteralPath $artError) {
        $artText=Get-Content -LiteralPath $artError -Raw
        if ($artText -match 'SCRIPT ERROR:|Parse Error:|Assertion failed') { Stop-Process -Id $artProcess.Id; throw "Own $Mode process failed; inspect $artError." }
    }
}
$artProcess.Refresh()
$artExit=$artProcess.ExitCode
$artErrors=Get-Content -LiteralPath $artError -Raw
if ($artExit -ne 0 -or $artErrors -match 'ERROR:|SCRIPT ERROR:') { throw "Own $Mode exited $artExit; inspect $artLog and $artError." }
Write-Output "ART04_REVIEW_OK $Mode"
