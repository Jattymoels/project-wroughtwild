extends Resource
## Habitat silhouette is composed around existing resource nodes and walk routes.
@export var quarry_colour := Color("636669")
@export var shell_colour := Color("b5b09a")
@export var clay_colour := Color("785440")
@export var reed_colour := Color("777953")
@export var cork_colour := Color("5c493b")
## Decoration remains outside 2.0 m around work nodes and 1.8 m around approaches.
@export var resource_clearance_metres := 2.0
@export var approach_clearance_metres := 1.8
## Repeated accents per habitat: enough to compose a place, bounded draw calls.
@export var accents_per_site := 16
@export var detail_distance_metres := 65.0
## Wind is restrained displacement, only high foliage/soft reed tips move.
@export var wind_metres := 0.035
@export var wind_rate := 0.85
## Fen pools are shallow dressing, never swimming, collision or a resource.
@export var puddle_radius_metres := 1.25
@export var puddles_per_site := 3 # Small pools surround the useful clear ground.
@export var puddle_candidates := 96 # Bound a stable search around busy deposits.
@export var puddle_max_rise := 0.12 # Reject surfaces too sloped for shallow water.
@export var water_colour := Color("465954")
## Sparse motes fill shafts of light without covering threat effects.
@export var motes_per_site := 10
@export var motes_lifetime_seconds := 8.0
## Palette-scale grove trees: trunk collision follows the same scaled mesh.
@export var resinheart_scale := Vector3(1.15,1.5,1.15)
