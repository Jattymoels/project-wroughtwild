param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$CopyTo,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$Visible)
$ErrorActionPreference='Stop'
$c6Package=(Resolve-Path -LiteralPath $Package).Path
$c6Copy=[IO.Path]::GetFullPath($CopyTo)
if(Test-Path -LiteralPath $c6Copy){throw 'Use a fresh copy directory.'}
if($c6Copy.StartsWith($c6Package+[IO.Path]::DirectorySeparatorChar)){throw 'A review copy must be outside the immutable package.'}
$c6Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $c6Python "$PSScriptRoot/verify_package.py" $c6Package $c6Copy
if($LASTEXITCODE -ne 0){throw 'Package verification failed.'}
$c6PreviousApp=$env:APPDATA;$c6PreviousLocal=$env:LOCALAPPDATA
$c6Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$c6Owns=$false
try{
 $env:APPDATA=Join-Path $c6Copy 'isolated-user';$env:LOCALAPPDATA=Join-Path $c6Copy 'isolated-local-user'
 New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 $c6Game=Join-Path $c6Copy 'native/game'
 & C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe --headless --editor --path $c6Game --import
 if($LASTEXITCODE -ne 0){throw 'Fresh import failed.'}
 $c6Owns=$c6Mutex.WaitOne(0);if(-not $c6Owns){throw 'Shared GPU slot busy. Retry this launcher with a fresh copy after the active job completes.'}
 $c6Processes=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%blender%' OR Name LIKE '%Godot%' OR Name LIKE '%trellis%'" | Select-Object ProcessId,ParentProcessId,Name,CommandLine,WorkingSetSize)
 foreach($c6Other in $c6Processes){
  if($c6Other.Name -match 'blender|trellis'){throw 'Existing renderer/generator; no process changed.'}
  if($c6Other.CommandLine -match '--headless'){continue}
  $c6Parent=$c6Processes | Where-Object {$_.ProcessId -eq $c6Other.ParentProcessId}
  if(-not $c6Other.CommandLine -and $c6Other.WorkingSetSize -lt 1048576 -and $c6Parent.CommandLine -match '--headless'){continue}
  throw 'Existing renderer or unclassified engine process; no process changed.'
 }
 $c6Args=@('--path',$c6Game,'--rendering-method',$Renderer,'--resolution','1440x900','res://c6/native_review.tscn','--','--weathered-look','--c6-mode=review')
 if(-not $Visible){$c6Args=@('--position','-16000,-16000')+$c6Args}
 $c6Quoted=($c6Args | ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' '
 $c6Style=if($Visible){'Normal'}else{'Hidden'}
 $c6Process=Start-Process C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe -ArgumentList $c6Quoted -WindowStyle $c6Style -PassThru
 Write-Output "C6 review PID $($c6Process.Id); close this review to release its GPU slot."
 $c6Process.WaitForExit()
}finally{$env:APPDATA=$c6PreviousApp;$env:LOCALAPPDATA=$c6PreviousLocal;if($c6Owns){$c6Mutex.ReleaseMutex()};$c6Mutex.Dispose()}
