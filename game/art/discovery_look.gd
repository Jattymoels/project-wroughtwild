extends Resource
## Presentation of inert remains at the generator's existing clue points.
## Sizes are metres, independent of finite stock and harvesting envelopes.

## A fallen empty papery husk remains legible beside grass without a lit heart.
@export var lantern_husk_size := Vector3(.50,.34,.52)
## An open, slack root shell suggests tension without presenting an intact coil.
@export var thrum_shell_size := Vector3(.95,.32,.48)
## A low split/scorch mark reads as spent ground, not another upright glass core.
@export var storm_scar_size := Vector3(1.25,.14,.72)
## A small scatter of ordinary displaced grit points toward the magnetic host.
@export var pull_grit_size := Vector3(.85,.10,.65)
## A short empty pressure casing has no membrane or breathing motion.
@export var vent_case_size := Vector3(.60,.30,.60)

func clue_size(kind: String) -> Vector3:
	match kind:
		"lanternheart": return lantern_husk_size
		"thrumroot": return thrum_shell_size
		"stormglass": return storm_scar_size
		"pullstone": return pull_grit_size
		"ventlung": return vent_case_size
	return Vector3.ZERO
