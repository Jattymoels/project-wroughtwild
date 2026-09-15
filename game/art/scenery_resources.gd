extends RefCounted
## Finite shared rare-source/device resources. Preparation owns no world state.
## Loaded at actual world entry; adapters retain lazy support for isolated scenes.
static var _ready := false
static var _adapters: Array = []

static func ready() -> bool:
	return _ready

static func prepare(trace: Node = null) -> void:
	var began := Time.get_ticks_usec() if trace != null else 0
	if not _ready:
		for path: String in ["res://f1/visuals.gd","res://f2/art.gd","res://f3/visuals.gd"]:
			var phase := Time.get_ticks_usec() if trace != null else 0
			var adapter = load(path)
			_adapters.append(adapter)
			adapter.prepare_resources()
			if trace != null: trace.note_arrival("scenery_prepare_adapter",phase,{"path":path})
		# Thrumroot still constructs its approved legacy backing before F2 hides it.
		# Retain the same cached mesh/finish output without creating a live source.
		var phase := Time.get_ticks_usec() if trace != null else 0
		StrangeResourceArt.mesh_for(&"thrumroot")
		var backing := StrangeResourceArt.FINISH.build("thrumroot")
		backing.free()
		if trace != null: trace.note_arrival("scenery_prepare_backing",phase,{"visual":"thrumroot"})
		_ready = true
	if trace != null: trace.note_arrival("scenery_preparation",began,{"ready":_ready})
