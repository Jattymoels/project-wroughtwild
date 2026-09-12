param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$f1Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f1'))
$f1Log=[IO.Path]::GetFullPath($Log)
if (-not $f1Log.StartsWith($f1Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in F1 build.' }
if (Test-Path -LiteralPath $f1Log) { throw 'Use a fresh log.' }
$f1Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$f1Owns=$false
$f1PriorApp=$env:APPDATA
$f1PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $f1Owns=$f1Mutex.WaitOne(0)
  if (-not $f1Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  $f1Benchmark=($JobArguments -contains '--benchmark') -or ($JobArguments -contains '--benchmark-no-shadows')
  $f1Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($f1Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($f1Busy) { throw ('Existing GPU art/game process; defer: '+($f1Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $f1Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $f1Log) 'blender-user'
  $f1Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $f1Quoted=@($JobArguments | ForEach-Object {
    $f1Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($f1Arg,'(\\+)$','$1$1')+'"'
  })
  $f1Process=Start-Process -FilePath $Program -ArgumentList $f1Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f1Log+'.stdout') -RedirectStandardError ($f1Log+'.stderr')
  $f1Process.WaitForExit()
  $f1Code=$f1Process.ExitCode
  @(Get-Content -LiteralPath ($f1Log+'.stdout');Get-Content -LiteralPath ($f1Log+'.stderr')) | Set-Content -Encoding utf8 $f1Log
  @{program=$Program;arguments=$JobArguments;started=$f1Start.ToString('o');seconds=((Get-Date)-$f1Start).TotalSeconds;exit_code=$f1Code;wrapper_pid=$PID;child_pid=$f1Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($f1Log+'.json')
  if ($f1Code -ne 0) { throw "F1 GPU job failed ($f1Code): $f1Log" }
  if (Select-String -LiteralPath $f1Log -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet) { throw "F1 job logged an engine error despite exit zero: $f1Log" }
} finally {
  $env:APPDATA=$f1PriorApp
  $env:BLENDER_USER_RESOURCES=$f1PriorBlender
  if ($f1Owns) { $f1Mutex.ReleaseMutex() }
  $f1Mutex.Dispose()
}
