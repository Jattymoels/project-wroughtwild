param([string]$Godot=(Join-Path $PSScriptRoot 'engine/Godot_v4.5-stable_win64.exe'),[ValidateSet('forward_plus','gl_compatibility')][string]$Renderer='forward_plus',[switch]$Baseline,[switch]$Import,[switch]$Smoke)
$ErrorActionPreference='Stop'
$g1Package=$PSScriptRoot
$g1Project=Join-Path $g1Package 'game'
if(-not (Test-Path -LiteralPath (Join-Path $g1Project 'project.godot'))){throw 'Run the copy of launch.ps1 at the packaged handoff root.'}
$g1Prior=$env:APPDATA
try {
 $env:APPDATA=Join-Path (Split-Path $g1Package) ((Split-Path $g1Package -Leaf)+'-user')
 $g1Args=@('--path',$g1Project,'--rendering-method',$Renderer)
 if($Import){$g1Args=@('--headless','--editor','--import')+$g1Args}
 elseif($Baseline -or $Smoke){$g1Args+=@('--');if($Baseline){$g1Args+='--baseline'};if($Smoke){$g1Args+='--smoke'}}
 $g1Quoted=@($g1Args|ForEach-Object {'"'+$_+'"'})
 $g1Process=Start-Process -FilePath $Godot -ArgumentList $g1Quoted -WindowStyle Hidden -Wait -PassThru
 if($g1Process.ExitCode -ne 0){throw "Godot exited $($g1Process.ExitCode)"}
} finally {$env:APPDATA=$g1Prior}
