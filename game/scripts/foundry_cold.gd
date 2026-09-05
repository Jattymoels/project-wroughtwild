class_name FoundryCold
extends Node3D
## Frost controls contact and flight; Preserving stores time and positions.
## Numbers and packet scaling come from the sim. No secondary event casts skills.
var combat: PlayerCombat
var skill_id: StringName
var mode := "ring"
var rules: Dictionary
var target: Enemy
var remaining := 0.0
var duration := 0.0
var radius := 1.0
var direction := Vector3.FORWARD
var visited := {}
var left_bed := false
var amount := 0.0
var pulse_left := 0.0
var pulses := 0
var visual: MeshInstance3D
var tint: StandardMaterial3D
var vapour: ShaderMaterial

static func contact(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	var chilled := enemy.chill>0 or enemy.is_frozen()
	var at := enemy.global_position+Vector3.UP*.5
	var limits: Dictionary=form.limits
	var operations := {"ring":"rime_ring_buildup","edge":"rime_edge_fraction","whiteout":"whiteout_slow","skin":"cold_sap_absorb","bind":"permafrost_seconds","reservoir":"reservoir_seconds","afterfield":"afterfield_fraction"}
	for kind in operations:
		var prop: String=operations[kind]
		if float(form.get(prop,0))<=0: continue
		if kind not in ["ring","afterfield"] and not chilled: continue
		if kind in ["bind","reservoir"] and enemy._immune_statuses.has("chill"): continue
		var cooldown := float(limits.memory_cooldown) if kind in ["reservoir","afterfield"] else float(limits.cold_charge_cooldown) if kind=="skin" else float(limits.cold_contact_cooldown)
		if FoundryReactions._commit(owner_combat,context,"cold_"+kind,cooldown): spawn(owner_combat,skill,kind,at,form,enemy)
	if float(form.get("wound_memory_seconds",0))>0 and enemy.bleeding_left>0 and not enemy._wound_memory_used:
		if FoundryReactions._commit(owner_combat,context,"wound_memory",float(limits.memory_cooldown)): spawn(owner_combat,skill,"wound",at,form,enemy)
	if float(form.get("emberbed_seconds",0))>0 and enemy.burning_left>0:
		if FoundryReactions._commit(owner_combat,context,"emberbed",float(limits.memory_cooldown)):
			var bed := spawn(owner_combat,skill,"emberbed",at,form,enemy)
			if bed!=null:
				var seconds := minf(float(form.emberbed_seconds),enemy.burning_left)
				var rate := enemy._burn_dps
				if enemy._sear>0 and Vector2(enemy.velocity.x,enemy.velocity.z).length()>.5 and enemy.bleeding_left>0: rate*=1+enemy._sear
				bed.rules["stored_fire_damage"]=rate*seconds/bed.pulses
				enemy.burning_left-=seconds
				enemy._refresh_look()
	if float(form.get("hoarfrost_refund",0))>0 and chilled:
		if FoundryReactions._commit(owner_combat,context,"hoarfrost",float(limits.cold_contact_cooldown)):
			var longest: StringName=&""
			var seconds := 0.0
			for id in owner_combat.cooldowns:
				if String(owner_combat.skills.get(id,{}).get("delivery",""))=="dash" and float(owner_combat.cooldowns[id])>seconds:
					longest=id
					seconds=float(owner_combat.cooldowns[id])
			if not longest.is_empty(): owner_combat.cooldowns[longest]=maxf(0,seconds-float(form.hoarfrost_refund))
			FoundryPuff.spawn(owner_combat,at,.5,true)

static func cast(owner_combat: PlayerCombat, skill: StringName, at: Vector3) -> void:
	# Called only by a successful real input cast. Linked/echo casts never enter.
	var memory := live(owner_combat,"tempo")
	if memory!=null and memory.skill_id!=skill:
		owner_combat.cooldowns[memory.skill_id]=maxf(0,float(owner_combat.cooldowns.get(memory.skill_id,0))-memory.amount)
		memory.cancel()
		FoundryPuff.spawn(owner_combat,at,.5,true)
	var form := owner_combat.mutation(skill)
	var operations := {"mirror":"stillwater_fraction","lifebed":"lifebed_life","held":"held_ground_push","tempo":"lingering_refund"}
	for kind in operations:
		if float(form.get(operations[kind],0))<=0: continue
		if owner_combat.reaction_ready("cast_"+kind,float(form.limits.cold_charge_cooldown if kind=="mirror" else form.limits.memory_cooldown)):
			spawn(owner_combat,skill,kind,at,form)

static func killed(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName) -> void:
	var form := owner_combat.mutation(skill)
	if float(form.get("sanctuary_charges",0))>0 and owner_combat.reaction_ready("sanctuary",float(form.limits.memory_cooldown)):
		spawn(owner_combat,skill,"sanctuary",enemy.global_position+Vector3.UP*.5,form)

static func live(owner_combat: PlayerCombat, kind: String) -> FoundryCold:
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_cold"):
		if node.combat==owner_combat and node.mode==kind and node.remaining>0 and not node.is_queued_for_deletion(): return node
	return null

static func spawn(owner_combat: PlayerCombat, skill: StringName, kind: String, at: Vector3, form: Dictionary, victim: Enemy = null) -> FoundryCold:
	var count := 0
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_cold"):
		if node.combat==owner_combat and node.remaining>0 and not node.is_queued_for_deletion(): count += 1
	if count>=int(form.limits.max_cold_memories): return null
	if kind in ["skin","tempo"] and live(owner_combat,kind)!=null: return null
	var node := FoundryCold.new()
	node.combat=owner_combat
	node.skill_id=skill
	node.mode=kind
	node.rules=form.duplicate(true)
	node.target=victim
	var limits: Dictionary=form.limits
	var extension := float(form.get("memory_extension",0))
	node.duration=float(limits.memory_seconds)+extension
	node.radius=owner_combat.mutation_radius(skill,float(limits.memory_radius))
	match kind:
		"ring":
			node.duration=float(limits.rime_ring_seconds)
			node.radius=owner_combat.mutation_radius(skill,float(limits.rime_ring_radius))
		"edge":
			node.duration=float(limits.rime_edge_delay)
			node.radius=owner_combat.mutation_radius(skill,float(limits.rime_edge_length))
		"whiteout":
			node.duration=float(limits.whiteout_seconds)
			node.radius=owner_combat.mutation_radius(skill,float(limits.whiteout_radius))
		"skin":
			node.duration=float(limits.cold_sap_seconds)
			node.amount=float(form.cold_sap_absorb)
		"mirror":
			node.duration=float(limits.stillwater_seconds)
			node.radius=owner_combat.mutation_radius(skill,float(limits.stillwater_radius))
		"needle": node.duration=float(limits.cold_needle_seconds)
		"emberbed":
			node.pulse_left=float(limits.pulse_interval)
			node.pulses=int(limits.emberbed_pulses)+int(floor(extension/node.pulse_left))
			node.duration=node.pulse_left*node.pulses
		"reservoir": node.duration=float(form.reservoir_seconds)+extension
		"bind": node.duration=float(form.permafrost_seconds)
		"lifebed": node.amount=float(form.lifebed_life)
		"tempo": node.amount=float(form.lingering_refund)
	node.remaining=node.duration
	owner_combat.player.world_root().add_child(node)
	node.global_position=at
	if is_instance_valid(victim):
		node.direction=(victim.global_position-owner_combat.player.global_position)*Vector3(1,0,1)
		node.direction=node.direction.normalized() if node.direction.length_squared()>.001 else Vector3.FORWARD
	if kind in ["afterfield","held"]:
		for enemy in owner_combat.alive_enemies():
			if node._inside(enemy.global_position+Vector3.UP*.5): node.visited[enemy.get_instance_id()]=true
	if kind in ["reservoir","bind","wound"]:
		victim._foundry_marks[kind]=node.get_instance_id()
		if kind=="reservoir": victim._reservoir_left=node.duration
		elif kind=="bind":
			victim._rime_bind_left=node.duration
			victim._rime_bind_loss=float(limits.cold_boss_control_factor) if victim is Boss else 1.0
		else:
			victim._wound_memory_left=float(form.wound_memory_seconds)
			victim._wound_memory_used=true
	node._make_visual()
	return node

func _ready() -> void:
	add_to_group("foundry_cold")
	combat.died.connect(cancel)

func cancel() -> void:
	remaining=0
	if is_instance_valid(target) and target._foundry_marks.get(mode,0)==get_instance_id():
		target._foundry_marks.erase(mode)
		if mode=="reservoir": target._reservoir_left=0
		elif mode=="bind": target._rime_bind_left=0
		elif mode=="wound": target._wound_memory_left=0
	queue_free()

func _physics_process(delta: float) -> void:
	advance(delta)

func _inside(at: Vector3) -> bool:
	return global_position.distance_to(at)<=radius and SkillBurst.solid_ray(combat,global_position,at).is_empty()

func advance(delta: float) -> void:
	if is_queued_for_deletion(): return
	if not is_instance_valid(combat) or combat.life<=0:
		cancel()
		return
	var elapsed := minf(maxf(delta,0),remaining)
	remaining=maxf(0,remaining-elapsed)
	if remaining<=0 and mode in ["afterfield","held","lifebed"]:
		cancel()
		return
	if mode in ["bind","reservoir","wound"]:
		if not is_instance_valid(target) or target.life<=0 or target._foundry_marks.get(mode,0)!=get_instance_id():
			cancel()
			return
		global_position=target.global_position+Vector3.UP*.5
		if mode=="bind": remaining=target._rime_bind_left
		elif mode=="reservoir": remaining=target._reservoir_left
		elif target.bleeding_left<=0 or target._wound_memory_left<=0: remaining=0
	elif mode=="ring":
		var edge := radius*(1-remaining/duration)
		for enemy in combat.alive_enemies():
			if visited.has(enemy.get_instance_id()) or global_position.distance_to(enemy.global_position+Vector3.UP*.5)>edge or not _inside(enemy.global_position+Vector3.UP*.5): continue
			visited[enemy.get_instance_id()]=true
			enemy.apply_chill(float(rules.rime_ring_chill_boss if enemy is Boss else rules.rime_ring_chill))
	elif mode=="edge" and remaining<=0:
		var across := direction.cross(Vector3.UP)
		var half_width := combat.mutation_radius(skill_id,float(rules.limits.rime_edge_half_width))
		for enemy in combat.alive_enemies():
			var offset: Vector3=enemy.global_position+Vector3.UP*.5-global_position
			if enemy==target or absf(offset.dot(direction))>half_width or absf(offset.y)>half_width or not _inside(enemy.global_position+Vector3.UP*.5): continue
			if absf(offset.dot(across))>0: _damage(enemy,"rime_edge")
		FoundryPuff.spawn(combat,global_position,radius,true)
	elif mode=="emberbed":
		pulse_left-=elapsed
		while pulse_left<=.00001 and pulses>0:
			pulse_left+=float(rules.limits.pulse_interval)
			pulses-=1
			for enemy in combat.alive_enemies():
				if _inside(enemy.global_position+Vector3.UP*.5): _damage(enemy,"stored")
			FoundryPuff.spawn(combat,global_position,radius*.5,false)
	elif mode in ["afterfield","held"]:
		var entrants: Array=[]
		for enemy in combat.alive_enemies():
			if not visited.has(enemy.get_instance_id()) and _inside(enemy.global_position+Vector3.UP*.5): entrants.append(enemy)
		if not entrants.is_empty():
			if mode=="afterfield":
				for enemy in entrants: _damage(enemy,"afterfield")
			else:
				var enemy: Enemy=entrants.front()
				enemy.shove(enemy.global_position-global_position,float(rules.held_ground_push)*(float(rules.limits.cold_boss_control_factor) if enemy is Boss else 1.0))
			FoundryPuff.spawn(combat,global_position,radius*.6,true)
			cancel()
	elif mode=="lifebed":
		var inside := _inside(combat.player.global_position+Vector3.UP*.5)
		if global_position.distance_to(combat.player.global_position+Vector3.UP*.5)>radius: left_bed=true
		elif left_bed and inside:
			combat.heal(amount)
			FoundryPuff.spawn(combat,global_position,.6,true)
			cancel()
	elif mode=="needle":
		if not is_instance_valid(target) or target.life<=0:
			cancel()
			return
		var to := target.global_position+Vector3.UP*.5
		var next := global_position.move_toward(to,float(rules.limits.cold_needle_speed)*elapsed)
		if not SkillBurst.solid_ray(combat,global_position,next).is_empty():
			cancel()
			return
		global_position=next
		if next.distance_to(to)<.01:
			_damage(target,"stillwater")
			if target.life>0: target.apply_chill(float(rules.stillwater_chill_boss if target is Boss else rules.stillwater_chill))
			cancel()
	_sample()
	if remaining<=0: cancel()

func _damage(enemy: Enemy, prefix: String) -> void:
	var fraction := 1.0
	if enemy.guards_against(global_position): fraction*=1.0-enemy.verb_strength
	var warden: Enemy=enemy.warded_by()
	if warden!=null: fraction*=1.0-warden.verb_strength
	var total := 0.0
	var types := PackedStringArray()
	for key in rules:
		if not String(key).begins_with(prefix+"_") or not String(key).ends_with("_damage"): continue
		var type := String(key).trim_prefix(prefix+"_").trim_suffix("_damage")
		var damage := float(rules[key])
		if damage<=0: continue
		total+=enemy.take_typed(damage*fraction,type)
		types.append(type)
	if total>0: combat.hit_landed.emit(total,1 if enemy.life<=0 else 0,types)

static func absorb(owner_combat: PlayerCombat, damage: float) -> float:
	var skin := live(owner_combat,"skin")
	if skin==null or damage<=0: return damage
	skin.cancel()
	FoundryPuff.spawn(owner_combat,owner_combat.player.global_position+Vector3.UP*.5,.8,true)
	return maxf(0,damage-skin.amount)

## Exact first sphere contact along an already world-limited shot segment.
static func crossing(node: FoundryCold, from: Vector3, to: Vector3) -> float:
	var segment := to-from
	var offset := from-node.global_position
	var a := segment.length_squared()
	var b := offset.dot(segment)
	var c := offset.length_squared()-node.radius*node.radius
	if c<=0: return 0.0 if SkillBurst.solid_ray(node.combat,node.global_position,from).is_empty() else INF
	if a<.000001 or b*b-a*c<0: return INF
	var t := (-b-sqrt(b*b-a*c))/a
	if t<0 or t>1: return INF
	return t if SkillBurst.solid_ray(node.combat,node.global_position,from+segment*t).is_empty() else INF

static func frostbite(tree: SceneTree, from: Vector3, to: Vector3) -> Dictionary:
	var first := INF
	var slow := 0.0
	for node in tree.get_nodes_in_group("foundry_cold"):
		if node.mode!="whiteout" or node.remaining<=0 or node.is_queued_for_deletion(): continue
		var t := crossing(node,from,to)
		if t<first:
			first=t
			slow=float(node.rules.whiteout_slow)
	return {} if first==INF else {"at":first,"slow":slow}

static func intercept(tree: SceneTree, from: Vector3, to: Vector3, shooter: Enemy) -> bool:
	var first := INF
	var ward: FoundryCold
	for node in tree.get_nodes_in_group("foundry_cold"):
		if node.mode not in ["mirror","sanctuary"] or node.remaining<=0 or node.is_queued_for_deletion(): continue
		var t := crossing(node,from,to)
		if t<first:
			first=t
			ward=node
	if ward==null: return false
	ward.cancel()
	var at := from+(to-from)*first
	FoundryPuff.spawn(ward.combat,at,.5,true)
	if ward.mode=="mirror" and is_instance_valid(shooter) and shooter.life>0:
		spawn(ward.combat,ward.skill_id,"needle",at,ward.rules,shooter)
	return true

func _make_visual() -> void:
	var st := ArtGeometry.begin()
	var colour := Color("a8c6c6") if mode in ["ring","edge","whiteout","skin","mirror","needle","bind"] else Color("aea5c1")
	if mode=="emberbed": colour=Color("c28a61")
	if mode=="lifebed": colour=Color("a2b990")
	if mode=="needle":
		ArtGeometry.oval(st,Vector3.ZERO,Vector3(.06,.2,.06),colour)
	elif mode=="edge":
		var across := direction.cross(Vector3.UP)
		var width := combat.mutation_radius(skill_id,float(rules.limits.rime_edge_half_width))/radius
		for sign_value in [-1,1]:
			var tip: Vector3=across*radius*sign_value
			var block := SkillBurst.solid_ray(combat,global_position,global_position+tip)
			if not block.is_empty(): tip=(block.position-global_position)*.95
			tip/=radius
			ArtGeometry.triangle(st,across*.07*sign_value,tip,direction*width*.35+tip*.4,colour)
			ArtGeometry.triangle(st,across*.07*sign_value,-direction*width*.35+tip*.4,tip,colour)
	else:
		for i in 48:
			if mode in ["whiteout","held","afterfield","lifebed","sanctuary","tempo"] and i%4==3: continue
			var a := TAU*i/48.0
			var b := TAU*(i+1)/48.0
			var p := Vector3(cos(a),0,sin(a))
			var q := Vector3(cos(b),0,sin(b))
			ArtGeometry.triangle(st,p,q,p*.975,colour)
			ArtGeometry.triangle(st,q,q*.975,p*.975,colour)
		if mode in ["mirror","sanctuary","skin"]:
			for i in 4:
				var p := Vector3(cos(TAU*i/4),0,sin(TAU*i/4))*.65
				var q := Vector3(cos(TAU*(i+1)/4),0,sin(TAU*(i+1)/4))*.65
				ArtGeometry.triangle(st,p,q,p*.85,colour)
				ArtGeometry.triangle(st,q,q*.85,p*.85,colour)
		if mode in ["held","afterfield","tempo"]:
			for i in 6:
				var p := Vector3(cos(TAU*i/6),0,sin(TAU*i/6))
				var side := p.cross(Vector3.UP)*.09
				ArtGeometry.triangle(st,p*.78,p*.5+side,p*.57,colour)
				ArtGeometry.triangle(st,p*.78,p*.57,p*.5-side,colour)
		if mode in ["lifebed","emberbed","reservoir","wound","bind"]:
			for i in 3:
				var p := Vector3(cos(TAU*i/3),0,sin(TAU*i/3))*.6
				var side := p.cross(Vector3.UP)*.22
				ArtGeometry.triangle(st,p,p*.35+side,Vector3.ZERO,colour)
				ArtGeometry.triangle(st,p,Vector3.ZERO,p*.35-side,colour)
	visual=MeshInstance3D.new()
	visual.mesh=st.commit()
	tint=ArtGeometry.material()
	tint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.cull_mode=BaseMaterial3D.CULL_DISABLED
	visual.material_override=tint
	visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	if mode=="whiteout":
		vapour=ShaderMaterial.new()
		vapour.shader=preload("res://art/foundry_vapour.gdshader")
		vapour.set_shader_parameter("tint",Color("b0c1bf"))
		var mesh := SphereMesh.new()
		mesh.radial_segments=16
		mesh.rings=8
		for i in 7:
			var cloud := MeshInstance3D.new()
			cloud.mesh=mesh
			cloud.material_override=vapour
			cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.position=Vector3(cos(TAU*i/7)*.45,.13+float(i%3)*.035,sin(TAU*i/7)*.45)
			cloud.scale=Vector3(.8,.38,.8)
			visual.add_child(cloud)
	_sample()

func _sample() -> void:
	if visual==null: return
	var size := radius
	if mode=="ring": size*=maxf(.03,1-remaining/duration)
	if mode in ["bind","reservoir","wound"]: size=.45
	if mode in ["skin","tempo"]:
		global_position=combat.player.global_position+Vector3.UP*.5
		size=.65
	if mode!="needle":
		visual.scale=Vector3.ONE*size
		var floor_hit := SkillBurst.solid_ray(combat,global_position+Vector3.UP*.5,global_position+Vector3.DOWN*3)
		if not floor_hit.is_empty(): visual.global_position=floor_hit.position+Vector3.UP*.045
		tint.albedo_color.a=.65 if mode=="edge" else (.18 if mode=="whiteout" else .5)*minf(1,remaining/.3)
		if vapour!=null: vapour.set_shader_parameter("opacity",.12*minf(1,remaining/.4))
