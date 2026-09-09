class_name Boss
extends Enemy
## The Forge Tyrant. Numbers come from the sim's boss definition (life, claw,
## breath, periods) and the realtime boss table (speed, ranges, telegraph).
## Claws on its own cadence when in reach; on a slower schedule it inhales
## (the telegraph) and then breathes fire over a cone. Dashing through the
## telegraph, or being outside the cone, avoids the breath; resistance is
## what makes the hits you cannot avoid survivable.

var breath_damage := 0.0
var breath_damage_type := "fire"
var breath_period_seconds := 2.0
var breath_range := 9.0
var breath_cone_degrees := 70.0
var breath_telegraph_seconds := 1.0

## chase | windup | inhale
var _breath_timer := 0.0
var _telegraph_left := 0.0
var _base_material: StandardMaterial3D
var _telegraph_material: StandardMaterial3D
var _trial_rules: Dictionary={}
var _trial_kind:=""
var _recovery_left:=0.0
var _floor_tell: MeshInstance3D
var _tell_boundary: ForgeTell


static func spawn_boss(root: Node, at: Vector3) -> Boss:
	var human:=String(load("res://scripts/sim.gd").shared().boss().get("id",""))=="conservator"
	var scene: PackedScene = load("res://scenes/conservator.tscn" if human else "res://scenes/boss.tscn")
	var boss: Boss = scene.instantiate()
	boss.position=at
	root.add_child(boss)
	boss.global_position = at
	return boss


func configure(sim: WroughtwildSim) -> void:
	_sim=sim
	var def: Dictionary = sim.boss()
	var rt: Dictionary = sim.realtime()
	var boss_rt: Dictionary = rt["boss"]
	var speed_multiplier: float = sim.combat_mods()["enemy_speed_multiplier"]

	enemy_id = def["id"]
	display_name = def["display_name"]
	behaviour = "boss"
	max_life = def["max_life"]
	life = max_life
	damage = def["claw_damage"]
	damage_type = def["claw_damage_type"]
	attack_period_seconds = def["claw_period_rounds"] * rt["round_seconds"] / speed_multiplier
	move_speed = boss_rt["move_speed_mps"] * speed_multiplier
	attack_range = boss_rt["claw_range_m"]
	windup_seconds = boss_rt["claw_windup_seconds"]
	aggro_range = 40.0

	breath_damage = def["breath_damage"]
	breath_damage_type = def["breath_damage_type"]
	breath_period_seconds = def["breath_period_rounds"] * rt["round_seconds"]
	breath_range = boss_rt["breath_range_m"]
	breath_cone_degrees = boss_rt["breath_cone_degrees"]
	breath_telegraph_seconds = boss_rt["breath_telegraph_seconds"]
	_breath_timer = breath_period_seconds

	_configure_statuses(sim)
	vertical_reach = rt.get("horde", {}).get("vertical_reach_m", 2.5)
	jump_speed = rt.get("horde", {}).get("jump_speed_mps", 5.0)

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(0.45, 0.08, 0.05)
	_telegraph_material = StandardMaterial3D.new()
	_telegraph_material.albedo_color = Color(1.0, 0.5, 0.1)
	_telegraph_material.emission_enabled = true
	_telegraph_material.emission = Color(1.0, 0.4, 0.05)
	_telegraph_material.emission_energy_multiplier = 3.0
	# The status looks (ice, fire, blood) paint the base material, so the
	# shared _refresh_look works on the boss too; the telegraph is its own
	# override on top.
	_material = _base_material
	_base_albedo = _base_material.albedo_color
	_mesh.material_override = _base_material
	_mesh.mesh = preload("res://art/character_look.tres").build("boss")
	_mesh.position.y = 0.0
	_mesh.scale = Vector3(1.9,1.87,1.9)
	CreatureMotion.attach(_mesh,self,"boss")
	for material in [_base_material,_telegraph_material]:
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		material.roughness = 1.0
	state = "chase"
	if not died.is_connected(_on_tell_owner_died): died.connect(_on_tell_owner_died)
	_refresh_label()

func configure_trial(controller: Node, rules: Dictionary) -> void:
	trial_controller=controller
	_trial_rules=rules
	# Forge floors are level and navigated around cover. Hopping against a
	# support enemy would lift the committed attack tell off its floor.
	jump_speed=0.0
	_trial_kind=String(controller.layout.get("run_id","forge_tyrant"))
	if String(enemy_id)!="forge_tyrant":
		verb="guard"
		verb_arc=float(rules.get("boss_guard_arc_degrees",130))
		verb_strength=float(rules.get("boss_guard_reduction",.45))
		breath_damage_type="physical"
		_base_material.albedo_color=Color("62695e")
		_base_albedo=_base_material.albedo_color
	if _trial_kind=="forge_capstone": controller.build_conduits()

func _begin_trial_tell() -> void:
	if not is_instance_valid(trial_controller): return
	trial_controller.boss_tells+=1
	_end_trial_tell()
	_floor_tell=MeshInstance3D.new()
	_floor_tell.name="BossFloorTell"
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arc:=deg_to_rad(breath_cone_degrees)*.5
	for i in 16:
		var a:=lerpf(-arc,arc,float(i)/16)
		var b:=lerpf(-arc,arc,float(i+1)/16)
		surface.add_vertex(Vector3(0,.06,0))
		surface.add_vertex(Vector3(sin(b)*breath_range,.06,-cos(b)*breath_range))
		surface.add_vertex(Vector3(sin(a)*breath_range,.06,-cos(a)*breath_range))
	surface.generate_normals()
	_floor_tell.mesh=surface.commit()
	_floor_tell.material_override=ForgeTell.LOOK.fill()
	_floor_tell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_floor_tell)
	_tell_boundary=ForgeTell.attach(_floor_tell,ForgeTell.cone(breath_range,breath_cone_degrees))
	_tell_boundary.set_warning(_telegraph_left,breath_telegraph_seconds)

func _end_trial_tell() -> void:
	if is_instance_valid(_floor_tell):
		_floor_tell.hide()
		_floor_tell.queue_free()
	_floor_tell=null
	_tell_boundary=null

func _on_tell_owner_died(_enemy: Enemy) -> void:
	_end_trial_tell()


## Freezing a boss (through its buildup resistance) interrupts everything,
## an inhale included - the earned reward is a stopped breath.
func _on_frozen() -> void:
	super()
	if state == "inhale":
		state = "chase"
		_telegraph_left = 0.0
		_mesh.material_override = _base_material
		_refresh_label()
		_end_trial_tell()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Shared status clocks (enemy.gd): a frozen boss stands, thaws, and takes
	# its DoT ticks like anything else - only its buildup resistance differs.
	if _tick_statuses(delta):
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_shove(delta)
		move_and_slide()
		return
	var player := _find_player()
	if player == null:
		_apply_shove(delta)
		move_and_slide()
		return

	var distance := _horizontal_distance_to(player)
	var in_reach := _vertical_gap_to(player) <= vertical_reach
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var planar := Vector3.ZERO
	var was_recovering:=_recovery_left>0
	_recovery_left=maxf(0,_recovery_left-delta)
	if was_recovering and _recovery_left<=0: _refresh_label()
	if _recovery_left>0:
		velocity.x=0
		velocity.z=0
		move_and_slide()
		return

	match state:
		"chase":
			_breath_timer -= delta
			if _breath_timer <= 0.0 and distance <= breath_range * 1.2 and in_reach:
				state = "inhale"
				_telegraph_left = breath_telegraph_seconds
				_mesh.material_override = _telegraph_material
				_refresh_label()
				if trial_bound: _begin_trial_tell()
				player.hud.notify("%s commits a heavy sweep. Leave its marked arc!" % display_name if trial_bound and breath_damage_type!="fire" else "%s inhales deeply. Fire is coming!" % display_name)
			elif distance <= attack_range and in_reach and _attack_cooldown <= 0.0:
				state = "windup"
				_windup_left = windup_seconds
			else:
				planar = _chase_direction(player, distance) * move_speed
		"windup":
			_windup_left -= delta
			if _windup_left <= 0.0:
				attack_released.emit("strike")
				if distance <= attack_range * 1.15 and in_reach:
					player.combat.take_hit(damage, damage_type, display_name, self)
				_attack_cooldown = attack_period_seconds
				state = "chase"
		"inhale":
			_telegraph_left -= delta
			if is_instance_valid(_tell_boundary): _tell_boundary.set_warning(_telegraph_left,breath_telegraph_seconds)
			if _telegraph_left <= 0.0:
				breathe(player)

	planar *= status_move_multiplier()
	velocity.x = planar.x
	velocity.z = planar.z
	_hop_if_blocked(planar)
	if state != "inhale" and (not trial_bound or state!="windup"):
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	_apply_shove(delta)
	move_and_slide()


func _in_breath_cone(player: Node3D) -> bool:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > breath_range or to_player.length() < 0.001:
		return false
	var angle := rad_to_deg(forward.normalized().angle_to(to_player.normalized()))
	return angle <= breath_cone_degrees * 0.5


## Ends the telegraph: fire lands on a player inside the cone. Returns the
## damage the player actually took (0 when out of the cone or dashing).
func breathe(player: WroughtwildPlayer) -> float:
	attack_released.emit("breath")
	state = "chase"
	_breath_timer = breath_period_seconds
	if trial_bound and is_instance_valid(trial_controller):
		_end_trial_tell()
		_recovery_left=float(_trial_rules.get("boss_recovery_seconds",2.2))*float(trial_controller.run_mods.get("boss_recovery_multiplier",1))
		_breath_timer*=float(trial_controller.run_mods.get("boss_recovery_multiplier",1))
	_mesh.material_override = _base_material
	_refresh_label()
	if not _in_breath_cone(player):
		player.hud.notify("The sweep passes you." if breath_damage_type!="fire" else "The fire washes past you.")
		return 0.0
	if trial_bound:
		var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,player.global_position+Vector3.UP)
		query.exclude=[self]
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.get("collider")!=player: return 0.0
	return player.combat.take_hit(breath_damage, breath_damage_type, display_name, self)

func guards_against(from: Vector3) -> bool:
	return _recovery_left<=0 and state!="inhale" and super(from)


## Test hook: begin the telegraph immediately.
func force_inhale() -> void:
	state = "inhale"
	_telegraph_left = breath_telegraph_seconds
	_mesh.material_override = _telegraph_material
	_refresh_label()


func _refresh_label() -> void:
	if _label != null:
		var tag := ""
		if life>0:
			if state=="inhale": tag="  (FIRE)" if breath_damage_type=="fire" else "  (SWEEP)"
			elif _recovery_left>0: tag="  (RECOVERING)"
		_label.text = "%s  %d / %d%s" % [display_name, ceili(life), ceili(max_life), tag]
