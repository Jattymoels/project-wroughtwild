param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$CopyTo,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[ValidateSet('review','capture','motion','walk')][string]$Mode='review',[switch]$Visible)
$ErrorActionPreference='Stop'
$c4Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$c4Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
& $c4Python -B (Join-Path $PSScriptRoot 'verify_package.py') $Package $CopyTo
if($LASTEXITCODE -ne 0){throw 'Package verification failed'}
$c4Copy=[IO.Path]::GetFullPath($CopyTo)
$c4Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$c4Owns=$false
$c4PriorApp=$env:APPDATA;$c4PriorLocal=$env:LOCALAPPDATA
try {
 $c4Owns=$c4Mutex.WaitOne(0)
 if(-not $c4Owns -or (Get-Process | Where-Object {$_.ProcessName -match 'blender|godot|trellis'})){throw 'GPU busy; verified copy retained, no process interrupted'}
 $env:APPDATA=Join-Path $c4Copy 'isolated-user';$env:LOCALAPPDATA=Join-Path $c4Copy 'isolated-local-user'
 New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 foreach($c4Stage in @('import','review')){
  $c4Args=@('--path',(Join-Path $c4Copy 'review'),'--rendering-method',$Renderer,'--audio-driver','Dummy')
  if($c4Stage -eq 'import'){$c4Args+=@('--headless','--editor','--import')}elseif($Mode -ne 'review'){$c4Args+=@('--fixed-fps','60','--',('--'+$Mode))}
  $c4Quoted=($c4Args | ForEach-Object {'"'+$_.Replace('"','\"')+'"'}) -join ' '
  $c4Style=if($Visible -and $c4Stage -eq 'review'){'Normal'}else{'Hidden'}
  $c4Start=Get-Date
  $c4Proc=Start-Process -FilePath $c4Godot -ArgumentList $c4Quoted -WindowStyle $c4Style -PassThru -RedirectStandardOutput (Join-Path $c4Copy ($c4Stage+'.log')) -RedirectStandardError (Join-Path $c4Copy ($c4Stage+'.stderr'))
  Write-Output "C4 own PID $($c4Proc.Id)"
  $c4Proc.WaitForExit();$c4Proc.Refresh()
  @{program=$c4Godot;arguments=$c4Args;pid=$c4Proc.Id;exit=$c4Proc.ExitCode;seconds=((Get-Date)-$c4Start).TotalSeconds;started_utc=$c4Start.ToUniversalTime().ToString('o');finished_utc=(Get-Date).ToUniversalTime().ToString('o');appdata=$env:APPDATA;gpu_slot=$true} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $c4Copy ($c4Stage+'.job.json'))
  if($c4Proc.ExitCode -ne 0){throw 'C4 review process failed'}
  if(Select-String -Path (Join-Path $c4Copy ($c4Stage+'.log')),(Join-Path $c4Copy ($c4Stage+'.stderr')) -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error' -Quiet){throw 'C4 diagnostic error; inspect logs'}
 }
} finally {
 $env:APPDATA=$c4PriorApp;$env:LOCALAPPDATA=$c4PriorLocal
 if($c4Owns){$c4Mutex.ReleaseMutex()};$c4Mutex.Dispose()
}
