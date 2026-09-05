class_name FoundryEmber
extends Node3D
## The five early Ember events: short-lived, snapshotted and bounded.
## Their terminal ignite can shed a cinder/cleanse, but never makes another
## fuse, spark, seam, linked cast or mastery use.
var combat: PlayerCombat
var skill_id: StringName
var mode := "fuse"
var target: Enemy
var rules: Dictionary
var remaining := 0.0
var duration := 0.0
var direction := Vector3.FORWARD
var length := 0.0
var width := 0.0
var radius := 0.0
var visual: Node3D
var material: StandardMaterial3D

static func active(owner_combat: PlayerCombat, kind: String) -> FoundryEmber:
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_embers"):
		if node.combat == owner_combat and node.mode == kind and node.remaining > 0 and not node.is_queued_for_deletion(): return node
	return null

static func launch(owner_combat: PlayerCombat, skill: StringName, kind: String, victim: Enemy, form: Dictionary) -> FoundryEmber:
	var count := 0
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_embers"):
		if node.combat != owner_combat or node.remaining <= 0 or node.is_queued_for_deletion(): continue
		count += 1
		# A fresh hit cannot refresh a fuse or stack personal charges.
		if node.mode == kind and (kind in ["temper", "cautery"] or kind == "fuse" and node.target == victim): return null
	if count >= int(form.limits.max_ember_effects): return null
	var effect := FoundryEmber.new()
	effect.combat = owner_combat
	effect.skill_id = skill
	effect.mode = kind
	effect.target = victim
	effect.rules = form.duplicate(true)
	effect.rules["sear"] = owner_combat.sim.skill_sear(String(skill)) if not skill.is_empty() else 0.0
	match kind:
		"fuse": effect.duration = float(form.limits.fuse_delay)
		"spark": effect.duration = float(form.limits.ember_hop_seconds)
		"seam":
			effect.duration = float(form.limits.rake_delay)
			effect.length = owner_combat.mutation_radius(skill, float(form.limits.rake_length))
			effect.width = owner_combat.mutation_radius(skill, float(form.limits.rake_half_width))
		"temper":
			effect.duration = float(form.limits.temper_seconds)
			effect.radius = owner_combat.mutation_radius(skill, float(form.limits.temper_radius))
		"cautery": effect.duration = float(form.limits.cautery_seconds)
	effect.remaining = effect.duration
	owner_combat.player.world_root().add_child(effect)
	effect.global_position = owner_combat.player.global_position + Vector3.UP * 0.5
	if is_instance_valid(victim) and kind not in ["temper","cautery"]:
		effect.global_position = victim.global_position + Vector3.UP * 0.5
		effect.direction = (victim.global_position - owner_combat.player.global_position) * Vector3(1,0,1)
		effect.direction = effect.direction.normalized() if effect.direction.length_squared() > 0.001 else Vector3.FORWARD
	if kind == "seam":
		var cover := SkillBurst.solid_ray(owner_combat, effect.global_position, effect.global_position + effect.direction * effect.length)
		if not cover.is_empty(): effect.length = effect.global_position.distance_to(cover.position)
	effect._make_visual()
	return effect

func _ready() -> void:
	add_to_group("foundry_embers")
	combat.died.connect(cancel)

func cancel() -> void:
	remaining = 0
	queue_free()

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if is_queued_for_deletion(): return
	if not is_instance_valid(combat) or not is_instance_valid(combat.player) or combat.life <= 0:
		cancel()
		return
	var elapsed := minf(maxf(delta,0), remaining)
	remaining = maxf(0, remaining - elapsed)
	if mode in ["fuse", "spark"]:
		if not is_instance_valid(target) or target.life <= 0 or target.burning_left > 0:
			cancel()
			return
		var to := target.global_position + Vector3.UP * 0.5
		if mode == "fuse":
			global_position = to
			if remaining <= 0: _ignite("fuse")
		else:
			var next := global_position.move_toward(to, float(rules.limits.ember_hop_speed) * elapsed)
			if not SkillBurst.solid_ray(combat, global_position, next).is_empty():
				cancel()
				return
			if next.distance_to(global_position) > .001 and visual != null:
				visual.quaternion = Quaternion(Vector3.FORWARD,(next-global_position).normalized())
			global_position = next
			if global_position.distance_to(to) < 0.01:
				_ignite("ember_hop")
				cancel()
	elif mode in ["temper", "cautery"]:
		global_position = combat.player.global_position + Vector3.UP * 0.5
	elif mode == "seam" and remaining <= 0:
		_cut()
	_sample()
	if remaining <= 0: cancel()

func _ignite(key: String) -> void:
	var amount := float(rules.get(key + ("_ignite_boss" if target is Boss else "_ignite"),0))
	target.apply_ignite(amount, float(rules.sear), 0, rules)
	FoundryPuff.spawn(combat, global_position, 0.55, false)
	# These two ignition rewards have their own player-wide limits. Allowing
	# them here lets Kindling + Bloodfire/Cautery cooperate without proc chains.
	if target.burning_left > 0: FoundryReactions.ignited(combat, target, rules)

func _cut() -> void:
	var total := 0.0
	var kills := 0
	for enemy in combat.alive_enemies():
		if enemy == target: continue
		var centre: Vector3 = enemy.global_position + Vector3.UP * 0.5
		var offset := centre - global_position
		var along := offset.dot(direction)
		if along <= 0 or along > length or (offset - direction * along).length() > width: continue
		if not SkillBurst.solid_ray(combat, global_position, centre).is_empty(): continue
		var fraction := 1.0
		if enemy.guards_against(global_position): fraction *= 1.0 - enemy.verb_strength
		var warden: Enemy = enemy.warded_by()
		if warden != null: fraction *= 1.0 - warden.verb_strength
		total += enemy.take_typed(float(rules.rake_fire_damage) * fraction, "fire")
		if enemy.life <= 0: kills += 1
	if total > 0: combat.hit_landed.emit(total,kills,PackedStringArray(["fire"]))
	for i in 4:
		FoundryPuff.spawn(combat, global_position + direction * length * (i + 0.5) / 4.0, width, false)

static func retaliate(owner_combat: PlayerCombat) -> void:
	var charge := active(owner_combat,"temper")
	if charge == null or owner_combat.life <= 0: return
	charge.cancel() # Consume before visiting recipients, even when nobody is near.
	var at := owner_combat.player.global_position + Vector3.UP * 0.5
	for enemy in owner_combat.alive_enemies():
		var centre: Vector3 = enemy.global_position + Vector3.UP * 0.5
		if at.distance_to(centre) > charge.radius or not SkillBurst.solid_ray(owner_combat,at,centre).is_empty(): continue
		var push := float(charge.rules.temper_push)
		if enemy is Boss: push *= float(charge.rules.limits.temper_boss_factor)
		enemy.shove(centre-at, push)
	FoundryPuff.spawn(owner_combat,at,charge.radius,false)

static func cauterise(owner_combat: PlayerCombat, form: Dictionary) -> void:
	var cleansed := ""
	if owner_combat.rooted():
		owner_combat._root_left = 0
		cleansed = "root"
	elif owner_combat.harried():
		owner_combat._slow_left = 0
		cleansed = "harry"
	elif owner_combat.marked():
		owner_combat._marked_left = 0
		cleansed = "mark"
	if cleansed.is_empty():
		launch(owner_combat,&"","cautery",null,form)
	else:
		FoundryPuff.spawn(owner_combat,owner_combat.player.global_position+Vector3.UP*0.5,0.8,false)
		if owner_combat.player.hud != null: owner_combat.player.hud.notify("Cautery cleared " + cleansed)

static func prevent(owner_combat: PlayerCombat, verb: String) -> bool:
	if verb not in ["root","harry","mark"]: return false
	var ward := active(owner_combat,"cautery")
	if ward == null: return false
	ward.cancel()
	FoundryPuff.spawn(owner_combat,owner_combat.player.global_position+Vector3.UP*0.5,0.8,false)
	if owner_combat.player.hud != null: owner_combat.player.hud.notify("Cautery prevented " + verb)
	return true

func _make_visual() -> void:
	visual = Node3D.new()
	add_child(visual)
	if mode in ["fuse","spark"]:
		if mode == "spark":
			visual.add_child(CombatVisuals.projectile("ember",Color("f6a465")))
			visual.scale = Vector3.ONE * .65
		else:
			var st := ArtGeometry.begin()
			# A broken ember halo contracts as the fuse expires. Unlike a rock
			# or a full orb, its hollow centre keeps the victim visible.
			for i in 18:
				if i % 6 == 5: continue
				var a := TAU * i / 18.0
				var b := TAU * (i+.7) / 18.0
				var p := Vector3(cos(a),sin(a),0) * .23
				var q := Vector3(cos(b),sin(b),0) * .23
				ArtGeometry.triangle(st,p,q,p*.87,Color("f4ac68"))
				ArtGeometry.triangle(st,q,q*.87,p*.87,Color("e77938"))
			var halo := MeshInstance3D.new()
			halo.mesh = st.commit()
			halo.material_override = ArtGeometry.material()
			halo.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			halo.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
			halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			visual.add_child(halo)
	else:
		var st := ArtGeometry.begin()
		var colour := Color("df8853") if mode != "cautery" else Color("d5b37c")
		if mode == "seam":
			var side := direction.cross(Vector3.UP) * width
			for i in 12:
				var p := _ground_point(direction * length * i / 12.0)
				var q := _ground_point(direction * length * (i + 1) / 12.0)
				ArtGeometry.triangle(st,p-side*.14,q-side*.14,q+side*.14,colour)
				ArtGeometry.triangle(st,p-side*.14,q+side*.14,p+side*.14,colour)
				if i % 2 == 0:
					ArtGeometry.triangle(st,p-side*.65,p-side*.5,q,colour.darkened(.45))
					ArtGeometry.triangle(st,p+side*.65,p+side*.5,q,colour.darkened(.45))
		else:
			# An open ring of heated facets at the player's feet, not a screen tint.
			for i in 12:
				var angle := TAU * i / 12.0
				var reach := .7 if mode == "temper" else .85
				var p := Vector3(cos(angle),0,sin(angle)) * reach
				var q := Vector3(cos(angle+.3),0,sin(angle+.3)) * reach
				ArtGeometry.triangle(st,p,q,p*1.04,colour)
				ArtGeometry.triangle(st,q,q*1.04,p*1.04,colour)
		var mesh := MeshInstance3D.new()
		mesh.mesh = st.commit()
		material = ArtGeometry.material()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visual.add_child(mesh)
	_sample()

func _sample() -> void:
	if visual == null: return
	var progress := 1.0 - remaining / maxf(duration,.001)
	if mode == "fuse":
		visual.position.y = 1.0
		visual.scale = Vector3.ONE * (1.0 - progress * .4)
		visual.look_at(combat.player.camera.global_position,Vector3.UP)
	elif mode in ["temper","cautery"]:
		visual.position = _ground_point(Vector3.ZERO)
	if material != null: material.albedo_color.a = .65 if mode == "seam" else minf(.4,remaining)

func _ground_point(offset: Vector3) -> Vector3:
	var at := global_position + offset
	var hit := SkillBurst.solid_ray(combat,at+Vector3.UP*.5,at+Vector3.DOWN*3)
	return to_local(hit.position+Vector3.UP*.035) if not hit.is_empty() else offset+Vector3.DOWN*.5
