param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log,[string]$StateDirectory='')
$ErrorActionPreference='Stop'
$g1Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/g1'))
$g1Log=[IO.Path]::GetFullPath($Log)
if (-not $g1Log.StartsWith($g1Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in G1 build.' }
if (Test-Path -LiteralPath $g1Log) { throw 'Use a fresh log.' }
$g1Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$g1Owns=$false
$g1PriorApp=$env:APPDATA
$g1PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $g1NeedsGpu = -not ($JobArguments -contains '--headless')
  if ($g1NeedsGpu) {
    $g1Owns=$g1Mutex.WaitOne(0)
    if (-not $g1Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  }
  $g1Benchmark=$JobArguments -contains '--benchmark'
  $g1Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match $(if($g1Benchmark){'^(blender|godot.*|trellis.*|cc1plus|g\+\+|cmake|mingw32-make)\.exe$'}else{'^(blender|godot.*|trellis.*)\.exe$'}) -and
    ($g1Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($g1NeedsGpu -and $g1Busy) { throw ('Existing GPU art/game process; defer: '+($g1Busy.ProcessId -join ',')) }
  $g1State=if($StateDirectory){[IO.Path]::GetFullPath($StateDirectory)}else{Join-Path $g1Root 'u'}
  if(-not $g1State.StartsWith($g1Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'State must remain in G1 build.'}
  $env:APPDATA=$g1State
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $g1Log) 'blender-user'
  $g1Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $g1Quoted=@($JobArguments | ForEach-Object {
    $g1Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($g1Arg,'(\\+)$','$1$1')+'"'
  })
  $g1Process=Start-Process -FilePath $Program -ArgumentList $g1Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($g1Log+'.stdout') -RedirectStandardError ($g1Log+'.stderr')
  $g1CompetingIds=@()
  while (-not $g1Process.WaitForExit(1000)) {
    if($g1Benchmark){
      $g1CompetingIds+=@(Get-CimInstance Win32_Process | Where-Object {$_.ProcessId -ne $g1Process.Id -and $_.Name -match '^(blender|godot.*|trellis.*|cc1plus|g\+\+|cmake|mingw32-make)\.exe$'} | Select-Object -ExpandProperty ProcessId)
    }
    if ((Test-Path -LiteralPath ($g1Log+'.stderr')) -and (Select-String -LiteralPath ($g1Log+'.stderr') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)) {
      # Stop only the child launched above, after its own fatal log. Never a name.
      Stop-Process -Id $g1Process.Id -ErrorAction SilentlyContinue
      $g1Process.WaitForExit()
      break
    }
  }
  $g1Code=$g1Process.ExitCode
  @(Get-Content -LiteralPath ($g1Log+'.stdout');Get-Content -LiteralPath ($g1Log+'.stderr')) | Set-Content -Encoding utf8 $g1Log
  @{program=$Program;arguments=$JobArguments;started=$g1Start.ToString('o');seconds=((Get-Date)-$g1Start).TotalSeconds;exit_code=$g1Code;wrapper_pid=$PID;child_pid=$g1Process.Id;appdata=$env:APPDATA;competing_benchmark_processes=@($g1CompetingIds|Select-Object -Unique)} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($g1Log+'.json')
  if ($g1Code -ne 0) { throw "G1 GPU job failed ($g1Code): $g1Log" }
  if($g1CompetingIds.Count){throw "Benchmark overlapped another worker; retain log and use a fresh run: $g1Log"}
  if (Select-String -LiteralPath $g1Log -Pattern '^(SCRIPT ERROR|ERROR): (?!Condition .*certs\.size\(\) == 0)' -Quiet) { throw "G1 job logged an engine error despite exit zero: $g1Log" }
} finally {
  $env:APPDATA=$g1PriorApp
  $env:BLENDER_USER_RESOURCES=$g1PriorBlender
  if ($g1Owns) { $g1Mutex.ReleaseMutex() }
  $g1Mutex.Dispose()
}
