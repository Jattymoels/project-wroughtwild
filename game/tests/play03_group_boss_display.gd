extends Sandpit
var checks := 0
var failures := 0
var samples := []
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL BOSS DISPLAY ",label)
func _ready() -> void:
	set_physics_process(false)
	terrain.set_process(false)
	mob_packs.set_physics_process(false)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	_run.call_deferred()
func _run() -> void:
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"nonfocusing mouse-free display probe")
	var original:=_sim().export_json()
	player.position=Vector3(0,1,6)
	player.rotation=Vector3.ZERO
	player.spring_arm.rotation.x=-.08
	# A separate body display probe, not ordinary world timing. Preparation is
	# the production resource contract already checked at real entry boundaries.
	load("res://art/creature_resources.gd").prepare(_sim())
	await display_body("forge_tyrant")
	var central:=preload("res://tests/central_fixture.gd").ready_rules(_sim(),original)
	check(not central.is_empty() and _sim().import_json(central),"retained native Central setup before measured display")
	check(_sim().trial_start_story(618,"forge_capstone"),"native human session selected")
	await display_body("conservator")
	_sim().trial_abandon()
	check(_sim().trial_end() and _sim().import_json(original),"boss probe settles and restores native state")
	var output:=OS.get_environment("WROUGHTWILD_ARRIVAL_OUTPUT")
	var receipt:={"checks":checks,"failures":failures,"samples":samples,"scope":"Isolated first display after real resource preparation; world simulation intentionally absent from this separate body probe. Setup never overlaps measured draw."}
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	print("BOSS_DISPLAY ",JSON.stringify(receipt))
	get_tree().quit(0 if failures==0 else 1)
func display_body(id: String) -> void:
	# Flush setup before beginning. No boss instance exists during this wait.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var began:=Time.get_ticks_usec()
	var body:=Boss.spawn_boss(self,Vector3(0,1,0))
	var created:=(Time.get_ticks_usec()-began)/1000.0
	check(String(body.enemy_id)==id and body._mesh.is_visible_in_tree(),"selected visible "+id)
	await RenderingServer.frame_post_draw
	var first:=(Time.get_ticks_usec()-began)/1000.0
	var frame_began:=Time.get_ticks_usec()
	await RenderingServer.frame_post_draw
	var next:=(Time.get_ticks_usec()-frame_began)/1000.0
	samples.append({"id":id,"spawn_ms":created,"creation_through_first_post_draw_ms":first,"next_post_draw_interval_ms":next})
	if body is Conservator:
		var other:=Boss.spawn_boss(self,Vector3(4,1,0)) as Conservator
		check(body._mesh.mesh==other._mesh.mesh and body._material!=other._material,"shared exact human geometry with actor-local material")
		check(body.arms[0]!=body.arms[1] and body.arms[0]!=other.arms[0] and body.arms[0].get_child(0).mesh==other.arms[0].get_child(0).mesh,"independent animated human joints reuse only immutable limb geometry")
		check(body.harness.mesh==other.harness.mesh and body.harness.material_override!=other.harness.material_override,"independent harness material over shared scars")
		other.free()
	body.free()
