class_name EnvironmentAmbience
extends Node
## The player's current surface supplies brief air/rustle, separated by silence.
## One retained voice; no object scans, gameplay noise or saved ambient clocks.
signal clip_started(bed: String, variant: int, stream: AudioStreamWAV, gain: float)
const LOOK = preload("res://art/environment_sound_look.tres")
var player: WroughtwildPlayer
var _voices: Array[AudioStreamPlayer] = []
var _levels: Array[float] = [0.0]
var _target := -1
var _rng := RandomNumberGenerator.new()
var _quiet_left := -1.0
var _clip_left := 0.0
var _last_variant := -1
var _sample_left := 0.0
var _last_position := Vector3.ZERO
var _has_position := false
var _terrain_id := 0
var _profile := ""
var _seed := 0
var active_bed := ""

func setup(subject: WroughtwildPlayer) -> void:
	if is_instance_valid(player):
		if player.combat != null and player.combat.died.is_connected(reset_context):
			player.combat.died.disconnect(reset_context)
		if player.audio_preferences.changed.is_connected(_preferences_changed):
			player.audio_preferences.changed.disconnect(_preferences_changed)
	player = subject
	_rng.randomize()
	if is_instance_valid(player) and player.combat != null:
		player.combat.died.connect(reset_context)
	if is_instance_valid(player):
		if not player.audio_preferences.changed.is_connected(_preferences_changed):
			player.audio_preferences.changed.connect(_preferences_changed)
	reset_context()

func _ready() -> void:
	# Fixed cold preparation, not synthesis on a crossing or in each frame.
	EnvironmentSound.prepare()
	for i in 1:
		var voice := AudioStreamPlayer.new()
		voice.name = "EnvironmentTexture" + str(i)
		voice.bus = &"Master"
		voice.volume_linear = 0.0
		add_child(voice)
		voice.add_to_group(&"environment_ambience_voices")
		_voices.append(voice)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
		reset_context()

## Called after explicit restore/rebuild too: even a same-coordinate load starts
## quietly. This operation never creates a one-shot or touches life/inventory.
func reset_context() -> void:
	if not _has_position and active_bed.is_empty(): return
	for voice: AudioStreamPlayer in _voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.volume_linear = 0.0
	_levels = [0.0]
	_target = -1
	_quiet_left = -1.0
	_clip_left = 0.0
	_sample_left = 0.0
	_has_position = false
	_terrain_id = 0
	_profile = ""
	_seed = 0
	active_bed = ""

## Shared lookup for the selected map payload, including every historical
## profile. A surface names ordinary air texture, never a resource location.
static func bed_at(terrain: Terrain, global_at: Vector3) -> String:
	if not is_instance_valid(terrain): return ""
	var map := terrain.map
	var cell := float(map.get("cell_size", 0.0))
	if cell <= 0.0 or not global_at.is_finite(): return ""
	var at := terrain.to_local(global_at)
	var x := floori(at.x / cell)
	var z := floori(at.z / cell)
	var width := int(map.get("width", 0))
	var height := int(map.get("height", 0))
	if x < 0 or z < 0 or x >= width or z >= height: return ""
	var biomes: PackedInt32Array = map.get("biomes", PackedInt32Array())
	var defs: Array = map.get("biome_defs", [])
	if biomes.size() != width * height: return ""
	var index := int(biomes[z * width + x])
	if index < 0 or index >= defs.size() or not defs[index] is Dictionary: return ""
	return EnvironmentSound.bed_for_surface(String(defs[index].get("surface", "")))

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not player.is_inside_tree() or not player.is_physics_processing() \
		or get_tree().paused or player.combat == null or player.combat.life <= 0.0 \
		or (player.trial != null and player.trial.active()) or player.audio_preferences.gain() <= 0.0:
		reset_context()
		return
	var terrain := player._find_terrain()
	if not is_instance_valid(terrain) or terrain.map.is_empty():
		reset_context()
		return
	var map := terrain.map
	var at := terrain.to_local(player.global_position)
	var cell := float(map.get("cell_size", 0.0))
	if not at.is_finite() or cell <= 0.0 or at.x < 0.0 or at.z < 0.0 \
		or at.x >= int(map.get("width", 0)) * cell or at.z >= int(map.get("height", 0)) * cell:
		reset_context()
		return
	var terrain_id := terrain.get_instance_id()
	var profile := terrain.world_profile()
	var world_seed := terrain.seed_value()
	if terrain_id != _terrain_id or profile != _profile or world_seed != _seed \
		or (_has_position and player.global_position.distance_to(_last_position) > LOOK.teleport_distance_m):
		reset_context()
		_terrain_id = terrain_id
		_profile = profile
		_seed = world_seed
	_last_position = player.global_position
	_has_position = true
	_sample_left -= delta
	if _sample_left <= 0.0:
		_sample_left = LOOK.sample_interval_seconds
		var bed := bed_at(terrain, player.global_position)
		if bed.is_empty():
			reset_context()
			return
		if bed != active_bed:
			_stop_clip()
			active_bed = bed
			_quiet_left = -1.0
	if _voices.is_empty(): return
	if _quiet_left < 0.0:
		_quiet_left = _rng.randf_range(LOOK.quiet_seconds.x, LOOK.quiet_seconds.y)
		return
	if _clip_left > 0.0:
		_clip_left = maxf(0.0, _clip_left - delta)
		if _clip_left <= 0.0:
			_stop_clip()
			_quiet_left = _rng.randf_range(LOOK.quiet_seconds.x, LOOK.quiet_seconds.y)
		else: _update_gain(delta)
		return
	_quiet_left = maxf(0.0, _quiet_left - delta)
	if _quiet_left > 0.0: return
	# No catch-up burst after a stall; start at most one short event this turn.
	var variant := _rng.randi_range(0, LOOK.variants - 1 if _last_variant < 0 else LOOK.variants - 2)
	if _last_variant >= 0 and variant >= _last_variant: variant += 1
	_last_variant = variant
	var stream := EnvironmentSound.clip(active_bed, variant)
	_target = 0
	_voices[0].stream = stream
	_clip_left = stream.get_length()
	_update_gain(LOOK.fade_seconds)
	_voices[0].play()
	clip_started.emit(active_bed, variant, stream, _levels[0])

func _stop_clip() -> void:
	if not _voices.is_empty():
		_voices[0].stop()
		_voices[0].volume_linear = 0.0
	_levels = [0.0]
	_target = -1
	_clip_left = 0.0

func _update_gain(delta: float) -> void:
	var outside := db_to_linear(LOOK.outdoor_gain_db - (LOOK.shelter_attenuation_db if player.combat.sheltered else 0.0)) * player.audio_preferences.gain()
	_levels[0] = move_toward(_levels[0], outside, db_to_linear(LOOK.outdoor_gain_db) * delta / maxf(LOOK.fade_seconds, 0.001))
	_voices[0].volume_linear = _levels[0]

func _preferences_changed() -> void:
	if player.audio_preferences.gain() <= 0.0: reset_context()
	elif _target >= 0: _update_gain(LOOK.fade_seconds)
