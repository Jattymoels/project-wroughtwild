class_name Conservator
extends Boss
## Dedicated human harness encounter. Boss ancestry supplies the existing
## damage/status classification; none of the Warden's attack loop is used.
var channel := ""
var sequence_index := 0
var channel_left := 0.0
var channel_total := 0.0
var recovery_left := 0.0
var committed_origin := Vector3.ZERO
var committed_mark := Vector3.ZERO
var committed_directions: Array[Vector3] = []
var channel_tells: Array[MeshInstance3D] = []
var arms: Array[Node3D] = []
var harness: MeshInstance3D
var releases := 0
var drains := 0
var _pose_time := 0.0

func rule(key: String) -> float:
	return float(_trial_rules["conservator_"+key])

func configure(sim: WroughtwildSim) -> void:
	_sim=sim
	var definition:=sim.boss()
	_trial_rules=sim.trial_rules()
	enemy_id=definition.id
	display_name=definition.display_name
	behaviour="boss"
	max_life=definition.max_life
	life=max_life
	damage=definition.claw_damage
	damage_type=definition.claw_damage_type
	breath_damage=definition.breath_damage
	breath_damage_type=definition.breath_damage_type
	move_speed=rule("move_speed_mps")
	vertical_reach=float(sim.realtime().horde.vertical_reach_m)
	jump_speed=0
	_configure_statuses(sim)
	_material=ArtGeometry.material()
	_base_albedo=Color.WHITE # The authored vertices already carry skin/coat colour.
	_material.albedo_color=_base_albedo
	_mesh.material_override=_material
	_build_human()
	state="chase"
	recovery_left=rule("opening_seconds")
	died.connect(_cancel_on_death)
	_refresh_label()

func configure_trial(controller: Node, rules: Dictionary) -> void:
	trial_controller=controller
	_trial_rules=rules
	controller.build_release_pedestals()

func _build_human() -> void:
	# Human shoulders, head, coat, hands and separate jointed arms; no Warden
	# mesh, motion adapter or third-party asset. Dimensions are presentation.
	var st:=ArtGeometry.begin()
	ArtGeometry.box(st,Vector3(0,1.35,0),Vector3(.66,.85,.4),Color("545b53"))
	ArtGeometry.box(st,Vector3(0,1.0,0),Vector3(.8,.35,.48),Color("3c4442"))
	ArtGeometry.box(st,Vector3(0,2.04,-.04),Vector3(.36,.45,.34),Color("b0a28a"))
	for side in [-1.0,1.0]:
		ArtGeometry.box(st,Vector3(side*.08,2.1,-.217),Vector3(.065,.035,.02),Color("303631"))
	for side in [-1.0,1.0]:
		ArtGeometry.box(st,Vector3(side*.2,.43,0),Vector3(.24,.84,.28),Color("434944"))
		ArtGeometry.box(st,Vector3(side*.2,.09,-.1),Vector3(.29,.18,.48),Color("323b39"))
		ArtGeometry.box(st,Vector3(side*.26,1.47,-.24),Vector3(.08,.72,.08),Color("262f31"))
	_mesh.mesh=st.commit()
	_mesh.position=Vector3.ZERO
	for side in [-1.0,1.0]:
		var joint:=Node3D.new()
		_mesh.add_child(joint)
		joint.position=Vector3(side*.43,1.7,0)
		var part:=MeshInstance3D.new()
		var limb:=ArtGeometry.begin()
		ArtGeometry.box(limb,Vector3(0,-.32,0),Vector3(.23,.64,.26),Color("61685b"))
		ArtGeometry.box(limb,Vector3(0,-.72,-.06),Vector3(.18,.26,.22),Color("b0a28a"))
		part.mesh=limb.commit()
		part.material_override=_material
		joint.add_child(part)
		arms.append(joint)
	var scar:=ArtGeometry.begin()
	for i in 5:
		ArtGeometry.box(scar,Vector3((i%2)*.055,1.34+i*.15,-.225),Vector3(.025,.2,.03),Color.WHITE)
	ArtGeometry.box(scar,Vector3(.08,2.07,-.225),Vector3(.025,.32,.03),Color.WHITE)
	harness=MeshInstance3D.new()
	harness.name="HarnessScars"
	harness.mesh=scar.commit()
	var glow:=StandardMaterial3D.new()
	glow.emission_enabled=true
	glow.emission_energy_multiplier=.8
	harness.material_override=glow
	_mesh.add_child(harness)

func _physics_process(delta: float) -> void:
	if life<=0: return
	if not is_on_floor(): velocity+=get_gravity()*delta
	var stopped:=_tick_statuses(delta)
	if life<=0: return
	var player:=_find_player()
	velocity.x=0
	velocity.z=0
	if stopped or player==null:
		move_and_slide()
		return
	if recovery_left>0:
		recovery_left=maxf(0,recovery_left-delta)
		if recovery_left==0: state="chase"; _refresh_label()
	elif not channel.is_empty():
		channel_left-=delta
		for tell in channel_tells:
			(tell.get_node("TellBoundary") as ForgeTell).set_warning(channel_left,channel_total)
		if channel_left<=0:
			if channel=="blue":
				channel="red"
				channel_total=rule("red_warning_seconds")
				channel_left=channel_total
				_colour_tells(Color("ee8053"))
				_refresh_label()
			else: _release(player)
	else:
		var to: Vector3=(player.global_position-global_position)*Vector3(1,0,1)
		if to.length()<=rule("engage_range_m") and _vertical_gap_to(player)<=vertical_reach:
			_begin_channel(player)
		else:
			var walk:=_chase_direction(player,to.length())*move_speed*status_move_multiplier()
			velocity.x=walk.x;velocity.z=walk.z
			if to.length()>.01: look_at(global_position+to)
	move_and_slide()
	_pose_time+=delta
	for i in arms.size():
		arms[i].rotation.x=-1.4 if not channel.is_empty() else sin(_pose_time*5+i*PI)*(.22 if velocity.length()>1 else .03)
		arms[i].rotation.z=(i*2-1)*(.6 if channel=="green" else .08)

func _begin_channel(player: WroughtwildPlayer) -> void:
	committed_origin=global_position
	committed_mark=player.global_position
	committed_mark.y=committed_origin.y
	var forward: Vector3=(committed_mark-committed_origin).normalized()
	if forward.length()<.01: forward=-global_basis.z
	look_at(global_position+forward)
	committed_directions.clear()
	var selected:=sequence_index%3
	sequence_index+=1
	channel=["white","blue","green"][selected]
	state="channel"
	channel_total=rule("blue_hold_seconds" if channel=="blue" else channel+"_warning_seconds")
	channel_left=channel_total
	if selected==1:
		_make_tell(committed_mark,ForgeTell.disc(rule("mark_radius_m")))
	else:
		for angle in ([-rule("branch_angle_degrees"),rule("branch_angle_degrees")] if selected==2 else [0.0]):
			var direction:=forward.rotated(Vector3.UP,deg_to_rad(angle))
			committed_directions.append(direction)
			var tell:=_make_tell(committed_origin+direction*rule("lane_length_m")*.5,ForgeTell.lane(Vector2(rule("lane_width_m"),rule("lane_length_m"))))
			tell.look_at(tell.global_position+direction)
	_colour_tells({"white":Color("e6e2c8"),"blue":Color("71bae7"),"green":Color("87cf99")}[channel])
	if is_instance_valid(trial_controller): trial_controller.boss_tells+=1
	_refresh_label()
	player.hud.notify({"white":"White impulse — leave the committed lane.","blue":"Blue holds this mark. Red will release here — leave the ring.","green":"Green branches the impulse — read the two lanes and their gap."}[channel])

func _make_tell(at: Vector3, points: PackedVector2Array) -> MeshInstance3D:
	var tell:=MeshInstance3D.new()
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()-1):
		for p in [points[0],points[i+1],points[i]]: st.add_vertex(Vector3(p.x,.06,p.y))
	st.generate_normals()
	tell.mesh=st.commit()
	tell.material_override=ForgeTell.LOOK.fill()
	tell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(tell)
	tell.global_position=at
	ForgeTell.attach(tell,points)
	channel_tells.append(tell)
	return tell

func _colour_tells(colour: Color) -> void:
	for tell in channel_tells:
		var boundary:=tell.get_node("TellBoundary") as ForgeTell
		boundary.stroke.set_shader_parameter("warning_colour",colour)
		boundary.stroke.set_shader_parameter("progress_colour",colour.lightened(.2))
	var material:=harness.material_override as StandardMaterial3D
	material.albedo_color=colour
	material.emission=colour

func _release(player: WroughtwildPlayer) -> void:
	var hit:=false
	if channel=="red":
		hit=((player.global_position-committed_mark)*Vector3(1,0,1)).length()<=rule("mark_radius_m")
	else:
		var offset: Vector3=(player.global_position-committed_origin)*Vector3(1,0,1)
		for direction in committed_directions:
			var along:=offset.dot(direction)
			if along>=0 and along<=rule("lane_length_m") and absf(offset.dot(Vector3(-direction.z,0,direction.x)))<=rule("lane_width_m")*.5: hit=true
	var release_kind:=channel
	releases+=1
	attack_released.emit(channel)
	if hit and _vertical_gap_to(player)<=vertical_reach:
		var query:=PhysicsRayQueryParameters3D.create(committed_origin+Vector3.UP,player.global_position+Vector3.UP)
		query.exclude=[self]
		var obstruction:=get_world_3d().direct_space_state.intersect_ray(query)
		if obstruction.is_empty() or obstruction.collider==player:
			player.combat.take_hit(breath_damage if release_kind=="red" else damage,breath_damage_type if release_kind=="red" else damage_type,display_name,self)
	_recover(rule("recovery_seconds"))

func _clear_channel() -> void:
	for tell in channel_tells:
		if is_instance_valid(tell): tell.hide(); tell.queue_free()
	channel_tells.clear()
	channel=""
	channel_left=0

func _recover(seconds: float) -> void:
	_clear_channel()
	recovery_left=seconds
	state="recover"
	_refresh_label()

func drain_channel() -> bool:
	if life<=0 or channel.is_empty(): return false
	drains+=1
	_recover(rule("release_recovery_seconds"))
	return true

func stagger(seconds: float) -> void:
	super.stagger(seconds)
	if seconds>0 and life>0 and not channel.is_empty(): _recover(rule("recovery_seconds"))

func _on_frozen() -> void:
	if not channel.is_empty(): _recover(rule("recovery_seconds"))

func _cancel_on_death(_enemy: Enemy) -> void:
	_clear_channel()

func _exit_tree() -> void:
	_clear_channel()

func _refresh_label() -> void:
	if _label!=null:
		var phase: String={"white":"WHITE — SIDE STEP","blue":"BLUE — HELD MARK","red":"RED — LEAVE MARK","green":"GREEN — TWO BRANCHES"}.get(channel,"RECOVERING" if recovery_left>0 else "")
		_label.text="%s  %d / %d\n%s" % [display_name,ceili(life),ceili(max_life),phase]
