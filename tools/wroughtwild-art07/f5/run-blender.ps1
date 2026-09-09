param([Parameter(Mandatory)][string]$Package,[string]$Colour='all',[string]$Tag='v01')
$ErrorActionPreference='Stop'
$artPackage=(Resolve-Path -LiteralPath $Package).Path
$artMutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$artOwns=$false;$artPrior=$env:BLENDER_USER_RESOURCES
try{
 $artOwns=$artMutex.WaitOne(0)
 if(-not $artOwns){throw 'ART-07 GPU/render slot busy.'}
 $artOthers=@(Get-Process|Where-Object{$_.ProcessName -match 'godot|blender|trellis'})
 if($artOthers.Count){throw 'Existing renderer/generator present; preserve it.'}
 $artBuild=Split-Path $artPackage
 $env:BLENDER_USER_RESOURCES=Join-Path $artBuild 'blender-user'
 $artColours=if($Colour -eq 'all'){@('red','white','blue','green')}else{@($Colour)}
 foreach($artColour in $artColours){
  $artOutput=Join-Path $artBuild "blender-$artColour-$Tag"
  if(Test-Path -LiteralPath $artOutput){throw 'Use fresh audit outputs.'}
  $artLog=Join-Path $artBuild "blender-$artColour-$Tag.log"
  & C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe --background --threads 8 --python-exit-code 1 --python (Join-Path $PSScriptRoot 'blender_audit.py') -- $artPackage $artColour $artOutput *> $artLog
  if($LASTEXITCODE -ne 0){throw "Blender audit failed: $artLog"}
  Write-Output "F5_BLENDER_OK $artColour $artOutput"
 }
}finally{
 $env:BLENDER_USER_RESOURCES=$artPrior
 if($artOwns){$artMutex.ReleaseMutex()}
 $artMutex.Dispose()
}
