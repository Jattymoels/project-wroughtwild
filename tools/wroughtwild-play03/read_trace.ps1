param([Parameter(Mandatory=$true)][string]$Trace)
$ErrorActionPreference='Stop'
$capture=Get-Content -LiteralPath $Trace -Raw | ConvertFrom-Json
if($null -eq $capture.metadata -or $null -eq $capture.frames){throw 'Expected a PLAY03 recorder JSON file.'}
$capture.metadata | Select-Object engine,rendering_method,gpu,retained_frames,overwritten_frames,stop_reason,frame_p95_ms,frame_max_ms,observer_frame_max_ms | Format-List
$capture.frames | Sort-Object frame_ms -Descending | Select-Object -First 8 elapsed_s,frame_ms,position,below_surface_m,floor,chunk_tick_ms,resource_tick_ms,ensure_area_ms,resource_arrival_max_ms,resource_arrival_visual,player_physics_ms,physics_callbacks_ms,draw_wall_ms,terrain_pending,resource_pending,projection_pending | Format-List
Write-Output 'Intervals include startup/loads if retained; the last can be a partial stop interval. Nested timers overlap. Draw wall time is not GPU execution time. A spike alone does not establish the reported cause.'
