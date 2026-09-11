param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$f3Build=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f3'))
$f3Out=[IO.Path]::GetFullPath($Output)
$f3Project=[IO.Path]::GetFullPath($Project)
foreach($f3Path in @($f3Out,$f3Project)) { if(-not $f3Path.StartsWith($f3Build+[IO.Path]::DirectorySeparatorChar)){throw 'Output/project outside F3 build'} }
if(Test-Path -LiteralPath $f3Out){throw 'Fresh native review output required'}
New-Item -ItemType Directory -Path $f3Out | Out-Null
$f3Prior=$env:APPDATA
$f3Commands=@()
try {
  $env:APPDATA=Join-Path $f3Build 'nu'
  $f3Jobs=@(
    @{name='import';args=@('--editor','--import')},
    @{name='placement';args=@('res://tests/placement_transactions.tscn')},
    @{name='restart';args=@('res://tests/placement_transactions.tscn','--','--placement-restore-only')},
    @{name='stations';args=@('res://tests/home_station_placement.tscn')},
    @{name='contraptions';args=@('res://tests/contraption_intensive.tscn')},
    @{name='strange';args=@('res://tests/strange_frontier.tscn')}
  )
  foreach($f3Job in $f3Jobs){
    $f3Args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$f3Project)+$f3Job.args
    $f3Quoted=@($f3Args | ForEach-Object { '"'+$_+'"' })
    $f3Log=Join-Path $f3Out $f3Job.name
    $f3Start=Get-Date
    $f3Process=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList $f3Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f3Log+'.log') -RedirectStandardError ($f3Log+'.err')
    $f3Process.WaitForExit()
    $f3Commands+=@{args=$f3Args;pid=$f3Process.Id;exit_code=$f3Process.ExitCode;seconds=((Get-Date)-$f3Start).TotalSeconds;appdata=$env:APPDATA;renderer='headless: no visual acceptance'}
    $f3Commands | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $f3Out 'commands.json')
    if($f3Process.ExitCode -ne 0){throw ('F3 native review failed: '+$f3Job.name)}
    Get-Content ($f3Log+'.log') | Select-Object -Last 4
  }
} finally {$env:APPDATA=$f3Prior}
