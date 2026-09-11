param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$f2Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f2'))
$f2Log=[IO.Path]::GetFullPath($Log)
if (-not $f2Log.StartsWith($f2Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in F2 build.' }
if (Test-Path -LiteralPath $f2Log) { throw 'Use a fresh log.' }
$f2Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$f2Owns=$false
$f2PriorApp=$env:APPDATA
$f2PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $f2Owns=$f2Mutex.WaitOne(0)
  if (-not $f2Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  $f2Benchmark=$JobArguments -contains '--benchmark'
  $f2Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($f2Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($f2Busy) { throw ('Existing GPU art/game process; defer: '+($f2Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $f2Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $f2Log) 'blender-user'
  $f2Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $f2Quoted=@($JobArguments | ForEach-Object {
    $f2Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($f2Arg,'(\\+)$','$1$1')+'"'
  })
  $f2Process=Start-Process -FilePath $Program -ArgumentList $f2Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f2Log+'.stdout') -RedirectStandardError ($f2Log+'.stderr')
  $f2Process.WaitForExit()
  $f2Code=$f2Process.ExitCode
  @(Get-Content -LiteralPath ($f2Log+'.stdout');Get-Content -LiteralPath ($f2Log+'.stderr')) | Set-Content -Encoding utf8 $f2Log
  @{program=$Program;arguments=$JobArguments;started=$f2Start.ToString('o');seconds=((Get-Date)-$f2Start).TotalSeconds;exit_code=$f2Code;wrapper_pid=$PID;child_pid=$f2Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($f2Log+'.json')
  if ($f2Code -ne 0) { throw "F2 GPU job failed ($f2Code): $f2Log" }
  if (Select-String -LiteralPath $f2Log -Pattern '^(SCRIPT ERROR|ERROR):|^Traceback \(most recent call last\)' -Quiet) { throw "F2 job logged an engine error despite exit zero: $f2Log" }
} finally {
  $env:APPDATA=$f2PriorApp
  $env:BLENDER_USER_RESOURCES=$f2PriorBlender
  if ($f2Owns) { $f2Mutex.ReleaseMutex() }
  $f2Mutex.Dispose()
}
