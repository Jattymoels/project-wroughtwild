param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output,[string]$Mode='checks',[string]$Renderer='forward_plus')
$ErrorActionPreference='Stop'
$f3Project=[IO.Path]::GetFullPath($Project)
$f3Out=[IO.Path]::GetFullPath($Output)
$f3Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f3'))
foreach($f3Path in @($f3Project,$f3Out)){if(-not $f3Path.StartsWith($f3Root+[IO.Path]::DirectorySeparatorChar)){throw 'F3 path boundary'}}
if(Test-Path -LiteralPath $f3Out){throw 'Use a fresh run log'}
$f3Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
if($Mode -in @('capture','motion','benchmark','benchmark-no-shadows','interactive')){
 $f3Args=@('--path',$f3Project,'--rendering-method',$Renderer,'--audio-driver','Dummy')
 if($Mode -notlike 'benchmark*'){$f3Args+=@('--fixed-fps','30')}
 $f3Args+=@('--',('--'+$Mode))
 & (Join-Path $PSScriptRoot 'queued-job.ps1') -Program $f3Godot -JobArguments $f3Args -Log $f3Out
} else {
 $f3Prior=$env:APPDATA
 try {
  $env:APPDATA=Join-Path $f3Root 'u'
  $f3Args=@('--headless','--path',$f3Project,'--audio-driver','Dummy','--fixed-fps','60')
  if($Mode -eq 'import'){$f3Args+=@('--editor','--import')}else{$f3Args+=@('--',('--'+$Mode))}
  $f3Start=Get-Date
  $f3Quoted=@($f3Args | ForEach-Object {'"'+$_+'"'})
  $f3Process=Start-Process -FilePath $f3Godot -ArgumentList $f3Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f3Out+'.stdout') -RedirectStandardError ($f3Out+'.stderr')
  $f3Process.WaitForExit()
  @(Get-Content -LiteralPath ($f3Out+'.stdout');Get-Content -LiteralPath ($f3Out+'.stderr')) | Set-Content -Encoding utf8 $f3Out
  @{program=$f3Godot;args=$f3Args;pid=$f3Process.Id;seconds=((Get-Date)-$f3Start).TotalSeconds;exit_code=$f3Process.ExitCode;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content ($f3Out+'.json')
  if($f3Process.ExitCode -ne 0 -or (Select-String -LiteralPath $f3Out -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)){throw ('F3 Godot failed: '+$f3Out)}
 }finally{$env:APPDATA=$f3Prior}
}
