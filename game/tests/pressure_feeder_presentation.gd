extends Node3D
## Focused physical/presentation regression. The generated-world lifecycle,
## save escrow and reward ownership are exercised by pressure_workshop.tscn.
var checks:=0
var failures:=0

func check(condition: bool, label: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL PRESSURE PRESENTATION: ",label)

func _ready() -> void:
	_run.call_deferred()

func _floor(at: Vector3,size: Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new()
	body.position=at
	var collision:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=size
	collision.shape=box
	body.add_child(collision)
	add_child(body)
	return body

func _run() -> void:
	var sim: WroughtwildSim=load("res://scripts/sim.gd").shared()
	check(sim.contraption_bind_world("legacy_v1",1),"older world permits hand-wound feeder without retrofitted source")
	sim.add_station("forge_basic")
	sim.add_materials({"pressure_feeder_kit":1})
	var floor:=_floor(Vector3(0,-.5,0),Vector3(20,1,20))
	var player: WroughtwildPlayer=preload("res://scenes/player.tscn").instantiate()
	player.position=Vector3(-3,1.2,0)
	add_child(player)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	var forge: StationSite=preload("res://scenes/station_site.tscn").instantiate()
	forge.station_id=&"forge_basic"
	forge.position=Vector3(3.5,0,.5)
	forge.station_key=StationSite.key_at("forge_basic",forge.position)
	add_child(forge)
	check(sim.contraption_place("pressure_feeder","presentation_feeder",Vector3(.5,0,.5),0),"paid feeder placement has native owner")
	var feeder:=ContraptionSite.new()
	feeder.machine_key="presentation_feeder"
	feeder.sim=sim
	add_child(feeder)
	feeder.set_physics_process(false)
	for frame in 3:await get_tree().physics_frame
	check(not feeder.attach_feeder(forge.station_key,"").ok,"global station unlock does not make an unowned physical forge eligible")
	forge.player_built=true
	check(feeder.attach_feeder(forge.station_key,"").ok,"player-owned supported forge attaches in an older world")
	var visual:=StrangeResourceArt.fixture_mesh("pressure_feeder")
	var envelope:=AABB(Vector3(-.75,0,-.725),ContraptionSite.bounds_for("pressure_feeder"))
	check(envelope.grow(.015).encloses(visual.get_aabb()),"shared preview and authored assembly fit physical feeder envelope")
	check(feeder._visual.has_node("Hopper") and feeder._visual.has_node("Drum") and feeder._visual.has_node("Bellows") and feeder._visual.has_node("OutputTray"),"load, drive and output have distinct visible components")
	check(not feeder._hopper_load.visible and not feeder._output_load.visible,"empty hopper and tray do not display phantom stock")
	feeder.interact(player)
	check(player.work_panel.is_open() and player.work_panel._custom_title=="Pressure feeder","normal fixture interaction opens feeder controls")
	player.work_panel.close_panel()
	sim.add_materials({"raw_clay":8,"wood":1})
	sim.contraption_deposit(feeder.machine_key,"raw_clay",8)
	sim.contraption_deposit(feeder.machine_key,"wood",1)
	feeder.refresh_from_sim()
	check(feeder._hopper_load.visible and not feeder._output_load.visible,"physical input is visible before completed output exists")
	check(feeder.perform("wind").ok and feeder.perform("start").ok,"hand control reserves existing recipe")
	feeder._physics_process(1.0)
	var reserved:=sim.contraption_save()
	var obstruction:=_floor(Vector3(2,.85,.5),Vector3(.3,1,.8))
	for frame in 3:await get_tree().physics_frame
	check(not feeder.feeder_status().ready,"real connection obstruction is detected")
	feeder._physics_process(4.0)
	check(sim.contraption_save()==reserved,"obstruction pauses exact escrow clock")
	obstruction.free()
	for frame in 2:await get_tree().physics_frame
	feeder._physics_process(8.0)
	check(feeder._output_load.visible,"completed bricks become visible in the real tray")
	sim.add_materials({"stormglass_lever_kit":1,"raw_clay":8,"wood":1})
	check(sim.contraption_place("stormglass_lever","presentation_lever",Vector3(-2.5,0,2.5),0),"existing lever kit places normally")
	var lever:=ContraptionSite.new()
	lever.machine_key="presentation_lever"
	lever.sim=sim
	add_child(lever)
	lever.set_physics_process(false)
	for frame in 2:await get_tree().physics_frame
	check(sim.contraption_link(lever.machine_key,feeder.machine_key,lever.link_clear(feeder)).ok,"existing signal receiver accepts the feeder")
	sim.contraption_deposit(feeder.machine_key,"raw_clay",8)
	sim.contraption_deposit(feeder.machine_key,"wood",1)
	feeder.perform("wind")
	obstruction=_floor(Vector3(2,.85,.5),Vector3(.3,1,.8))
	for frame in 2:await get_tree().physics_frame
	check(not lever.perform("pulse").ok and int(sim.contraption_state(feeder.machine_key).escrow_drive)==0,"lever cannot bypass an obstructed forge connection")
	obstruction.free()
	for frame in 2:await get_tree().physics_frame
	check(lever.perform("pulse").ok and int(sim.contraption_state(feeder.machine_key).escrow_drive)==1,"clear lever requests one powered firing")
	check(feeder.perform("cancel").ok,"local cancel returns signalled firing escrow")
	var cancelled:=sim.contraption_save()
	check(not feeder.perform("cancel").ok and sim.contraption_save()==cancelled,"repeated local cancel cannot return stock twice")
	var original_key:=forge.station_key
	forge.position.x+=8
	check(not feeder.feeder_status().ready,"a moved forge invalidates its saved physical attachment")
	forge.position.x-=8
	check(forge.station_key==original_key,"physical station identity does not change with display inspection")
	# A narrow strip supports the centre but leaves one pair of feet hanging.
	floor.free()
	_floor(Vector3(.5,-.5,.5),Vector3(.3,1,2))
	_floor(Vector3(3.5,-.5,.5),Vector3(2,1,2))
	for frame in 3:await get_tree().physics_frame
	check(not feeder.feeder_status().ready,"centre support cannot hide unsupported machine feet")
	print("PRESSURE_FEEDER_PRESENTATION %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
