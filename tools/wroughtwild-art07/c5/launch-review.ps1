param(
 [Parameter(Mandatory)][string]$Package,
 [Parameter(Mandatory)][string]$FreshTarget,
 [ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',
 [switch]$Native,
 [switch]$Visible
)
$ErrorActionPreference='Stop'
$artPython='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$artGodot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$artSource=(Resolve-Path -LiteralPath $Package).Path
$artTarget=[IO.Path]::GetFullPath($FreshTarget)
if(Test-Path -LiteralPath $artTarget){throw 'FreshTarget must not exist.'}
if($artTarget.StartsWith($artSource+[IO.Path]::DirectorySeparatorChar)){throw 'Do not import inside the canonical package.'}
& $artPython "$PSScriptRoot/verify_package.py" $artSource $artTarget
if($LASTEXITCODE -ne 0){throw 'Manifest verification/copy failed.'}
$artProject=Join-Path $artTarget 'review/game'
$artLogs=Join-Path $artTarget 'launch'
New-Item -ItemType Directory -Path $artLogs | Out-Null
$artPriorApp=$env:APPDATA;$artPriorLocal=$env:LOCALAPPDATA
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$artOwns=$false
function Invoke-C5([string[]]$JobArguments,[string]$Name){
 $artQuoted=($JobArguments | ForEach-Object {'"'+$_.Replace('"','\"')+'"'}) -join ' '
 $artStyle='Hidden';if($Visible -and $Name -eq 'review'){$artStyle='Normal'}
 $artP=Start-Process -FilePath $artGodot -ArgumentList $artQuoted -PassThru -WindowStyle $artStyle -RedirectStandardOutput (Join-Path $artLogs ($Name+'.log')) -RedirectStandardError (Join-Path $artLogs ($Name+'.stderr'))
 Write-Output "C5 own PID $($artP.Id)"
 $artP.WaitForExit();$artP.Refresh()
 if($artP.ExitCode -ne 0){throw "$Name failed."}
 if(Select-String -Path (Join-Path $artLogs ($Name+'.log')),(Join-Path $artLogs ($Name+'.stderr')) -Pattern 'SCRIPT ERROR|SHADER ERROR|Parse Error' -Quiet){throw "$Name reported an error."}
}
try {
 $env:APPDATA=Join-Path $artLogs 'user';$env:LOCALAPPDATA=Join-Path $artLogs 'local-user'
 New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
 Invoke-C5 @('--headless','--editor','--path',$artProject,'--import') 'import'
 $artOwns=$artMutex.WaitOne(0);if(-not $artOwns){throw 'GPU slot busy; copied package remains available.'}
 $artBusy=@(Get-CimInstance Win32_Process -Filter "Name LIKE '%Godot%' OR Name LIKE '%blender%' OR Name LIKE '%trellis%'" | Where-Object {$_.ThreadCount -gt 0 -and ($_.Name -notmatch 'godot' -or $_.CommandLine -notmatch '--headless')})
 if($artBusy.Count){throw 'Existing renderer/generator; leave it untouched and retry later with another fresh target.'}
 $artScene='res://c5/review.tscn';if($Native){$artScene='res://c5/native_review.tscn'}
 Invoke-C5 @('--audio-driver','Dummy','--path',$artProject,'--rendering-method',$Renderer,'--resolution','1440x900',$artScene) 'review'
} finally {$env:APPDATA=$artPriorApp;$env:LOCALAPPDATA=$artPriorLocal;if($artOwns){$artMutex.ReleaseMutex()};$artMutex.Dispose()}
