param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$f1Build=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f1'))
$f1Out=[IO.Path]::GetFullPath($Output)
$f1Project=[IO.Path]::GetFullPath($Project)
foreach($f1Path in @($f1Out,$f1Project)) { if(-not $f1Path.StartsWith($f1Build+[IO.Path]::DirectorySeparatorChar)){throw 'Output/project outside F1 build'} }
if(Test-Path -LiteralPath $f1Out){throw 'Fresh native review output required'}
New-Item -ItemType Directory -Path $f1Out | Out-Null
$f1Prior=$env:APPDATA
$f1Commands=@()
try {
  $env:APPDATA=Join-Path $f1Build 'nu'
  $f1Jobs=@(
    @{name='import';args=@('--editor','--import')},
    @{name='placement';args=@('res://tests/placement_transactions.tscn')},
    @{name='restart';args=@('res://tests/placement_transactions.tscn','--','--placement-restore-only')},
    @{name='stations';args=@('res://tests/home_station_placement.tscn')},
    @{name='contraptions';args=@('res://tests/contraption_intensive.tscn')},
    @{name='strange';args=@('res://tests/strange_frontier.tscn')}
  )
  foreach($f1Job in $f1Jobs){
    $f1Args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$f1Project)+$f1Job.args
    $f1Quoted=@($f1Args | ForEach-Object { '"'+$_+'"' })
    $f1Log=Join-Path $f1Out $f1Job.name
    $f1Start=Get-Date
    $f1Process=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList $f1Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f1Log+'.log') -RedirectStandardError ($f1Log+'.err')
    $f1Process.WaitForExit()
    $f1Commands+=@{args=$f1Args;pid=$f1Process.Id;exit_code=$f1Process.ExitCode;seconds=((Get-Date)-$f1Start).TotalSeconds;appdata=$env:APPDATA;renderer='headless: no visual acceptance'}
    $f1Commands | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $f1Out 'commands.json')
    if($f1Process.ExitCode -ne 0){throw ('F1 native review failed: '+$f1Job.name)}
    Get-Content ($f1Log+'.log') | Select-Object -Last 4
  }
} finally {$env:APPDATA=$f1Prior}
