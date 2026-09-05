extends Label3D
## Depth-tested world labels with a bounded close-up size; no physics queries.
const LOOK = preload("res://art/character_look.tres")

func _ready() -> void:
	font_size = LOOK.name_font_size
	pixel_size = LOOK.name_pixel_size
	outline_size = 5
	no_depth_test = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var offset := global_position-camera.global_position
	var distance := offset.length()
	scale = Vector3.ONE * minf(1.0,distance/LOOK.name_reference_distance)
	visible = distance < LOOK.name_distance and distance > 0.05 and \
		(-camera.global_basis.z).dot(offset.normalized()) > cos(deg_to_rad(LOOK.name_focus_degrees))
