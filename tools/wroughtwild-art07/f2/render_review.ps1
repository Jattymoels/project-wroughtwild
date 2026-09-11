param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output,
 [ValidateSet('capture','motion','detail','benchmark')][string]$Mode='capture')
$ErrorActionPreference='Stop'
$f2Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/f2'))
$f2Project=[IO.Path]::GetFullPath($Project);$f2Output=[IO.Path]::GetFullPath($Output)
foreach($f2Path in @($f2Project,$f2Output)){if(-not $f2Path.StartsWith($f2Root+[IO.Path]::DirectorySeparatorChar)){throw 'F2-only paths required'}}
if(Test-Path -LiteralPath $f2Output){throw 'Fresh logs required'}
New-Item -ItemType Directory -Path $f2Output | Out-Null
foreach($f2Renderer in @('forward_plus','gl_compatibility')) {
 $f2Args=@('--audio-driver','Dummy','--path',$f2Project,'--rendering-method',$f2Renderer,'--',('--'+$Mode))
 if($Mode -eq 'detail'){$f2Args=@('--audio-driver','Dummy','--path',$f2Project,'--rendering-method',$f2Renderer,'--','--motion','--close')}
 & (Join-Path $PSScriptRoot 'queued-job.ps1') -Program 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe' -JobArguments $f2Args -Log (Join-Path $f2Output ($f2Renderer+'.log'))
 if($LASTEXITCODE -ne 0){throw ('F2 '+$Mode+' failed: '+$f2Renderer)}
}
