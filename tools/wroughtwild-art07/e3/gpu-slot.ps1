param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$e3Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/e3'))
$e3Log=[IO.Path]::GetFullPath($Log)
if (-not $e3Log.StartsWith($e3Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in E3 build.' }
if (Test-Path -LiteralPath $e3Log) { throw 'Use a fresh log.' }
$e3Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$e3Owns=$false
$e3PriorApp=$env:APPDATA
$e3PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $e3NeedsGpu = -not ($JobArguments -contains '--headless')
  if ($e3NeedsGpu) {
    $e3Owns=$e3Mutex.WaitOne(0)
    if (-not $e3Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  }
  $e3Benchmark=$JobArguments -contains '--benchmark'
  $e3Busy=Get-CimInstance Win32_Process | Where-Object {
    ($_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -or ($e3Benchmark -and $_.Name -match '^(g\+\+|cc1plus)\.exe$')) -and
    ($e3Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($e3NeedsGpu -and $e3Busy) { throw ('Existing GPU art/game process; defer: '+($e3Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $e3Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $e3Log) 'blender-user'
  $e3Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $e3Quoted=@($JobArguments | ForEach-Object {
    $e3Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($e3Arg,'(\\+)$','$1$1')+'"'
  })
  $e3Process=Start-Process -FilePath $Program -ArgumentList $e3Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($e3Log+'.stdout') -RedirectStandardError ($e3Log+'.stderr')
  $e3During=@()
  while (-not $e3Process.WaitForExit(1000)) {
    if ($e3Benchmark) {
      $e3During+=@(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^(blender|godot.*|trellis.*|g\+\+|cc1plus)\.exe$' -and
        $_.ProcessId -ne $e3Process.Id -and $_.ParentProcessId -ne $e3Process.Id
      } | Select-Object ProcessId,ParentProcessId,Name,CreationDate,CommandLine)
    }
    if ((Test-Path -LiteralPath ($e3Log+'.stderr')) -and (Select-String -LiteralPath ($e3Log+'.stderr') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)) {
      # Stop only the child launched above, after its own fatal log. Never a name.
      Stop-Process -Id $e3Process.Id -ErrorAction SilentlyContinue
      $e3Process.WaitForExit()
      break
    }
  }
  $e3Code=$e3Process.ExitCode
  @(Get-Content -LiteralPath ($e3Log+'.stdout');Get-Content -LiteralPath ($e3Log+'.stderr')) | Set-Content -Encoding utf8 $e3Log
  @{program=$Program;arguments=$JobArguments;started=$e3Start.ToString('o');seconds=((Get-Date)-$e3Start).TotalSeconds;exit_code=$e3Code;wrapper_pid=$PID;child_pid=$e3Process.Id;appdata=$env:APPDATA;gpu_mutex=$e3Owns;competing_processes_at_start=@($e3Busy | Select-Object ProcessId,Name,CommandLine);benchmark_competitors_observed=$e3During} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($e3Log+'.json')
  if ($e3During.Count) { throw 'Benchmark overlapped another art/game/compiler process; retain as diagnostic only.' }
  if ($e3Code -ne 0) { throw "E3 GPU job failed ($e3Code): $e3Log" }
  if (Select-String -LiteralPath $e3Log -Pattern '^(SCRIPT ERROR|ERROR): (?!Condition .*certs\.size\(\) == 0)' -Quiet) { throw "E3 job logged an engine error despite exit zero: $e3Log" }
} finally {
  $env:APPDATA=$e3PriorApp
  $env:BLENDER_USER_RESOURCES=$e3PriorBlender
  if ($e3Owns) { $e3Mutex.ReleaseMutex() }
  $e3Mutex.Dispose()
}
