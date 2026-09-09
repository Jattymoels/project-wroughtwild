param([ValidateSet('red','white','blue','green')][string]$Colour='white',[switch]$Compatibility)
$ErrorActionPreference='Stop'
$artPackage=$PSScriptRoot
$artManifest=Get-Content -LiteralPath (Join-Path $artPackage 'manifest.json') -Raw | ConvertFrom-Json
foreach($artFile in $artManifest.files.PSObject.Properties){
 $artPath=Join-Path $artPackage $artFile.Name
 if((Get-FileHash -LiteralPath $artPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artFile.Value.sha256){throw "Package hash mismatch: $($artFile.Name)"}
}
# Fresh work outside the immutable handoff; short user-data location avoids long shader-cache paths.
$artParent=Split-Path $artPackage
$artRun=Join-Path $artParent ('review-'+[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $artRun | Out-Null
Copy-Item -LiteralPath (Join-Path $artPackage "$Colour/review") -Destination (Join-Path $artRun 'review') -Recurse
$artOldAppdata=$env:APPDATA;$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
try{
 $artOwns=$artMutex.WaitOne(0)
 if(-not $artOwns){throw 'ART-07 GPU slot busy; close this launcher and retry later.'}
 if(@(Get-Process|Where-Object{$_.ProcessName -match 'godot|blender|trellis'}).Count){throw 'Preserve the existing renderer/playtest; retry later.'}
 $env:APPDATA=Join-Path $env:TEMP ('ww-f5-'+[Guid]::NewGuid().ToString('N').Substring(0,8))
 New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
 @{review=$artRun;appdata=$env:APPDATA} | ConvertTo-Json | Set-Content (Join-Path $artRun 'private-paths.json')
 $artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
 $artArgs=@('--path',(Join-Path $artRun 'review'),'--audio-driver','Dummy')
 if($Compatibility){$artArgs=@('--rendering-method','gl_compatibility')+$artArgs}
 & $artGodot @artArgs --headless --editor --import --quit
 if($LASTEXITCODE -ne 0){throw 'Fresh import failed.'}
 & $artGodot @artArgs --resolution 1600x1000
 if($LASTEXITCODE -ne 0){throw 'Review failed.'}
}finally{
 $env:APPDATA=$artOldAppdata
 if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()
}
