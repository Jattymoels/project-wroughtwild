param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$f2Build=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f2'))
$f2Out=[IO.Path]::GetFullPath($Output)
$f2Project=[IO.Path]::GetFullPath($Project)
foreach($f2Path in @($f2Out,$f2Project)) { if(-not $f2Path.StartsWith($f2Build+[IO.Path]::DirectorySeparatorChar)){throw 'Output/project outside F2 build'} }
if(Test-Path -LiteralPath $f2Out){throw 'Fresh native review output required'}
New-Item -ItemType Directory -Path $f2Out | Out-Null
$f2Prior=$env:APPDATA
$f2Commands=@()
try {
  $env:APPDATA=Join-Path $f2Build 'nu'
  $f2Jobs=@(
    @{name='import';args=@('--editor','--import')},
    @{name='placement';args=@('res://tests/placement_transactions.tscn')},
    @{name='restart';args=@('res://tests/placement_transactions.tscn','--','--placement-restore-only')},
    @{name='stations';args=@('res://tests/home_station_placement.tscn')},
    @{name='contraptions';args=@('res://tests/contraption_intensive.tscn')}
  )
  foreach($f2Job in $f2Jobs){
    $f2Args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$f2Project)+$f2Job.args
    $f2Quoted=@($f2Args | ForEach-Object { '"'+$_+'"' })
    $f2Log=Join-Path $f2Out $f2Job.name
    $f2Start=Get-Date
    $f2Process=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList $f2Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f2Log+'.log') -RedirectStandardError ($f2Log+'.err')
    $f2Process.WaitForExit()
    $f2Commands+=@{args=$f2Args;pid=$f2Process.Id;exit_code=$f2Process.ExitCode;seconds=((Get-Date)-$f2Start).TotalSeconds;appdata=$env:APPDATA;renderer='headless: no visual acceptance'}
    $f2Commands | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $f2Out 'commands.json')
    if($f2Process.ExitCode -ne 0){throw ('F2 native review failed: '+$f2Job.name)}
    Get-Content ($f2Log+'.log') | Select-Object -Last 4
  }
} finally {$env:APPDATA=$f2Prior}
