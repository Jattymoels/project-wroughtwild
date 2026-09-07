extends Resource
## Presentation for existing hostile areas. No damage, timing or hit extents.

## Smooth enough for a clear distant circle while bounding each outline mesh.
@export_range(16, 64, 1) var arc_segments := 32
## Dark outside edge and a narrower warm stroke both sit inside the true area.
@export var border_width_m := 0.16
@export var stroke_inset_m := 0.035
@export var stroke_width_m := 0.055
## Lift only the outline above ordinary floor effects; solid cover still occludes.
@export var outline_height_m := 0.12
@export var stroke_lift_m := 0.003
## Cached cone/disc/lane dimensions cannot accumulate beyond this small palette.
@export_range(1, 32, 1) var mesh_cache_limit := 24
## Dark under-stroke survives pale effects; amber keeps the existing danger hue.
@export var border_colour := Color("211b15")
@export var warning_colour := Color("a4763e")
@export var progress_colour := Color("ffce83")
@export var active_colour := Color("ff7c37")
## Quiet fill preserves visibility of player-owned fields inside the perimeter.
@export var warning_fill := Color(1.0, 0.58, 0.2, 0.18)
@export var active_fill := Color(1.0, 0.3, 0.035, 0.50)
## Existing hostile burning ground keeps its full extent while fading to expiry.
@export var burning_ground_initial_alpha := 0.85

func fill(active: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = active_fill if active else warning_fill
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
