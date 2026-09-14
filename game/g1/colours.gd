class_name G1Colours
extends Node3D
## The four F5 source/component/fixture families read their existing native owner.
var colour := "red"
var source: LeylineSource
var site: ContraptionSite
var mineral: ShaderMaterial
var claims: Node3D
var clock := 0.0
var work_clock := 0.0
var previous_progress := 0.0
var previous_cycles := 0
var last_pulses := 0
var event_left := 0.0
var settings: Dictionary
var core_materials: Array[ShaderMaterial]=[]
var first_sent:=false
var second_sent:=false

func parameter(key: String, value: Variant) -> void:
	mineral.set_shader_parameter(key,value)
	for mat in core_materials:mat.set_shader_parameter(key,value)

func blue_released() -> void:
	# Called only from a native request tick that consumes a pending request.
	# Cancellation, disconnection and restore do not call this hook.
	event_left=float(settings.presentation.release_seconds)

static func fixture(kind: String) -> Node3D:
	var root:=G1Colours.new()
	root.colour=kind.split("_")[0]
	root.name="StrangeFixtureVisual"
	root.add_model("buffer" if root.colour=="red" else "post")
	return root

static func mount_source(owner_node: LeylineSource) -> void:
	if owner_node.has_node("G1Source"): return
	var root:=G1Colours.new()
	root.name="G1Source"
	root.source=owner_node
	root.colour=String(owner_node.state().material).split("_")[0]
	for child in owner_node.get_children():
		if child is MeshInstance3D and child!=owner_node._claim: child.hide()
	owner_node._crystals.hide()
	root.add_model("source")
	owner_node.add_child(root)
	root.claims=Node3D.new()
	root.add_child(root.claims)
	for i in 3:
		var fragment: Node3D=R2Resources.resource("res://f5/"+root.colour+"/"+root.colour+"-fragment-%d.glb"%(i+1)).instantiate()
		root.claims.add_child(fragment)
		fragment.position=Vector3(-.28+i*.24,.002,.66)
		fragment.scale=Vector3.ONE*.52
		root.bind_mineral(fragment,root.scar("fragment-%d"%(i+1)))

func scar(prefix: String="") -> ShaderMaterial:
	if settings.is_empty(): settings=JSON.parse_string(FileAccess.get_file_as_string("res://f5/"+colour+"/"+colour+".json"))
	if prefix.is_empty(): prefix=colour
	var mat:=ShaderMaterial.new()
	mat.shader=R2Resources.resource("res://f5/"+colour+"/"+colour+"_scar.gdshader")
	for pair in [["base_texture","base"],["orm_texture","orm"],["scar_texture","scar"],["normal_texture","normal"]]:
		mat.set_shader_parameter(pair[0],R2Resources.resource("res://f5/"+colour+"/"+prefix+"-"+pair[1]+".png"))
	for key in ["period_seconds","minimum_light","peak_emission"]: mat.set_shader_parameter(key,settings.scar[key])
	var rgb: Array=settings.scar.colour_srgb
	mat.set_shader_parameter("core_colour",Color(rgb[0],rgb[1],rgb[2]))
	mat.set_shader_parameter("native_gain",float(settings.presentation.get("claim_gain",.3)))
	mat.set_shader_parameter("state_mode",1)
	return mat

func add_model(role: String) -> void:
	var integration:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://g1/settings.json"))
	var model: Node3D=R2Resources.resource("res://f5/"+colour+"/"+colour+"-"+role+"-"+String(integration.colour_lod)+".glb").instantiate()
	add_child(model)
	mineral=scar()
	bind_mineral(model,mineral)
	if role!="source":
		var housing:=model.find_children("*HOUSING*","MeshInstance3D",true,false)
		assert(housing.size()==1,"One actual F5 structural housing")
		housing[0].name="Housing"
	if role=="post" and colour=="green":
		var geometry:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://f5/green/asset-report.json"))
		for mesh in model.find_children("*CORE*","MeshInstance3D",true,false):
			var i:=0 if "stem" in String(mesh.name) else 1 if "first" in String(mesh.name) else 2
			var mat:=scar("fragment-%d"%(i+1))
			mat.set_shader_parameter("branch_override",i*.5)
			mat.set_shader_parameter("height_local",geometry.post.cores[i].height_local)
			mat.set_shader_parameter("flow_start",0.0 if i==0 else .42)
			mat.set_shader_parameter("flow_span",.42 if i==0 else .58)
			mesh.material_override=mat;core_materials.append(mat)

func bind_mineral(node: Node, mat: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var old: Material=node.get_active_material(i)
			if old!=null and old.resource_name.to_upper().begins_with(colour.to_upper()+"_"): node.set_surface_override_material(i,mat)
	for child in node.get_children(): bind_mineral(child,mat)

func _ready() -> void:
	if get_parent() is ContraptionSite:
		site=get_parent()
		var record:=site.sim.contraption_state(site.machine_key)
		last_pulses=int(record.get("pulses",0))
		var feeder:=site.sim.contraption_state(String(record.get("link","")))
		previous_progress=float(feeder.get("cycle_seconds",0))
		previous_cycles=int(feeder.get("completed_cycles",0))

func _process(delta: float) -> void:
	clock+=delta
	parameter("cosmetic_clock",clock)
	if source!=null:
		var record:=source.state()
		var ready: bool=int(record.lot)<int(record.lots) and record.claim.is_empty() and source.supported()
		parameter("state_mode",2 if ready else 0)
		parameter("native_gain",settings.presentation.source_work_gain if int(record.work)>0 else settings.presentation.source_ready_gain)
		if claims!=null: claims.visible=int(record.claim.get(record.material,0))>0
		source._claim.visible=record.claim.has(record.rare_item)
		source._crystals.hide()
	elif site!=null:
		var record:=site.sim.contraption_state(site.machine_key)
		if record.is_empty(): return
		var duration: float=settings.presentation.get("passage_seconds",1.05) if colour=="green" else settings.presentation.get("release_seconds",.65) if colour=="blue" else settings.presentation.get("request_seconds",.85)
		if colour in ["white","green"] and int(record.get("pulses",0))>last_pulses:
			event_left=duration
			if colour=="green":
				var space:=site.signal_space()
				first_sent=not String(record.link).is_empty() and bool(space.get("first_link",false))
				second_sent=not String(record.second_link).is_empty() and bool(space.get("second_link",false))
		last_pulses=int(record.get("pulses",0))
		event_left=maxf(0,event_left-delta)
		parameter("request_fraction",1.0-event_left/duration)
		parameter("passage_fraction",1.0-event_left/duration)
		parameter("first_sent",first_sent)
		parameter("second_sent",second_sent)
		parameter("state_mode",3 if event_left>0 else 0)
		parameter("native_gain",1.0 if event_left>0 else 0.0)
		if colour=="blue":
			var pending:=bool(record.get("pending_request",false))
			parameter("state_mode",3 if pending else 4 if event_left>0 else 0)
			parameter("request_fraction",float(record.delay_seconds)/float(site.sim.contraption_config().delay_seconds))
			parameter("release_fraction",1.0-event_left/duration)
			parameter("native_gain",1.0 if pending or event_left>0 else 0.0)
		if colour=="red":
			var feeder:=site.sim.contraption_state(String(record.get("link","")))
			var linked: bool=String(feeder.get("heat_key",""))==site.machine_key
			var progress:=float(feeder.get("cycle_seconds",0)) if linked else 0.0
			var cycles:=int(feeder.get("completed_cycles",0)) if linked else 0
			var advanced: float=(cycles-previous_cycles)*float(site.sim.contraption_config().feeder_cycle_seconds)+progress-previous_progress
			previous_progress=progress;previous_cycles=cycles
			if advanced>0: work_clock+=advanced
			var held:=int(record.get("heat",0))+(int(feeder.get("escrow_heat",0)) if linked else 0)
			parameter("work_clock",work_clock)
			parameter("state_mode",3 if advanced>0 else 1 if held>0 else 0)
			parameter("native_gain",float(settings.presentation.working_gain) if advanced>0 else float(settings.presentation.stored_gain)*held/float(site.sim.contraption_config().heat_capacity))

const R2Resources=preload("res://r2/resources.gd")
