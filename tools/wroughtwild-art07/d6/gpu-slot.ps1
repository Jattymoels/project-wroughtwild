param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$d6Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/d6'))
$d6Log=[IO.Path]::GetFullPath($Log)
if (-not $d6Log.StartsWith($d6Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in D6 build.' }
if (Test-Path -LiteralPath $d6Log) { throw 'Use a fresh log.' }
$d6Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$d6Owns=$false
$d6PriorApp=$env:APPDATA
$d6PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $d6Owns=$d6Mutex.WaitOne(0)
  if (-not $d6Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  $d6Benchmark=$JobArguments -contains '--benchmark'
  $d6Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($d6Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($d6Busy) { throw ('Existing GPU art/game process; defer: '+($d6Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $d6Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $d6Log) 'blender-user'
  $d6Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $d6Quoted=@($JobArguments | ForEach-Object {
    $d6Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($d6Arg,'(\\+)$','$1$1')+'"'
  })
  $d6Process=Start-Process -FilePath $Program -ArgumentList $d6Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($d6Log+'.stdout') -RedirectStandardError ($d6Log+'.stderr')
  $d6Process.WaitForExit()
  $d6Code=$d6Process.ExitCode
  @(Get-Content -LiteralPath ($d6Log+'.stdout');Get-Content -LiteralPath ($d6Log+'.stderr')) | Set-Content -Encoding utf8 $d6Log
  @{program=$Program;arguments=$JobArguments;started=$d6Start.ToString('o');seconds=((Get-Date)-$d6Start).TotalSeconds;exit_code=$d6Code;wrapper_pid=$PID;child_pid=$d6Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($d6Log+'.json')
  if ($d6Code -ne 0) { throw "D6 GPU job failed ($d6Code): $d6Log" }
  if (Select-String -LiteralPath $d6Log -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet) { throw "D6 job logged an engine error despite exit zero: $d6Log" }
} finally {
  $env:APPDATA=$d6PriorApp
  $env:BLENDER_USER_RESOURCES=$d6PriorBlender
  if ($d6Owns) { $d6Mutex.ReleaseMutex() }
  $d6Mutex.Dispose()
}
