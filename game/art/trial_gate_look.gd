extends MeshInstance3D
## Grounded Forge stone and recovered lamellae replace the orange placeholder.
## The scene fits this shared mesh to the unchanged 1 x 4 x 3 m gate body.
## Its recessed charcoal inset indicates a sealed entry surface; E still owns
## entry. The frame/inset contain no collision, lights, clocks or run rules.
func _ready() -> void:
	mesh = AuthoredAssets.mesh_for("cataclysm_forge_threshold")
