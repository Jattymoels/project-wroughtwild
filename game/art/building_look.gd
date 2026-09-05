extends Resource
## Shared workshop palette for ordinary construction, including restored pieces.
@export var timber := Color("98774e")
@export var pine := Color("ab8e5f")
@export var bog_oak := Color("594332")
@export var ash_wood := Color("aaa392")
@export var stone := Color("74747a")
## Darken structural timber and roof boards so the building has readable framing.
@export var frame_shade := 0.62
@export var roof_colour := Color("344d58")
## Width and joint depth of visible boards, in metres.
@export var board_width := 0.28
@export var seam_width := 0.012
## Timber ceilings and undersides are quieter than the sunlit upper floor faces.
@export var underside_shade := 0.74

func wood_colour(family: String) -> Color:
	return {"wood":timber,"pine":pine,"bog_oak":bog_oak,"ash_wood":ash_wood}.get(family,timber)
