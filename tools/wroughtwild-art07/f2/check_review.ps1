param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$f2Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f2'))
$f2Project=[IO.Path]::GetFullPath($Project);$f2Output=[IO.Path]::GetFullPath($Output)
foreach($f2Path in @($f2Project,$f2Output)){if(-not $f2Path.StartsWith($f2Root+[IO.Path]::DirectorySeparatorChar)){throw 'F2-only paths required'}}
if(Test-Path -LiteralPath $f2Output){throw 'Fresh logs required'}
New-Item -ItemType Directory -Path $f2Output | Out-Null
$f2Prior=$env:APPDATA
try{
 $env:APPDATA=Join-Path $f2Root 'u'
 foreach($f2Mode in @('import','check','restart')){
  $f2Args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$f2Project)
  if($f2Mode -eq 'import'){$f2Args+=@('--editor','--import')}else{$f2Args+=@('--',('--'+$f2Mode))}
  $f2Start=Get-Date;$f2Log=Join-Path $f2Output $f2Mode
  $f2Process=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList @($f2Args|ForEach-Object {'"'+$_+'"'}) -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f2Log+'.stdout') -RedirectStandardError ($f2Log+'.stderr')
  if(-not $f2Process.WaitForExit(180000)){
   # The console executable launches one engine child. Stop only that child
   # after verifying both parent identity and this isolated project's path.
   Get-CimInstance Win32_Process | Where-Object {$_.ParentProcessId -eq $f2Process.Id -and $_.Name -match '^Godot' -and $_.CommandLine.Contains($f2Project)} | ForEach-Object {Stop-Process -Id $_.ProcessId}
   Stop-Process -Id $f2Process.Id -ErrorAction SilentlyContinue
   throw 'This F2 check timed out; only its verified own process pair stopped'
  }
  @{arguments=$f2Args;pid=$f2Process.Id;seconds=((Get-Date)-$f2Start).TotalSeconds;exit_code=$f2Process.ExitCode;appdata=$env:APPDATA}|ConvertTo-Json|Set-Content ($f2Log+'.json')
  Get-Content ($f2Log+'.stdout')|Select-Object -Last 5
  if($f2Process.ExitCode -ne 0 -or (Select-String -LiteralPath ($f2Log+'.stderr') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)){Get-Content ($f2Log+'.stderr')|Select-Object -First 20;throw ('F2 check failed: '+$f2Mode)}
 }
}finally{$env:APPDATA=$f2Prior}
