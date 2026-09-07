extends Resource
## Presentation only: a paid manual operation lifts a few tiny work flecks.
## No saved state, collision, light, fuel or item ownership belongs here.

## Seconds until the response disappears; keep rapid batches from leaving litter.
@export var duration := 0.38
## Bounded flecks per completion, regardless of recipe quantity.
@export_range(1, 6, 1) var fleck_count := 3
## Metres: small surface chips, distinct from collectible material drops.
@export var fleck_size := Vector3(0.018, 0.012, 0.040)
## Maximum outward and upward movement, kept on the local work surface.
@export var spread := 0.10
@export var rise := 0.11
## Mounts on existing station geometry; changing these never moves its body.
@export var bench_mount := Vector3(0, 1.06, 0.12)
@export var yard_mount := Vector3(0, 1.10, 0.12)
@export var forge_mount := Vector3(0, 0.94, 0.35)
## Muted physical finishes; forge scale is warm but emits no danger-like glow.
@export var bench_colour := Color("ab8653")
@export var yard_colour := Color("aaa69c")
@export var forge_colour := Color("b57c52")


func mount_for(id: StringName) -> Vector3:
	if String(id).begins_with("forge_"): return forge_mount
	return yard_mount if id == &"mason_yard" else bench_mount


func colour_for(id: StringName) -> Color:
	if String(id).begins_with("forge_"): return forge_colour
	return yard_colour if id == &"mason_yard" else bench_colour
