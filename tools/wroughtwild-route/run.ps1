param([string]$Project='build/art05/baseline-v01/game',[string]$Scene='probe',[switch]$Rendered,[switch]$Baseline,[switch]$Restart,[switch]$Import,[switch]$Compatibility,[switch]$Smoke)
$ErrorActionPreference='Stop'
$p=(Resolve-Path -LiteralPath $Project).Path
$run=Split-Path $p
$env:APPDATA=Join-Path $run 'isolated-appdata'
$args=@('--path',$p,'--resolution','1280x800')
if($Import){$args+=@('--headless','--editor','--import','--quit')}
else{
 if(-not $Rendered){$args+='--headless'}
 $args+=@('res://art05/'+$Scene+'.tscn','--','--art05')
 if($Baseline){$args+='--baseline'}
 if($Restart){$args+='--restart'}
 if($Smoke){$args+='--smoke'}
}
if($Compatibility){$args=@('--rendering-method','gl_compatibility')+$args}
$label=$Scene+$(if($Import){'-import'}elseif($Restart){'-restart'}elseif($Baseline){'-baseline'}else{'-art'})+$(if($Compatibility){'-compat'}else{''})
$stdout=Join-Path $run ($label+'.log');$stderr=Join-Path $run ($label+'-errors.log')
$process=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
@{pid=$process.Id;project=$p;arguments=$args;utc=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json|Set-Content (Join-Path $run ($label+'-process.json'))
$timer=[Diagnostics.Stopwatch]::StartNew()
while(-not $process.WaitForExit(1000)){
 if($timer.Elapsed.TotalSeconds -gt 900){Stop-Process -Id $process.Id;throw 'Own review timed out'}
 $e=Get-Content -LiteralPath $stderr -Raw
 $relevant=$e -replace 'ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates \(platform/windows/os_windows.cpp:2468\)\r?\n',''
 if($relevant -match 'ERROR:|SCRIPT ERROR:|Parse Error:|Assertion failed'){Stop-Process -Id $process.Id;throw "Review failed: $stderr"}
}
$process.Refresh()
$e=Get-Content -LiteralPath $stderr -Raw
$e=$e -replace 'ERROR: Failed to read the root certificate store\.\r?\n\s+at: get_system_ca_certificates \(platform/windows/os_windows.cpp:2468\)\r?\n',''
if($process.ExitCode -ne 0 -or $e -match 'ERROR:|SCRIPT ERROR:'){throw "Review failed: $stderr"}
Get-Content -LiteralPath $stdout -Tail 12
