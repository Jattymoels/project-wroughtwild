param([Parameter(Mandatory)][string]$Game,[Parameter(Mandatory)][string]$Logs)
$ErrorActionPreference='Stop'
$d5Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/d5'))
$d5Game=[IO.Path]::GetFullPath($Game)
$d5Logs=[IO.Path]::GetFullPath($Logs)
foreach($d5Path in @($d5Game,$d5Logs)) {if(-not $d5Path.StartsWith($d5Root+[IO.Path]::DirectorySeparatorChar)){throw 'Native checks must remain in D5 build'}}
if(Test-Path -LiteralPath $d5Logs){throw 'Fresh logs required'}
New-Item -ItemType Directory -Path $d5Logs | Out-Null
$d5Prior=$env:APPDATA
try {
 $env:APPDATA=Join-Path $d5Root 'native-user'
 $d5Jobs=@(
  @{name='import';args=@('--headless','--editor','--import')},
  @{name='material';args=@('--headless','--audio-driver','Dummy','res://tests/material_intensive.tscn')},
  @{name='placement';args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','res://tests/placement_transactions.tscn')},
  @{name='restart';args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','res://tests/placement_transactions.tscn','--','--placement-restore-only')}
 )
 foreach($d5Job in $d5Jobs){
  $d5Args=@('--path',$d5Game)+$d5Job.args
  $d5Log=Join-Path $d5Logs $d5Job.name
  $d5Start=Get-Date
  $d5Proc=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList ($d5Args | ForEach-Object {'"'+$_+'"'}) -WindowStyle Hidden -PassThru -RedirectStandardOutput ($d5Log+'.stdout') -RedirectStandardError ($d5Log+'.stderr')
  $d5Proc.WaitForExit()
  @{arguments=$d5Args;exit_code=$d5Proc.ExitCode;seconds=((Get-Date)-$d5Start).TotalSeconds;pid=$d5Proc.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 ($d5Log+'.json')
  if($d5Proc.ExitCode -ne 0){throw ('Native game check failed: '+$d5Job.name)}
 }
 Write-Output 'D5_NATIVE_GAME_CHECKS_OK'
} finally {$env:APPDATA=$d5Prior}
