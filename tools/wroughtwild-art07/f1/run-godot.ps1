param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output,[string]$Mode='checks',[string]$Renderer='forward_plus')
$ErrorActionPreference='Stop'
$f1Project=[IO.Path]::GetFullPath($Project)
$f1Out=[IO.Path]::GetFullPath($Output)
$f1Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f1'))
foreach($f1Path in @($f1Project,$f1Out)){if(-not $f1Path.StartsWith($f1Root+[IO.Path]::DirectorySeparatorChar)){throw 'F1 path boundary'}}
if(Test-Path -LiteralPath $f1Out){throw 'Use a fresh run log'}
$f1Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
if($Mode -in @('capture','motion','benchmark','benchmark-no-shadows','interactive')){
 $f1Args=@('--path',$f1Project,'--rendering-method',$Renderer,'--audio-driver','Dummy')
 if($Mode -notlike 'benchmark*'){$f1Args+=@('--fixed-fps','30')}
 $f1Args+=@('--',('--'+$Mode))
 & (Join-Path $PSScriptRoot 'queued-job.ps1') -Program $f1Godot -JobArguments $f1Args -Log $f1Out
} else {
 $f1Prior=$env:APPDATA
 try {
  $env:APPDATA=Join-Path $f1Root 'u'
  $f1Args=@('--headless','--path',$f1Project,'--audio-driver','Dummy','--fixed-fps','60')
  if($Mode -eq 'import'){$f1Args+=@('--editor','--import')}else{$f1Args+=@('--',('--'+$Mode))}
  $f1Start=Get-Date
  $f1Quoted=@($f1Args | ForEach-Object {'"'+$_+'"'})
  $f1Process=Start-Process -FilePath $f1Godot -ArgumentList $f1Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f1Out+'.stdout') -RedirectStandardError ($f1Out+'.stderr')
  $f1Process.WaitForExit()
  @(Get-Content -LiteralPath ($f1Out+'.stdout');Get-Content -LiteralPath ($f1Out+'.stderr')) | Set-Content -Encoding utf8 $f1Out
  @{program=$f1Godot;args=$f1Args;pid=$f1Process.Id;seconds=((Get-Date)-$f1Start).TotalSeconds;exit_code=$f1Process.ExitCode;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content ($f1Out+'.json')
  if($f1Process.ExitCode -ne 0 -or (Select-String -LiteralPath $f1Out -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)){throw ('F1 Godot failed: '+$f1Out)}
 }finally{$env:APPDATA=$f1Prior}
}
