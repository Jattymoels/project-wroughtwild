class_name FoundryIdentity
extends RefCounted
## Shared spatial safety for the authored identity events. The sim supplies
## packets and ceilings; these terminal effects cannot recursively cast skills.

static func point(combat: PlayerCombat) -> Vector3:
	return combat.player.global_position + Vector3.UP * 0.5

static func direction(combat: PlayerCombat) -> Vector3:
	return (-combat.player.global_basis.z * Vector3(1,0,1)).normalized()

static func inside(combat: PlayerCombat, at: Vector3, target: Vector3, radius: float) -> bool:
	return at.distance_to(target) <= radius and SkillBurst.solid_ray(combat,at,target).is_empty()

static func admit(combat: PlayerCombat, group: String, cap: int) -> bool:
	var count := 0
	for node in combat.get_tree().get_nodes_in_group(group):
		if node.combat == combat and not node.is_queued_for_deletion() and node.remaining > 0: count += 1
	return count < cap

static func sphere_crossing(combat: PlayerCombat, centre: Vector3, radius: float, from: Vector3, to: Vector3) -> float:
	var segment := to-from
	var offset := from-centre
	var a := segment.length_squared()
	var b := offset.dot(segment)
	var c := offset.length_squared()-radius*radius
	var t := INF
	if c<=0: t=0
	elif a>.000001 and b*b-a*c>=0: t=(-b-sqrt(b*b-a*c))/a
	if t<0 or t>1: return INF
	return t if SkillBurst.solid_ray(combat,centre,from+segment*t).is_empty() else INF

static func intercept(tree: SceneTree, from: Vector3, to: Vector3, shooter: Enemy) -> bool:
	# Choose across all ward families before spending any charge. Calling four
	# independent interceptors in order could spend a farther ward first.
	var best := {"at":INF}
	var owners := {}
	for group in ["foundry_fields","foundry_cold","foundry_guard","foundry_tempo"]:
		for node in tree.get_nodes_in_group(group):
			if node.remaining<=0 or node.is_queued_for_deletion(): continue
			owners[node.combat]=true
			var t := INF
			if node is FoundryField and node.charges>0:
				t=sphere_crossing(node.combat,node.global_position+Vector3.UP*.65,node.radius,from,to)
			elif node is FoundryCold and node.mode in ["mirror","sanctuary"]:
				t=FoundryCold.crossing(node,from,to)
			if t<float(best.at): best={"at":t,"node":node}
	for owner_combat in owners:
		for candidate in [FoundryGuard.projectile_candidate(owner_combat,from,to,shooter),FoundryTempo.projectile_candidate(owner_combat,from,to,shooter)]:
			if not candidate.is_empty() and float(candidate.at)<float(best.at): best=candidate
	if not best.has("node"): return false
	var node: Node3D=best.node
	var at := from+(to-from)*float(best.at)
	if node is FoundryGuard: return FoundryGuard.consume_projectile(node,at,shooter)
	if node is FoundryTempo: return FoundryTempo.consume_projectile(node,at,shooter)
	if node is FoundryField:
		node.charges-=1
		SkillBurst.flash(node.combat,node.skill_id,at,.65)
	else:
		node.cancel()
		FoundryPuff.spawn(node.combat,at,.5,true)
		if node.mode=="mirror" and is_instance_valid(shooter) and shooter.life>0:
			FoundryCold.spawn(node.combat,node.skill_id,"needle",at,node.rules,shooter)
	return true

static func damage(combat: PlayerCombat, _skill: StringName, enemy: Enemy, at: Vector3, rules: Dictionary, prefix: String, type: String) -> float:
	if not is_instance_valid(enemy) or enemy.life <= 0: return 0
	if not SkillBurst.solid_ray(combat,at,enemy.global_position+Vector3.UP*.5).is_empty(): return 0
	var fraction := 1.0
	if enemy.guards_against(at): fraction *= 1.0-enemy.verb_strength
	var ward: Enemy = enemy.warded_by()
	if ward != null: fraction *= 1.0-ward.verb_strength
	var amount := enemy.take_typed(float(rules.get(prefix+"_"+type+"_damage",0))*fraction,type)
	if amount > 0: combat.hit_landed.emit(amount,int(enemy.life<=0),PackedStringArray([type]))
	return amount

static func visual(node: Node3D, shape: String, colour: Color, radius: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 0.65
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if shape == "ring":
		var ring := TorusMesh.new()
		ring.inner_radius = radius * .91
		ring.outer_radius = radius
		ring.rings = 32
		ring.ring_segments = 6
		mesh.mesh = ring
	elif shape == "bar":
		var bar := BoxMesh.new()
		bar.size = Vector3(radius*2,.06,.12)
		mesh.mesh = bar
	elif shape == "spike":
		var spike := CylinderMesh.new()
		spike.top_radius = 0
		spike.bottom_radius = radius*.3
		spike.height = radius
		spike.radial_segments = 5
		mesh.mesh = spike
	else:
		var orb := SphereMesh.new()
		orb.radius = radius*.25
		orb.height = radius*.5
		orb.radial_segments = 10
		orb.rings = 5
		mesh.mesh = orb
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mesh)
	return mesh
