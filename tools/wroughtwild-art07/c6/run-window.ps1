param([Parameter(Mandatory)][string]$Project,[Parameter(Mandatory)][string]$LogPrefix,[string[]]$Stages=@('capture','walk','motion','benchmark'),[string[]]$Renderers=@('forward_plus','gl_compatibility'))
$ErrorActionPreference='Stop'
$c6Window=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU');$c6OwnsWindow=$false
try {
 $c6Deadline=(Get-Date).AddSeconds(48)
 while(-not $c6OwnsWindow -and (Get-Date) -lt $c6Deadline){
  $c6OwnsWindow=$c6Window.WaitOne(0)
  if(-not $c6OwnsWindow){Start-Sleep -Milliseconds 250}
 }
 if(-not $c6OwnsWindow){Write-Output 'C6_GPU_WINDOW_BUSY';return}
 foreach($c6Stage in $Stages){
  & "$PSScriptRoot/run-stage.ps1" -Project $Project -Logs "$LogPrefix-$c6Stage" -Stage $c6Stage -Renderers $Renderers
  foreach($c6Renderer in $Renderers){
   if(Select-String -LiteralPath "$LogPrefix-$c6Stage/$c6Renderer.log.stderr" -Pattern 'ERROR:' -Quiet){throw "Rendered diagnostic in $c6Stage/$c6Renderer; inspect before continuing."}
  }
 }
}finally{if($c6OwnsWindow){$c6Window.ReleaseMutex()};$c6Window.Dispose()}
