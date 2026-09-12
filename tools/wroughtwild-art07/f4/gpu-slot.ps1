param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$f4Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f4'))
$f4Log=[IO.Path]::GetFullPath($Log)
if (-not $f4Log.StartsWith($f4Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in F4 build.' }
if (Test-Path -LiteralPath $f4Log) { throw 'Use a fresh log.' }
$f4Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$f4Owns=$false
$f4PriorApp=$env:APPDATA
$f4PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $f4NeedsGpu = -not ($JobArguments -contains '--headless')
  if ($f4NeedsGpu) {
    $f4Owns=$f4Mutex.WaitOne(0)
    if (-not $f4Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  }
  $f4Benchmark=$JobArguments -contains '--benchmark'
  $f4Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match $(if($f4Benchmark){'^(blender|godot.*|trellis.*|cc1plus|g\+\+|cmake|mingw32-make)\.exe$'}else{'^(blender|godot.*|trellis.*)\.exe$'}) -and
    ($f4Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($f4NeedsGpu -and $f4Busy) { throw ('Existing GPU art/game process; defer: '+($f4Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $f4Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $f4Log) 'blender-user'
  $f4Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $f4Quoted=@($JobArguments | ForEach-Object {
    $f4Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($f4Arg,'(\\+)$','$1$1')+'"'
  })
  $f4Process=Start-Process -FilePath $Program -ArgumentList $f4Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($f4Log+'.stdout') -RedirectStandardError ($f4Log+'.stderr')
  $f4CompetingIds=@()
  while (-not $f4Process.WaitForExit(1000)) {
    if($f4Benchmark){
      $f4CompetingIds+=@(Get-CimInstance Win32_Process | Where-Object {$_.ProcessId -ne $f4Process.Id -and $_.Name -match '^(blender|godot.*|trellis.*|cc1plus|g\+\+|cmake|mingw32-make)\.exe$'} | Select-Object -ExpandProperty ProcessId)
    }
    if ((Test-Path -LiteralPath ($f4Log+'.stderr')) -and (Select-String -LiteralPath ($f4Log+'.stderr') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)) {
      # Stop only the child launched above, after its own fatal log. Never a name.
      Stop-Process -Id $f4Process.Id -ErrorAction SilentlyContinue
      $f4Process.WaitForExit()
      break
    }
  }
  $f4Code=$f4Process.ExitCode
  @(Get-Content -LiteralPath ($f4Log+'.stdout');Get-Content -LiteralPath ($f4Log+'.stderr')) | Set-Content -Encoding utf8 $f4Log
  @{program=$Program;arguments=$JobArguments;started=$f4Start.ToString('o');seconds=((Get-Date)-$f4Start).TotalSeconds;exit_code=$f4Code;wrapper_pid=$PID;child_pid=$f4Process.Id;appdata=$env:APPDATA;competing_benchmark_processes=@($f4CompetingIds|Select-Object -Unique)} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($f4Log+'.json')
  if ($f4Code -ne 0) { throw "F4 GPU job failed ($f4Code): $f4Log" }
  if($f4CompetingIds.Count){throw "Benchmark overlapped another worker; retain log and use a fresh run: $f4Log"}
  if (Select-String -LiteralPath $f4Log -Pattern '^(SCRIPT ERROR|ERROR): (?!Condition .*certs\.size\(\) == 0)' -Quiet) { throw "F4 job logged an engine error despite exit zero: $f4Log" }
} finally {
  $env:APPDATA=$f4PriorApp
  $env:BLENDER_USER_RESOURCES=$f4PriorBlender
  if ($f4Owns) { $f4Mutex.ReleaseMutex() }
  $f4Mutex.Dispose()
}
