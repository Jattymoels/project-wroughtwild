param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$d6Build=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/d6'))
$d6Out=[IO.Path]::GetFullPath($Output)
$d6Project=[IO.Path]::GetFullPath($Project)
foreach($d6Path in @($d6Out,$d6Project)) { if(-not $d6Path.StartsWith($d6Build+[IO.Path]::DirectorySeparatorChar)){throw 'Output/project outside D6 build'} }
if(Test-Path -LiteralPath $d6Out){throw 'Fresh native review output required'}
New-Item -ItemType Directory -Path $d6Out | Out-Null
$d6Prior=$env:APPDATA
$d6Commands=@()
try {
  $env:APPDATA=Join-Path $d6Build 'nu'
  $d6Jobs=@(
    @{name='import';args=@('--editor','--import')},
    @{name='placement';args=@('res://tests/placement_transactions.tscn')},
    @{name='restart';args=@('res://tests/placement_transactions.tscn','--','--placement-restore-only')},
    @{name='stations';args=@('res://tests/home_station_placement.tscn')}
  )
  foreach($d6Job in $d6Jobs){
    $d6Args=@('--headless','--audio-driver','Dummy','--fixed-fps','60','--path',$d6Project)+$d6Job.args
    $d6Quoted=@($d6Args | ForEach-Object { '"'+$_+'"' })
    $d6Log=Join-Path $d6Out $d6Job.name
    $d6Start=Get-Date
    $d6Process=Start-Process -FilePath 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -ArgumentList $d6Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($d6Log+'.log') -RedirectStandardError ($d6Log+'.err')
    $d6Process.WaitForExit()
    $d6Commands+=@{args=$d6Args;pid=$d6Process.Id;exit_code=$d6Process.ExitCode;seconds=((Get-Date)-$d6Start).TotalSeconds;appdata=$env:APPDATA;renderer='headless: no visual acceptance'}
    $d6Commands | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $d6Out 'commands.json')
    if($d6Process.ExitCode -ne 0){throw ('D6 native review failed: '+$d6Job.name)}
    Get-Content ($d6Log+'.log') | Select-Object -Last 4
  }
} finally {$env:APPDATA=$d6Prior}
