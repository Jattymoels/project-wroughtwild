extends Node3D
## Five short, cached local clues; presentation only, with no external audio.
const LOOK = preload("res://art/strange_look.tres")
static var _clips: Dictionary={}
static var _last_clue_ms: int=-10000
var kind: String

static func play(parent: Node3D, sound: String, gain_db: float = -18.0) -> void:
	if not parent.is_inside_tree() or DisplayServer.get_name()=="headless": return
	var player:=AudioStreamPlayer3D.new()
	player.stream=_clip(sound)
	player.volume_db=gain_db
	player.max_distance=LOOK.clue_sound_distance_m
	player.unit_size=2.0
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func attach(parent: Node3D, at: Vector3, sound: String) -> void:
	var cue:=load("res://art/strange_sound.gd").new() as Node3D
	cue.kind=sound
	cue.position=at
	parent.add_child(cue)

func _ready() -> void:
	var timer:=Timer.new()
	timer.wait_time=LOOK.clue_interval_s+float(abs(hash(kind+str(position)))%300)/100.0
	timer.timeout.connect(_clue)
	add_child(timer)
	timer.start()

func _clue() -> void:
	var camera:=get_viewport().get_camera_3d()
	if camera==null or camera.global_position.distance_to(global_position)>LOOK.clue_sound_distance_m: return
	if Time.get_ticks_msec()-_last_clue_ms<int(LOOK.clue_interval_s*1000): return
	_last_clue_ms=Time.get_ticks_msec()
	play(self,kind,LOOK.clue_volume_db)

static func _clip(sound: String) -> AudioStreamWAV:
	if _clips.has(sound): return _clips[sound]
	var clip:=AudioStreamWAV.new()
	clip.format=AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate=22050
	clip.stereo=false
	var samples:=int(LOOK.sound_duration_s*clip.mix_rate)
	var bytes:=PackedByteArray()
	bytes.resize(samples*2)
	var pitch: float={"lanternheart":620.0,"thrumroot":92.0,"stormglass":1160.0,"pullstone":170.0,"ventlung":74.0,"pulse":880.0,"tick":180.0}.get(sound,440.0)
	for i in samples:
		var time:=float(i)/clip.mix_rate
		var phase:=TAU*pitch*time
		var envelope:=minf(time*80,1.0)*exp(-time*8.0)
		var value:=sin(phase)*.65+sin(phase*2.73)*.19+sin(phase*4.17)*.10
		if sound in ["thrumroot","ventlung"]:
			value=(sin(phase+sin(time*31)*.6)*.5+sin(phase*1.013)*.25)*(.72+.28*sin(time*19))
		bytes.encode_s16(i*2,int(clampf(value*envelope,-1,1)*20000))
	clip.data=bytes
	_clips[sound]=clip
	return clip
