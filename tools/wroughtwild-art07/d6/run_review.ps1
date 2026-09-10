param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$Output)
$ErrorActionPreference='Stop'
$d6Root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../build/art07/d6'))
$d6Out=[IO.Path]::GetFullPath($Output)
if(-not $d6Out.StartsWith($d6Root+[IO.Path]::DirectorySeparatorChar)){throw 'Output outside D6 build'}
if(Test-Path -LiteralPath $d6Out){throw 'Use fresh output logs'}
New-Item -ItemType Directory -Path $d6Out | Out-Null
$d6Godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
$d6Queue=Join-Path $PSScriptRoot 'queued-job.ps1'
& $d6Queue -Program $d6Godot -JobArguments @('--headless','--path',$Project,'--editor','--import') -Log (Join-Path $d6Out 'import.log')
foreach($d6Mode in @('capture','motion','benchmark')){
  foreach($d6Renderer in @('forward_plus','gl_compatibility')){
    Write-Output ('D6_REVIEW_JOB '+$d6Renderer+' '+$d6Mode)
    & $d6Queue -Program $d6Godot -JobArguments @('--path',$Project,'--rendering-method',$d6Renderer,'--',('--'+$d6Mode)) -Log (Join-Path $d6Out ($d6Renderer+'-'+$d6Mode+'.log'))
  }
}
