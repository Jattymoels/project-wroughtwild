param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$CopyTo,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[ValidateSet('review','capture','walk','motion','benchmark')][string]$Mode='review',[switch]$Visible,[string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')
$ErrorActionPreference='Stop'
$c3Package=(Resolve-Path -LiteralPath $Package).Path
$c3Copy=[IO.Path]::GetFullPath($CopyTo)
if(Test-Path -LiteralPath $c3Copy){throw 'Use a fresh copy directory; canonical package is immutable.'}
$c3Manifest=Get-Content -Raw -LiteralPath (Join-Path $c3Package 'manifest.json') | ConvertFrom-Json -AsHashtable
function Test-C3Hashes([string]$Folder){
 foreach($rel in $c3Manifest.Keys){
  $p=[IO.Path]::GetFullPath((Join-Path $Folder $rel))
  if(-not $p.StartsWith($Folder+[IO.Path]::DirectorySeparatorChar)){throw 'Manifest path escapes package.'}
  if((Get-Item -LiteralPath $p).Length -ne $c3Manifest[$rel].bytes -or (Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant() -ne $c3Manifest[$rel].sha256){throw "Package mismatch: $rel"}
 }
}
Test-C3Hashes $c3Package
Copy-Item -LiteralPath $c3Package -Destination $c3Copy -Recurse
Test-C3Hashes $c3Copy
$c3Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$c3Owns=$false;$c3Prior=$env:APPDATA;$c3PriorLocal=$env:LOCALAPPDATA
try {
 $c3Owns=$c3Mutex.WaitOne(0)
 if(-not $c3Owns -or (Get-Process | Where-Object{$_.ProcessName -match 'godot|blender|trellis'})){throw 'Renderer busy. Verified copy is ready; leave the active process intact.'}
 $env:APPDATA=Join-Path $c3Copy 'isolated-user';New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
 $env:LOCALAPPDATA=Join-Path $c3Copy 'isolated-local-user';New-Item -ItemType Directory -Path $env:LOCALAPPDATA | Out-Null
 $c3Project=Join-Path $c3Copy 'review'
 & $Godot --headless --editor --path $c3Project --import *> (Join-Path $c3Copy 'import.log')
 if($LASTEXITCODE -ne 0){throw 'Import failed.'}
 $c3Args=@('--path',$c3Project,'--rendering-method',$Renderer)
 if($Mode -ne 'review'){
  $c3Args+=@('--audio-driver','Dummy')
  if($Mode -ne 'benchmark'){$c3Args+=@('--fixed-fps','60')}
  $c3Args+=@('--',('--'+$Mode))
 }
 $c3Style=if($Visible){'Normal'}else{'Hidden'}
 $p=Start-Process -FilePath $Godot -ArgumentList (($c3Args | ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' ') -WindowStyle $c3Style -PassThru -RedirectStandardOutput (Join-Path $c3Copy 'review.log') -RedirectStandardError (Join-Path $c3Copy 'review.stderr')
 Write-Output "C3 review PID $($p.Id); isolated user data $env:APPDATA"
 $p.WaitForExit();$p.Refresh();if($p.ExitCode -ne 0){throw 'Review failed; inspect its log.'}
 if(Select-String -Path (Join-Path $c3Copy 'import.log'),(Join-Path $c3Copy 'review.log'),(Join-Path $c3Copy 'review.stderr') -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error' -Quiet){throw 'Script/shader failure; inspect copy logs.'}
} finally {$env:APPDATA=$c3Prior;$env:LOCALAPPDATA=$c3PriorLocal;if($c3Owns){$c3Mutex.ReleaseMutex()};$c3Mutex.Dispose()}
