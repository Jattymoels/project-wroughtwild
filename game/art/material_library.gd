extends Resource
## One surface vocabulary for placed pieces, previews and catalogue swatches.
## Profile pattern selects wood(0), slate(1), fossil masonry(2), brick(3),
## woven reeds(4), cork(5), vitrified basalt(6), or glass(7).
@export var profiles: Dictionary = {}
## Metres of glazing frame and muntin inside its one-metre wall envelope.
@export var window_frame_metres := 0.075
@export var window_muntin_metres := 0.026
## Small physical battens hold a light panel together without new inventory.
@export var panel_batten_metres := 0.045
## Shared visibility controls bound tree/detail geometry cost in the field.
@export var authored_tree_distance := 200.0
@export var authored_detail_distance := 48.0
## Batches of surviving meadow/fen tree records carry woodland into the middle
## distance. They contain no colliders, gathering state or generated positions.
@export var distant_canopy_distance := 320.0
## A soft far fade avoids a hard ring while bounding distant draw submissions.
@export var distant_canopy_fade_margin := 24.0
