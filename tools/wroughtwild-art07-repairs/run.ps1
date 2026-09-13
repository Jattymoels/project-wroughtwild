# Derived from checked G2 run.ps1; original remains read-only.
param([Parameter(Mandatory)][string]$Spec, [string]$From='')
$ErrorActionPreference='Stop'
$repairRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$repairBranch=(& git -c ('safe.directory='+$repairRoot) -C $repairRoot branch --show-current).Trim()
if($LASTEXITCODE -ne 0 -or $repairBranch -notmatch '^codex/art07-(r[1-9])$'){throw 'Run from the assigned R worktree; main is not an execution workspace.'}
$repairId=$Matches[1]
$g2Build=[IO.Path]::GetFullPath((Join-Path $repairRoot ('build/art07-repairs/'+$repairId)))
function Assert-G2Path([string]$Value) {
 $resolved=[IO.Path]::GetFullPath($Value)
 if (-not $resolved.StartsWith($g2Build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw ('Outside assigned repair output: '+$resolved) }
 return $resolved
}
function Get-ArtProcesses {
 @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(blender|godot.*|trellis.*|cc1plus|g\+\+|cmake|mingw32-make|cl|ninja)\.exe$' } | Select-Object ProcessId,ParentProcessId,Name,CommandLine)
}
$g2Jobs=Get-Content -LiteralPath $Spec -Raw | ConvertFrom-Json
$g2Started=($From -eq '')
foreach($g2Job in $g2Jobs) {
 if($g2Job.id -eq $From){$g2Started=$true}
 if(-not $g2Started){continue}
 $g2Log=Assert-G2Path $g2Job.log
 $g2State=Assert-G2Path $g2Job.state
 if(Test-Path -LiteralPath $g2Log){throw ('Use fresh logs: '+$g2Log)}
 $g2Program=[IO.Path]::GetFullPath($g2Job.program)
 $g2Args=[string[]]$g2Job.arguments
 $g2PathIndex=[Array]::IndexOf($g2Args,'--path')
 if($g2PathIndex -ge 0){$null=Assert-G2Path $g2Args[$g2PathIndex+1]}
 New-Item -ItemType Directory -Path (Split-Path $g2Log),$g2State,(Join-Path $g2State 'temp') -Force | Out-Null
 $g2Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
 $g2Owns=$false
 $g2Previous=@{}
 foreach($g2Key in @('APPDATA','LOCALAPPDATA','TEMP','TMP','BLENDER_USER_RESOURCES')){$g2Previous[$g2Key]=[Environment]::GetEnvironmentVariable($g2Key,'Process')}
 $g2Start=Get-Date
 $g2Process=$null
 $g2Before=@();$g2Competing=@();$g2Failure='';$g2Code=$null
 try {
  $g2Owns=$g2Mutex.WaitOne(0)
  if(-not $g2Owns){throw 'ART-07 GPU slot busy; no process launched.'}
  $g2Before=Get-ArtProcesses
  if($g2Before.Count){throw ('Existing art/game/compiler process; defer without interrupting: '+($g2Before.ProcessId -join ','))}
  $env:APPDATA=$g2State
  $env:LOCALAPPDATA=Join-Path $g2State 'local'
  $env:TEMP=Join-Path $g2State 'temp';$env:TMP=$env:TEMP
  $env:BLENDER_USER_RESOURCES=Join-Path $g2State 'blender-user'
  $g2Quoted=@($g2Args | ForEach-Object {
   $g2Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
   '"'+[regex]::Replace($g2Arg,'(\\+)$','$1$1')+'"'
  })
  Write-Output ('G2_START '+$g2Job.id)
  $g2Process=Start-Process -FilePath $g2Program -ArgumentList $g2Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($g2Log+'.stdout') -RedirectStandardError ($g2Log+'.stderr')
  while(-not $g2Process.WaitForExit(1000)) {
   if($g2Args -contains '--benchmark') {
    $g2Competing+=@(Get-ArtProcesses | Where-Object {$_.ProcessId -ne $g2Process.Id})
   }
   if(((Get-Date)-$g2Start).TotalSeconds -gt 1800){$g2Failure='Owned job exceeded 1800 seconds.'}
   if((Test-Path -LiteralPath ($g2Log+'.stderr')) -and (Select-String -LiteralPath ($g2Log+'.stderr') -Pattern '^(SCRIPT ERROR|ERROR): (?!Condition .*certs\.size\(\) == 0)' -Quiet)){$g2Failure='Owned process reported a fatal script/engine error.'}
   if($g2Failure){Stop-Process -Id $g2Process.Id -Force -ErrorAction SilentlyContinue;$g2Process.WaitForExit();break}
  }
  $g2Code=$g2Process.ExitCode
  if($g2Code -ne 0 -and -not $g2Failure){$g2Failure='Nonzero process exit.'}
  if($g2Competing.Count){$g2Failure='Benchmark overlapped another process; diagnostic only.'}
 } catch {$g2Failure=$_.Exception.Message}
 finally {
  foreach($g2Key in $g2Previous.Keys){[Environment]::SetEnvironmentVariable($g2Key,$g2Previous[$g2Key],'Process')}
  if($g2Owns){$g2Mutex.ReleaseMutex()};$g2Mutex.Dispose()
 }
 $g2Lines=@()
 foreach($g2Suffix in @('.stdout','.stderr')){if(Test-Path -LiteralPath ($g2Log+$g2Suffix)){$g2Lines+=Get-Content -LiteralPath ($g2Log+$g2Suffix)}}
 $g2Lines | Set-Content -LiteralPath $g2Log -Encoding utf8
 if($g2Lines -match '^(SCRIPT ERROR|ERROR): (?!Condition .*certs\.size\(\) == 0)'){$g2Failure='Fatal log diagnostic; assertions do not override this.'}
 $g2Result=@{id=$g2Job.id;program=$g2Program;arguments=$g2Args;start=$g2Start.ToString('o');seconds=((Get-Date)-$g2Start).TotalSeconds;exit_code=$g2Code;wrapper_pid=$PID;child_pid=$(if($g2Process){$g2Process.Id}else{$null});appdata=$g2State;localappdata=(Join-Path $g2State 'local');temp=(Join-Path $g2State 'temp');processes_before=$g2Before;benchmark_competitors=$g2Competing;failure=$g2Failure;log_sha256=(Get-FileHash -LiteralPath $g2Log -Algorithm SHA256).Hash.ToLower();results=@($g2Lines | Where-Object {$_ -match 'G[12]_|checks|assertions|passed|failures'})}
 $g2Result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath ($g2Log+'.json') -Encoding utf8
 if($g2Failure){throw ($g2Job.id+': '+$g2Failure+' '+$g2Log)}
 Write-Output ('G2_PASS '+$g2Job.id+' '+[math]::Round($g2Result.seconds,2)+'s')
}
