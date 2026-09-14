extends SceneTree
## Read-only attribution around the unchanged original scene; no quit interception.
var observed: Dictionary = {}
var records: Array = []
var buffered := false

func _initialize() -> void:
	buffered="--r4-buffered" in OS.get_cmdline_user_args()
	node_added.connect(_node_added)
	call_deferred("_start")

func _start() -> void:
	# --script does not construct project autoloads; recreate the same two named nodes.
	for pair in [["Sim","res://scripts/sim.gd"],["ExtensionGuard","res://scripts/extension_guard.gd"]]:
		if root.get_node_or_null(pair[0]) == null:
			var singleton: Node = load(pair[1]).new()
			singleton.name = pair[0]
			root.add_child(singleton)
	var ident := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--r4-case="): ident = arg.trim_prefix("--r4-case=")
	assert(ident in ["b3","c1","c2","c3","c4","e1","f2","f3"])
	var scene := "native_review" if ident in ["b3","c1","c2","c3","c4"] else "review"
	var path := "res://r4/c1_before.tscn" if "--r4-original-copy" in OS.get_cmdline_user_args() else "res://"+ident+"/"+scene+".tscn"
	assert(change_scene_to_file(path) == OK)

func _node_added(node: Node) -> void:
	if node is AudioStreamPlayer3D:
		node.tree_exiting.connect(_observe.bind(node, "tree_exiting"))
		call_deferred("_observe", node, "added")

func _observe(node: Node, event: String) -> void:
	if not is_instance_valid(node): return
	var voice := node as AudioStreamPlayer3D
	if voice.stream == null: return
	var playback_id: int = voice.get_stream_playback().get_instance_id() if voice.has_stream_playback() else 0
	var data := {"event":event,"voice_id":voice.get_instance_id(),"path":str(voice.get_path()) if voice.is_inside_tree() else str(voice.name),
		"cue":str(voice.get_meta("cue","")),"stream_id":voice.stream.get_instance_id(),
		"stream_class":voice.stream.get_class(),"playback_id":playback_id,"playing":voice.playing,
		"parent":str(voice.get_parent().name) if voice.get_parent()!=null else ""}
	var key := str(data.voice_id)+":"+str(playback_id)+":"+event
	if observed.has(key): return
	observed[key]=true
	records.append(data)
	if not buffered: print("R4_AUDIO_TRACE ",JSON.stringify(data))

func _process(_delta: float) -> bool:
	for voice in get_nodes_in_group("interaction_sounds"): _observe(voice,"playing")
	return false

func _finalize() -> void:
	if buffered: print("R4_AUDIO_TRACE_BATCH ",JSON.stringify(records))
	print("R4_AUDIO_TRACE_END ",records.size())
