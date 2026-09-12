param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$e1Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/e1'))
$e1Log=[IO.Path]::GetFullPath($Log)
if (-not $e1Log.StartsWith($e1Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in E1 build.' }
if (Test-Path -LiteralPath $e1Log) { throw 'Use a fresh log.' }
$e1Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$e1Owns=$false
$e1PriorApp=$env:APPDATA
$e1PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $e1NeedsGpu = -not ($JobArguments -contains '--headless')
  if ($e1NeedsGpu) {
    $e1Owns=$e1Mutex.WaitOne(0)
    if (-not $e1Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  }
  $e1Benchmark=$JobArguments -contains '--benchmark'
  $e1Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($e1Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($e1NeedsGpu -and $e1Busy) { throw ('Existing GPU art/game process; defer: '+($e1Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $e1Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $e1Log) 'blender-user'
  $e1Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $e1Quoted=@($JobArguments | ForEach-Object {
    $e1Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($e1Arg,'(\\+)$','$1$1')+'"'
  })
  $e1Process=Start-Process -FilePath $Program -ArgumentList $e1Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($e1Log+'.stdout') -RedirectStandardError ($e1Log+'.stderr')
  while (-not $e1Process.WaitForExit(1000)) {
    if ((Test-Path -LiteralPath ($e1Log+'.stderr')) -and (Select-String -LiteralPath ($e1Log+'.stderr') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)) {
      # Stop only the child launched above, after its own fatal log. Never a name.
      Stop-Process -Id $e1Process.Id -ErrorAction SilentlyContinue
      $e1Process.WaitForExit()
      break
    }
  }
  $e1Code=$e1Process.ExitCode
  @(Get-Content -LiteralPath ($e1Log+'.stdout');Get-Content -LiteralPath ($e1Log+'.stderr')) | Set-Content -Encoding utf8 $e1Log
  @{program=$Program;arguments=$JobArguments;started=$e1Start.ToString('o');seconds=((Get-Date)-$e1Start).TotalSeconds;exit_code=$e1Code;wrapper_pid=$PID;child_pid=$e1Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($e1Log+'.json')
  if ($e1Code -ne 0) { throw "E1 GPU job failed ($e1Code): $e1Log" }
  if (Select-String -LiteralPath $e1Log -Pattern '^(SCRIPT ERROR|ERROR): (?!Condition .*certs\.size\(\) == 0)' -Quiet) { throw "E1 job logged an engine error despite exit zero: $e1Log" }
} finally {
  $env:APPDATA=$e1PriorApp
  $env:BLENDER_USER_RESOURCES=$e1PriorBlender
  if ($e1Owns) { $e1Mutex.ReleaseMutex() }
  $e1Mutex.Dispose()
}
