class_name StrangeStreamLook
extends Resource
## Nearby resource scenes only; records are always kept for saving/depletion.
@export var radius_m := 120.0 # Creates resources before the normal visual distance.
@export var retire_margin_m := 32.0 # Prevents repeated rebuilds when pacing at an edge.
@export var nodes_per_frame := 12 # Bounds resource scene creation during travel.
@export var refresh_seconds := 0.25 # Nearby bucket refresh cadence while walking.
@export var terrain_initial_radius_m := 128.0 # Exact ground covers every initially visible resource.
@export var terrain_detail_radius_m := 144.0 # Build walking collision and close detail ahead of resource activation.
@export var terrain_keep_radius_m := 176.0 # Hysteresis before releasing unedited meshes, collision and surface samplers.
@export var terrain_safe_radius_m := 32.0 # Teleports and fast movement synchronously prepare the next playable area.
@export var terrain_chunks_per_frame := 1 # One small mesh, cover or collision phase each frame during exploration.
@export var terrain_far_step_cells := 8 # A distant heightfield keeps the whole skyline visible before detail exists.
@export var diagnostic_window_samples := 512 # Retain only recent construction/retirement timings during long exploration.
func settings() -> Dictionary:
	return {"radius_m":radius_m,"retire_margin_m":retire_margin_m,"nodes_per_frame":nodes_per_frame,"refresh_seconds":refresh_seconds,
		"terrain_initial_radius_m":terrain_initial_radius_m,"terrain_detail_radius_m":terrain_detail_radius_m,
		"terrain_keep_radius_m":terrain_keep_radius_m,"terrain_safe_radius_m":terrain_safe_radius_m,
		"terrain_chunks_per_frame":terrain_chunks_per_frame,"terrain_far_step_cells":terrain_far_step_cells,
		"diagnostic_window_samples":diagnostic_window_samples}
