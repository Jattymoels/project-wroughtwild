param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$f3Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f3'))
$f3Log=[IO.Path]::GetFullPath($Log)
if (-not $f3Log.StartsWith($f3Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in F3 build.' }
if (Test-Path -LiteralPath $f3Log) { throw 'Use a fresh log.' }
$f3Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$f3Owns=$false
$f3PriorApp=$env:APPDATA
$f3PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $f3Owns=$f3Mutex.WaitOne(0)
  if (-not $f3Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  $f3Benchmark=($JobArguments -contains '--benchmark') -or ($JobArguments -contains '--benchmark-no-shadows')
  $f3Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($f3Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($f3Busy) { throw ('Existing GPU art/game process; defer: '+($f3Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $f3Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $f3Log) 'blender-user'
  $f3Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $f3Quoted=@($JobArguments | ForEach-Object {
    $f3Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($f3Arg,'(\\+)$','$1$1')+'"'
  })
  $f3Process=Start-Process -FilePath $Program -ArgumentList $f3Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f3Log+'.stdout') -RedirectStandardError ($f3Log+'.stderr')
  $f3Process.WaitForExit()
  $f3Code=$f3Process.ExitCode
  @(Get-Content -LiteralPath ($f3Log+'.stdout');Get-Content -LiteralPath ($f3Log+'.stderr')) | Set-Content -Encoding utf8 $f3Log
  @{program=$Program;arguments=$JobArguments;started=$f3Start.ToString('o');seconds=((Get-Date)-$f3Start).TotalSeconds;exit_code=$f3Code;wrapper_pid=$PID;child_pid=$f3Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($f3Log+'.json')
  if ($f3Code -ne 0) { throw "F3 GPU job failed ($f3Code): $f3Log" }
  if (Select-String -LiteralPath $f3Log -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet) { throw "F3 job logged an engine error despite exit zero: $f3Log" }
} finally {
  $env:APPDATA=$f3PriorApp
  $env:BLENDER_USER_RESOURCES=$f3PriorBlender
  if ($f3Owns) { $f3Mutex.ReleaseMutex() }
  $f3Mutex.Dispose()
}
