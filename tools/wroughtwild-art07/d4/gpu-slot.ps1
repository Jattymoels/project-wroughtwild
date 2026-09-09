param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$d4Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/d4'))
$d4Log=[IO.Path]::GetFullPath($Log)
if (-not $d4Log.StartsWith($d4Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in D4 build.' }
if (Test-Path -LiteralPath $d4Log) { throw 'Use a fresh log.' }
$d4Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d4Owns=$false
$d4PriorApp=$env:APPDATA
$d4PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $d4Owns=$d4Mutex.WaitOne(0)
  if (-not $d4Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  $d4Benchmark=$JobArguments -contains '--benchmark'
  $d4Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($d4Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($d4Busy) { throw ('Existing GPU art/game process; defer: '+($d4Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $d4Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $d4Log) 'blender-user'
  $d4Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $d4Quoted=@($JobArguments | ForEach-Object {
    $d4Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($d4Arg,'(\\+)$','$1$1')+'"'
  })
  $d4Process=Start-Process -FilePath $Program -ArgumentList $d4Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($d4Log+'.stdout') -RedirectStandardError ($d4Log+'.stderr')
  $d4Process.WaitForExit()
  $d4Code=$d4Process.ExitCode
  @(Get-Content -LiteralPath ($d4Log+'.stdout');Get-Content -LiteralPath ($d4Log+'.stderr')) | Set-Content -Encoding utf8 $d4Log
  @{program=$Program;arguments=$JobArguments;started=$d4Start.ToString('o');seconds=((Get-Date)-$d4Start).TotalSeconds;exit_code=$d4Code;wrapper_pid=$PID;child_pid=$d4Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($d4Log+'.json')
  if ($d4Code -ne 0) { throw "D4 GPU job failed ($d4Code): $d4Log" }
} finally {
  $env:APPDATA=$d4PriorApp
  $env:BLENDER_USER_RESOURCES=$d4PriorBlender
  if ($d4Owns) { $d4Mutex.ReleaseMutex() }
  $d4Mutex.Dispose()
}
