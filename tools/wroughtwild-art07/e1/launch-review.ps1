param([string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
 [ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$Visible)
$ErrorActionPreference='Stop'
$e1Package=$PSScriptRoot
$e1Manifest=Get-Content -LiteralPath (Join-Path $e1Package 'manifest.json') -Raw | ConvertFrom-Json
foreach($e1File in $e1Manifest.files){
 $e1Path=[IO.Path]::GetFullPath((Join-Path $e1Package $e1File.path))
 if(-not $e1Path.StartsWith($e1Package+[IO.Path]::DirectorySeparatorChar)){throw 'Invalid package path'}
 if((Get-FileHash -LiteralPath $e1Path).Hash.ToLowerInvariant() -ne $e1File.sha256){throw ('Package hash mismatch: '+$e1File.path)}
}
$e1Out=Join-Path $env:TEMP ('wroughtwild-e1-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $e1Out | Out-Null
Copy-Item -LiteralPath (Join-Path $e1Package 'review') -Destination $e1Out -Recurse
$e1Game=Join-Path $e1Out 'review/game'
$e1Prior=$env:APPDATA
$e1Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$e1Owns=$false
try{
 $e1Owns=$e1Mutex.WaitOne(0)
 if(-not $e1Owns){throw 'GPU slot busy; launch after the current job finishes'}
 $e1Busy=Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(blender|godot.*|trellis.*)\.exe$'}
 if($e1Busy){throw 'An existing art/game process is running; leave it intact and launch later'}
 $env:APPDATA=Join-Path $e1Out 'appdata'
 $e1Import=Start-Process -FilePath $Godot -ArgumentList @('--headless','--path',('"'+$e1Game+'"'),'--editor','--import') -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput (Join-Path $e1Out 'import.log') -RedirectStandardError (Join-Path $e1Out 'import.err')
 if($e1Import.ExitCode -ne 0){throw 'Fresh review import failed'}
 $e1Style=if($Visible){'Normal'}else{'Hidden'}
 $e1Child=Start-Process -FilePath $Godot -ArgumentList @('--path',('"'+$e1Game+'"'),'--rendering-method',$Renderer,'res://e1/review.tscn','--','--play') -WindowStyle $e1Style -PassThru -Wait -RedirectStandardOutput (Join-Path $e1Out 'review.log') -RedirectStandardError (Join-Path $e1Out 'review.err')
 Write-Output ('E1 isolated review exit '+$e1Child.ExitCode+'; evidence/save root '+$e1Out)
}finally{
 $env:APPDATA=$e1Prior
 if($e1Owns){$e1Mutex.ReleaseMutex()}
 $e1Mutex.Dispose()
}
