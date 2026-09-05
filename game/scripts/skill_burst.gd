class_name SkillBurst
extends Node3D
## Fixed, bounded area delivery: sim payloads, Godot timing and solid cover.
const LOOK = preload("res://art/combat_feel.tres")
var combat: PlayerCombat
var skill_id: StringName
var radius := 1.0
var delay := 0.0
var remaining := 0.0
var detonated := false
var allow_links := true
var ring: MeshInstance3D
var crown: MeshInstance3D
var tint: StandardMaterial3D
var action_context: Dictionary

static func has_room(from_combat: PlayerCombat, limit: int) -> bool:
	var count := 0
	for node in from_combat.get_tree().get_nodes_in_group("skill_bursts"):
		if not node.is_queued_for_deletion(): count += 1
	return count < limit

static func solid_ray(from_combat: PlayerCombat, from: Vector3, to: Vector3) -> Dictionary:
	var excluded: Array[RID] = [from_combat.player.get_rid()]
	for enemy in from_combat.get_tree().get_nodes_in_group("enemies"):
		if enemy is Enemy: excluded.append(enemy.get_rid())
	return from_combat.player.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(from,to,1,excluded))

static func hit_area(from_combat: PlayerCombat, skill: StringName, at: Vector3,
		in_radius: float, fraction: float, visited: Array, links: bool, secondary := false, context := {}) -> void:
	var enemies := from_combat.alive_enemies()
	var shatter: Dictionary = from_combat.sim.shatter_for(String(skill))
	var frozen: Array = []
	var damage := 0.0
	var kills := 0
	var types := PackedStringArray()
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.life<=0 or visited.has(enemy.get_instance_id()): continue
		var target: Vector3 = enemy.global_position+Vector3.UP*0.65
		if at.distance_to(target)>in_radius or not solid_ray(from_combat,at,target).is_empty(): continue
		visited.append(enemy.get_instance_id())
		if not secondary and enemy.is_frozen() and shatter.get("enabled",false):
			frozen.append(enemy)
			continue
		var crossed := from_combat.apply_payload(enemy,skill,enemy is Boss,fraction if secondary else 1.0,secondary,context)
		var landed := from_combat.deal(enemy,skill,enemies.size()==1,fraction,secondary)
		damage += float(landed.damage)
		kills += 1 if landed.kill else 0
		for type in landed.types:
			if not types.has(type): types.append(type)
		if not secondary: from_combat._space_control(enemy,skill,at.direction_to(target))
		if links: from_combat.fire_links(skill,crossed,enemy)
	var cascade := from_combat._shatter_cascade(frozen,shatter,from_combat.sim.skill_nova_chill(String(skill)))
	damage += float(cascade.damage)
	kills += int(cascade.kills)
	from_combat._reap(skill,int(cascade.kills))
	if float(cascade.damage)>0 and not types.has("cold"): types.append("cold")
	if damage>0: from_combat.hit_landed.emit(damage,kills,types)

static func mark(from_combat: PlayerCombat, skill: StringName, at: Vector3, normal: Vector3, seconds: float) -> SkillBurst:
	var burst := SkillBurst.new()
	burst.combat = from_combat
	burst.skill_id = skill
	burst.action_context = from_combat.action_context(skill)
	burst.radius = from_combat.area_radius(skill)
	burst.delay = seconds
	burst.remaining = seconds
	burst.allow_links = from_combat._link_depth==0
	from_combat.player.world_root().add_child(burst)
	burst.global_position = at
	burst.quaternion = Quaternion(Vector3.UP,normal.normalized())
	burst._make_visual()
	return burst

static func flash(from_combat: PlayerCombat, skill: StringName, at: Vector3, in_radius: float) -> void:
	# Cosmetic flashes can be omitted at the budget; committed damage never is.
	if not has_room(from_combat,LOOK.max_cast_effects): return
	var burst := mark(from_combat,skill,at,Vector3.UP,0)
	burst.radius = in_radius
	burst.detonated = true
	burst.remaining = LOOK.effect_seconds
	burst.ring.scale = Vector3.ONE*in_radius
	burst._sample_visual()

func _ready() -> void:
	add_to_group("skill_bursts")
	combat.died.connect(cancel)

func cancel() -> void:
	detonated = true
	queue_free()

func _make_visual() -> void:
	var st := ArtGeometry.begin()
	var colour: Color = LOOK.colour(combat.skills[skill_id])
	for i in 48:
		var a := TAU*float(i)/48
		var b := TAU*float(i+1)/48
		var p := Vector3(cos(a),0,sin(a))
		var q := Vector3(cos(b),0,sin(b))
		ArtGeometry.triangle(st,p,q,p*0.975,colour)
		ArtGeometry.triangle(st,q,q*0.975,p*0.975,colour)
	ring = MeshInstance3D.new()
	ring.mesh = st.commit()
	tint = ArtGeometry.material()
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = tint
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3.ONE*radius
	add_child(ring)
	st = ArtGeometry.begin()
	# Solid charred splinters with a hot inner face, rather than flat flame cards.
	# The authored mesh scales with the committed radius; it has no collisions.
	for i in 16:
		var a := TAU*float(i)/16
		var radial := Vector3(cos(a),0,sin(a))
		var tangent := Vector3(-sin(a),0,cos(a))
		var at := radial*(0.24+float((i*7)%11)*0.046)
		var width := 0.025+float(i%3)*0.012
		var tip := at+radial*0.14+Vector3.UP*(0.2+float((i*5)%9)*0.046)
		var corners := [at-radial*width,at+tangent*width,at+radial*width,at-tangent*width]
		for side in 4:
			var shade := colour.darkened(0.12) if side==0 else Color("342d28").lightened(float(side)*0.014)
			ArtGeometry.triangle(st,corners[side],corners[(side+1)%4],tip,shade)
	crown = MeshInstance3D.new()
	crown.mesh = st.commit()
	crown.material_override = tint
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(crown)
	_sample_visual()

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if is_queued_for_deletion(): return
	if not is_instance_valid(combat) or not is_instance_valid(combat.player):
		cancel()
		return
	remaining = maxf(0,remaining-maxf(0,delta))
	if not detonated and remaining<=0:
		detonated = true
		hit_area(combat,skill_id,global_position,radius,1.0,[],allow_links,false,action_context)
		combat.mutation_impact(skill_id,global_position)
		remaining = LOOK.effect_seconds
	elif detonated and remaining<=0:
		queue_free()
	_sample_visual()

func _sample_visual() -> void:
	if ring==null: return
	var progress := 1.0-remaining/maxf(delay,0.001)
	tint.albedo_color.a = remaining/maxf(LOOK.effect_seconds,0.001) if detonated else 0.4+progress*0.4
	crown.scale = Vector3.ONE*radius*(1.0-remaining/LOOK.effect_seconds*0.55) if detonated else Vector3(0.2,0.08+progress*0.1,0.2)
