param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$CopyTo,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[ValidateSet('review','check','capture','walk','motion','benchmark')][string]$Mode='review',[switch]$Visible,[string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe')
$ErrorActionPreference='Stop'
$b4Package=(Resolve-Path -LiteralPath $Package).Path
$b4Copy=[IO.Path]::GetFullPath($CopyTo)
if(Test-Path -LiteralPath $b4Copy){throw 'Use a fresh copy directory; canonical package is immutable.'}
$b4Manifest=Get-Content -Raw -LiteralPath (Join-Path $b4Package 'manifest.json') | ConvertFrom-Json -AsHashtable
function Test-B4Hashes([string]$Folder){
 foreach($rel in $b4Manifest.Keys){
  $p=[IO.Path]::GetFullPath((Join-Path $Folder $rel))
  if(-not $p.StartsWith($Folder+[IO.Path]::DirectorySeparatorChar)){throw 'Manifest path escapes package.'}
  if((Get-Item -LiteralPath $p).Length -ne $b4Manifest[$rel].bytes -or (Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant() -ne $b4Manifest[$rel].sha256){throw "Package mismatch: $rel"}
 }
}
Test-B4Hashes $b4Package
Copy-Item -LiteralPath $b4Package -Destination $b4Copy -Recurse
Test-B4Hashes $b4Copy
$b4Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$b4Owns=$false;$b4Prior=$env:APPDATA;$b4PriorLocal=$env:LOCALAPPDATA
try {
 $b4Owns=$b4Mutex.WaitOne(0)
 if(-not $b4Owns -or (Get-Process | Where-Object{$_.ProcessName -match 'godot|blender|trellis'})){throw 'Renderer busy. Verified copy is ready; leave the active process intact.'}
 $env:APPDATA=Join-Path $b4Copy 'isolated-user';New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
 $env:LOCALAPPDATA=Join-Path $b4Copy 'isolated-local-user';New-Item -ItemType Directory -Path $env:LOCALAPPDATA | Out-Null
 $b4Project=Join-Path $b4Copy 'review'
 & $Godot --headless --editor --path $b4Project --import *> (Join-Path $b4Copy 'import.log')
 if($LASTEXITCODE -ne 0){throw 'Import failed.'}
 $b4Args=@('--path',$b4Project,'--rendering-method',$Renderer)
 if($Mode -ne 'review'){$b4Args+=@('--audio-driver','Dummy','--fixed-fps','60','--',('--'+$Mode))}
 $b4Style=if($Visible){'Normal'}else{'Hidden'}
 $p=Start-Process -FilePath $Godot -ArgumentList (($b4Args | ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' ') -WindowStyle $b4Style -PassThru -RedirectStandardOutput (Join-Path $b4Copy 'review.log') -RedirectStandardError (Join-Path $b4Copy 'review.stderr')
 Write-Output "B4 review PID $($p.Id); isolated user data $env:APPDATA"
 $p.WaitForExit();$p.Refresh();if($p.ExitCode -ne 0){throw 'Review failed; inspect its log.'}
 if(Select-String -Path (Join-Path $b4Copy 'import.log'),(Join-Path $b4Copy 'review.log'),(Join-Path $b4Copy 'review.stderr') -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error' -Quiet){throw 'Script/shader failure; inspect copy logs.'}
} finally {$env:APPDATA=$b4Prior;$env:LOCALAPPDATA=$b4PriorLocal;if($b4Owns){$b4Mutex.ReleaseMutex()};$b4Mutex.Dispose()}
