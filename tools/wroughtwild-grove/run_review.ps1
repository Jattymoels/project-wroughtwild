param([Parameter(Mandatory)][string]$Godot,[Parameter(Mandatory)][string]$Project,[ValidateSet('Import','Check','Capture','Walk','Benchmark','Review')][string]$Mode='Check',[switch]$Visible)
$ErrorActionPreference='Stop'
$groveProject=(Resolve-Path -LiteralPath $Project).Path
$groveEngine=(Resolve-Path -LiteralPath $Godot).Path
if(!(Test-Path -LiteralPath (Join-Path $groveProject 'grove.json'))){throw 'Not an isolated grove project.'}
$grovePrior=$env:APPDATA
try{
 $env:APPDATA=Join-Path $groveProject 'user';New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
 $groveArgs=@('--path',('"'+$groveProject+'"'))
 if($Mode -eq 'Import'){$groveArgs+=@('--headless','--editor','--import','--quit')}
 elseif($Mode -eq 'Check'){$groveArgs+=@('--headless','--','--check')}
 elseif($Mode -ne 'Review'){$groveArgs+=@('--rendering-method','forward_plus','--',('--'+$Mode.ToLowerInvariant()))}
 $groveLog=Join-Path $groveProject ('run-'+$Mode.ToLowerInvariant()+'.log')
 $groveOptions=@{FilePath=$groveEngine;ArgumentList=$groveArgs;PassThru=$true;RedirectStandardOutput=$groveLog;RedirectStandardError=($groveLog+'.err')}
 if(!$Visible){$groveOptions.WindowStyle='Hidden'}
 $groveProcess=Start-Process @groveOptions
 Write-Output "ART-02 $Mode PID $($groveProcess.Id)"
 if($Mode -eq 'Review'){Write-Output "Grove review PID $($groveProcess.Id)";return}
 $groveDeadline=[DateTime]::UtcNow.AddMinutes(5)
 while(!$groveProcess.WaitForExit(1000)){
  $groveErrors=Get-Content -LiteralPath ($groveLog+'.err') -Raw -ErrorAction SilentlyContinue
  if($groveErrors -match 'SCRIPT ERROR|SHADER ERROR|Parse Error'){
   $groveProcess.Kill($true)
   throw "Stopped only this failed review PID $($groveProcess.Id): $groveLog"
  }
  if([DateTime]::UtcNow -gt $groveDeadline){throw "Grove process $($groveProcess.Id) still running; inspect its own logs."}
 }
 $groveText=(Get-Content $groveLog -Raw)+(Get-Content ($groveLog+'.err') -Raw)
 if($groveProcess.ExitCode -ne 0 -or $groveText -match 'SCRIPT ERROR|SHADER ERROR|Error importing|Failed loading resource|Parse Error'){throw "Grove $Mode failed (exit $($groveProcess.ExitCode)): $groveLog"}
 if($Mode -ne 'Import' -and !$groveText.Contains('GROVE_'+$Mode.ToUpperInvariant()+'_OK')){throw "Missing completion marker: $groveLog"}
 Write-Output "$Mode passed: $groveLog"
}finally{$env:APPDATA=$grovePrior}
