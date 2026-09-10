param([Parameter(Mandatory)][string]$Package,[string]$Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',[switch]$Compatibility,[switch]$Native,[switch]$Visible)
$ErrorActionPreference='Stop'
$artPackage=(Resolve-Path -LiteralPath $Package).Path
$artSession=Join-Path (Split-Path $artPackage) ('b3-review-session-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $artSession | Out-Null
Copy-Item -LiteralPath (Join-Path $artPackage $(if($Native){'native'}else{'review'})) -Destination $artSession -Recurse
$artProject=Join-Path $artSession $(if($Native){'native/game'}else{'review'})
$artPriorApp=$env:APPDATA;$artPriorLocal=$env:LOCALAPPDATA
try{
 $env:APPDATA=Join-Path $artSession 'user';$env:LOCALAPPDATA=Join-Path $artSession 'local-user'
 New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 & $Godot --headless --editor --path $artProject --import *> (Join-Path $artSession 'import.log')
 if($LASTEXITCODE -ne 0){throw 'Fresh import failed; inspect the session log.'}
 $artArgs=@('--path',$artProject,'--rendering-method',$(if($Compatibility){'gl_compatibility'}else{'forward_plus'}),'--resolution','1440x900')
 if($Native){$artArgs+=@('--fixed-fps','60','res://b3/native_review.tscn')}
 $artQuoted=($artArgs | ForEach-Object {'"'+$_+'"'}) -join ' '
 $artStyle=if($Visible){'Normal'}else{'Hidden'}
 $artProc=Start-Process -FilePath $Godot -ArgumentList $artQuoted -PassThru -WindowStyle $artStyle -RedirectStandardOutput (Join-Path $artSession 'review.log') -RedirectStandardError (Join-Path $artSession 'review.stderr')
 Write-Output "B3 review PID $($artProc.Id); fresh session $artSession"
}finally{$env:APPDATA=$artPriorApp;$env:LOCALAPPDATA=$artPriorLocal}
