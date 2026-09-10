param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$d5Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/d5'))
$d5Log=[IO.Path]::GetFullPath($Log)
if (-not $d5Log.StartsWith($d5Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in D5 build.' }
if (Test-Path -LiteralPath $d5Log) { throw 'Use a fresh log.' }
$d5Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d5Owns=$false
$d5PriorApp=$env:APPDATA
$d5PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $d5Owns=$d5Mutex.WaitOne(0)
  if (-not $d5Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  $d5Benchmark=$JobArguments -contains '--benchmark'
  $d5Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($d5Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($d5Busy) { throw ('Existing GPU art/game process; defer: '+($d5Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $d5Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $d5Log) 'blender-user'
  $d5Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $d5Quoted=@($JobArguments | ForEach-Object {
    $d5Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($d5Arg,'(\\+)$','$1$1')+'"'
  })
  $d5Process=Start-Process -FilePath $Program -ArgumentList $d5Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($d5Log+'.stdout') -RedirectStandardError ($d5Log+'.stderr')
  $d5Process.WaitForExit()
  $d5Code=$d5Process.ExitCode
  @(Get-Content -LiteralPath ($d5Log+'.stdout');Get-Content -LiteralPath ($d5Log+'.stderr')) | Set-Content -Encoding utf8 $d5Log
  @{program=$Program;arguments=$JobArguments;started=$d5Start.ToString('o');seconds=((Get-Date)-$d5Start).TotalSeconds;exit_code=$d5Code;wrapper_pid=$PID;child_pid=$d5Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($d5Log+'.json')
  if ($d5Code -ne 0) { throw "D5 GPU job failed ($d5Code): $d5Log" }
} finally {
  $env:APPDATA=$d5PriorApp
  $env:BLENDER_USER_RESOURCES=$d5PriorBlender
  if ($d5Owns) { $d5Mutex.ReleaseMutex() }
  $d5Mutex.Dispose()
}
