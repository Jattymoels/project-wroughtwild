param([Parameter(Mandatory)][string]$Package,[Parameter(Mandatory)][string]$CopyTo,[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[ValidateSet('check','capture','motion','benchmark','review')][string]$Mode='check',[switch]$Visible)
$ErrorActionPreference='Stop'
$artPackage=(Resolve-Path -LiteralPath $Package).Path
$artCopy=[IO.Path]::GetFullPath($CopyTo)
if(Test-Path -LiteralPath $artCopy){throw 'Use a fresh handoff copy.'}
if($artCopy.StartsWith($artPackage+[IO.Path]::DirectorySeparatorChar)){throw 'Copy must be outside the canonical package.'}
$artManifest=Get-Content -LiteralPath (Join-Path $artPackage 'manifest.json') -Raw | ConvertFrom-Json
foreach($entry in $artManifest.PSObject.Properties){if((Get-FileHash -LiteralPath (Join-Path $artPackage $entry.Name) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.Value.sha256){throw "Package hash mismatch: $($entry.Name)"}}
Copy-Item -LiteralPath $artPackage -Destination $artCopy -Recurse
foreach($entry in $artManifest.PSObject.Properties){if((Get-FileHash -LiteralPath (Join-Path $artCopy $entry.Name) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.Value.sha256){throw "Copy hash mismatch: $($entry.Name)"}}
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
$artApp=$env:APPDATA;$artLocal=$env:LOCALAPPDATA
try {
 $artOwns=$artMutex.WaitOne(0);if(-not $artOwns){throw 'GPU slot occupied.'}
 if(Get-Process | Where-Object {$_.ProcessName -match 'godot|blender|trellis'}){throw 'Existing renderer/generator; wait for its owner.'}
 $env:APPDATA=Join-Path $artCopy 'isolated-user';$env:LOCALAPPDATA=Join-Path $artCopy 'isolated-local-user'
 New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 $artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
 $artProject=Join-Path $artCopy 'review';$artStyle=if($Visible){'Normal'}else{'Hidden'}
 foreach($phase in @('import','review')){
  $artArgs=if($phase -eq 'import'){@('--headless','--editor','--import','--path',$artProject,'--quit')}else{@('--path',$artProject,'--audio-driver','Dummy','--rendering-method',$Renderer)}
  if($phase -eq 'review' -and $Mode -ne 'review'){$artArgs+=@('--',"--$Mode")}
  $artLog=Join-Path $artCopy "$phase.log"
  $artProc=Start-Process -FilePath $artGodot -ArgumentList (($artArgs | ForEach-Object {'"'+$_+'"'}) -join ' ') -WindowStyle $artStyle -PassThru -RedirectStandardOutput $artLog -RedirectStandardError "$artLog.stderr"
  Write-Output "B2 copy own PID $($artProc.Id)"
  while(-not $artProc.WaitForExit(1000)){if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error' -Quiet){Stop-Process -Id $artProc.Id;throw 'Own review process failed.'}}
  $artProc.Refresh();if($artProc.ExitCode -ne 0){throw 'Review process failed.'}
  if(Select-String -Path $artLog,"$artLog.stderr" -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error' -Quiet){throw 'Review diagnostic failure.'}
 }
} finally {$env:APPDATA=$artApp;$env:LOCALAPPDATA=$artLocal;if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
Write-Output "B2_FRESH_HANDOFF_OK $artCopy"
