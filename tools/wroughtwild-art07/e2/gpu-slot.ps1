param([Parameter(Mandatory)][string]$Program,
  [Parameter(Mandatory)][string[]]$JobArguments,
  [Parameter(Mandatory)][string]$Log)
$ErrorActionPreference='Stop'
$e2Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/e2'))
$e2Log=[IO.Path]::GetFullPath($Log)
if (-not $e2Log.StartsWith($e2Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Log must remain in E2 build.' }
if (Test-Path -LiteralPath $e2Log) { throw 'Use a fresh log.' }
$e2Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$e2Owns=$false
$e2PriorApp=$env:APPDATA
$e2PriorBlender=$env:BLENDER_USER_RESOURCES
try {
  $e2NeedsGpu = -not ($JobArguments -contains '--headless')
  if ($e2NeedsGpu) {
    $e2Owns=$e2Mutex.WaitOne(0)
    if (-not $e2Owns) { throw 'ART-07 GPU slot busy; continue CPU work.' }
  }
  $e2Benchmark=$JobArguments -contains '--benchmark'
  $e2Busy=Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match '^(blender|godot.*|trellis.*)\.exe$' -and
    ($e2Benchmark -or -not ($_.Name -match '^godot' -and $_.CommandLine -match '(?:^|[\s"])--headless(?:[\s"]|$)'))
  }
  if ($e2NeedsGpu -and $e2Busy) { throw ('Existing GPU art/game process; defer: '+($e2Busy.ProcessId -join ',')) }
  $env:APPDATA=Join-Path $e2Root 'u'
  $env:BLENDER_USER_RESOURCES=Join-Path (Split-Path $e2Log) 'blender-user'
  $e2Start=Get-Date
  # Start-Process receives a Windows argument string; quote each literal argument.
  $e2Quoted=@($JobArguments | ForEach-Object {
    $e2Arg=[regex]::Replace($_,'(\\*)"','$1$1\"')
    '"'+[regex]::Replace($e2Arg,'(\\+)$','$1$1')+'"'
  })
  $e2Process=Start-Process -FilePath $Program -ArgumentList $e2Quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput ($e2Log+'.stdout') -RedirectStandardError ($e2Log+'.stderr')
  while (-not $e2Process.WaitForExit(1000)) {
    if ((Test-Path -LiteralPath ($e2Log+'.stderr')) -and (Select-String -LiteralPath ($e2Log+'.stderr') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet)) {
      # Stop only the child launched above, after its own fatal log. Never a name.
      Stop-Process -Id $e2Process.Id -ErrorAction SilentlyContinue
      $e2Process.WaitForExit()
      break
    }
  }
  $e2Code=$e2Process.ExitCode
  @(Get-Content -LiteralPath ($e2Log+'.stdout');Get-Content -LiteralPath ($e2Log+'.stderr')) | Set-Content -Encoding utf8 $e2Log
  @{program=$Program;arguments=$JobArguments;started=$e2Start.ToString('o');seconds=((Get-Date)-$e2Start).TotalSeconds;exit_code=$e2Code;wrapper_pid=$PID;child_pid=$e2Process.Id;appdata=$env:APPDATA} | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 ($e2Log+'.json')
  if ($e2Code -ne 0) { throw "E2 GPU job failed ($e2Code): $e2Log" }
  if (Select-String -LiteralPath $e2Log -Pattern '^(SCRIPT ERROR|ERROR): (?!Condition .*certs\.size\(\) == 0)' -Quiet) { throw "E2 job logged an engine error despite exit zero: $e2Log" }
} finally {
  $env:APPDATA=$e2PriorApp
  $env:BLENDER_USER_RESOURCES=$e2PriorBlender
  if ($e2Owns) { $e2Mutex.ReleaseMutex() }
  $e2Mutex.Dispose()
}
