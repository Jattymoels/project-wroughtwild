class_name FirstPersonHands
extends Node3D
## Visual observer of committed skills. Never aims, spends, hits or moves a camera.
const LOOK = preload("res://art/first_person_look.tres")
const GATHER = preload("res://art/gathering_look.tres")
const FEEL = preload("res://art/combat_feel.tres")
var player: WroughtwildPlayer
var hands: Array[MeshInstance3D] = []
var glow: MeshInstance3D
var active_delivery := ""
var remaining := 0.0
var duration := 0.3
var impact := 0.0
var walk_phase := 0.0
var wall_retract := 0.0
var elemental := false
var active_profile := ""
var weapon: MeshInstance3D
var weapon_base := ""
var _equipment_left := 0.0
var _previous := Vector3.ZERO
var _material: StandardMaterial3D

func _ready() -> void:
	_material = ArtGeometry.material()
	for i in 2:
		var hand := MeshInstance3D.new()
		hand.mesh = LOOK.hand_mesh(i==0)
		hand.material_override = _material
		hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(hand)
		hands.append(hand)
	glow = MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = 0.025
	orb.height = 0.05
	glow.mesh = orb
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := StandardMaterial3D.new()
	light.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light.emission_enabled = true
	glow.material_override = light
	add_child(glow)
	weapon = MeshInstance3D.new()
	weapon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(weapon)
	refresh_weapon()
	_previous = player.global_position
	player.combat.skill_committed.connect(present_skill)
	player.combat.hit_landed.connect(_on_hit)
	sample(0.0)

func present_skill(skill_id: StringName) -> void:
	var def: Dictionary = player.combat.skills.get(skill_id,{})
	active_delivery = def.get("delivery","")
	var spatial: Dictionary = player.combat.sim.realtime().get("skills",{}).get(String(skill_id),{})
	active_profile = FEEL.profile(def,spatial)
	duration = FEEL.seconds(active_profile)
	remaining = duration
	refresh_weapon()
	SkillCastEffect.spawn(player.combat,skill_id)
	var tags: PackedStringArray = def.get("tags",PackedStringArray())
	elemental = "cold" in tags or "fire" in tags
	var colour := Color("a9d9e5") if "cold" in tags else Color("e7a15f") if "fire" in tags else Color("d5c59d")
	(glow.material_override as StandardMaterial3D).albedo_color = colour
	(glow.material_override as StandardMaterial3D).emission = colour

func _on_hit(_damage: float, _kills: int, _types: PackedStringArray) -> void:
	impact = LOOK.impact_seconds

func present_work() -> void:
	active_delivery = "gather"
	active_profile = "gather"
	duration = GATHER.hand_seconds
	remaining = duration
	elemental = false

func _process(delta: float) -> void:
	_equipment_left -= delta
	if _equipment_left <= 0.0:
		_equipment_left = FEEL.equipment_refresh_seconds
		refresh_weapon()
	var at := player.global_position
	var travelled := Vector2(at.x-_previous.x,at.z-_previous.z).length()
	_previous = at
	if travelled<1.0 and player.is_on_floor():
		walk_phase = fposmod(walk_phase+travelled*4.0,TAU)
	visible = player.first_person and not player.placement.build_mode_enabled and player.combat.life>0.0
	for panel in [player.work_panel,player.inventory_panel,player.foundry_panel,player.class_panel,player.chest_panel]:
		if panel!=null and panel.is_open():
			visible = false
	wall_retract = 0.0
	if visible:
		# Check each wrist lane, excluding the player's own capsule.
		for side in [-1.0,1.0]:
			var origin := to_global(Vector3(side*LOOK.hand_position.x,LOOK.hand_position.y,0))
			var end := origin-global_basis.z*LOOK.wall_reach
			var ray := PhysicsRayQueryParameters3D.create(origin,end,1,[player.get_rid()])
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty():
				wall_retract = maxf(wall_retract,LOOK.wall_reach-origin.distance_to(hit.position)+LOOK.wall_margin)
	sample(delta)

func sample(delta: float) -> void:
	remaining = maxf(0.0,remaining-delta)
	impact = maxf(0.0,impact-delta)
	var strength := remaining/maxf(duration,0.001)
	var recoil := LOOK.impact_recoil*impact/maxf(LOOK.impact_seconds,0.001)
	for i in 2:
		var side := -1.0 if i==0 else 1.0
		var hand := hands[i]
		var sway := sin(walk_phase)*LOOK.stride_sway if player.preferences.values.hand_sway else 0.0
		hand.position = Vector3(side*LOOK.hand_position.x,LOOK.hand_position.y+sway,LOOK.hand_position.z+recoil+wall_retract)
		hand.rotation = Vector3(-0.13,side*-0.18,side*-0.18)
		if active_delivery=="gather" and i==1:
			hand.position += Vector3(-0.055, 0.045, -GATHER.hand_reach)*strength
			hand.rotation.x -= strength*0.5
		elif active_profile=="drive":
			hand.position += Vector3(-side*0.4,0.05,-1.35)*FEEL.swing_metres*strength
			hand.rotation.x -= strength*0.5
		elif active_profile=="strike" and i==1:
			hand.position += Vector3(-0.25,-0.35,-1.0)*FEEL.swing_metres*strength
			hand.rotation.x -= strength*1.1
		elif active_profile=="rend" and i==1:
			hand.position += Vector3(-1.0,0.25,-0.6)*FEEL.swing_metres*strength
			hand.rotation.z += strength*1.15
		elif active_profile in ["sweep","reap"]:
			hand.position += Vector3(-1.0,0.2,-0.5)*FEEL.swing_metres*strength
			hand.rotation.z += strength*0.8
			if active_profile=="reap": hand.position.y -= strength*0.10
		elif active_profile=="nova":
			hand.position += Vector3(side*0.65,0.4,-0.65)*FEEL.swing_metres*strength
			hand.rotation.z += side*strength*0.8
		elif active_profile in ["arrow","fan","bodkin"]:
			hand.position += Vector3(-0.03,0.05,-0.12)*strength if i==0 else Vector3(0.09,0.08,0.12)*strength
			hand.rotation.y += side*strength*0.4
			if active_profile=="fan": hand.rotation.z += side*strength*0.35
			if active_profile=="bodkin" and i==1: hand.position.z += strength*0.08
		elif active_profile=="frost":
			hand.position += Vector3(-side*0.10,0.10,-0.10)*strength
			hand.rotation.z += side*strength*0.6
		elif active_profile=="ember" and i==1:
			hand.position += Vector3(-0.04,0.05,-FEEL.swing_metres)*strength
			hand.rotation.y -= strength*0.65
		elif active_profile=="coal":
			hand.position += Vector3(-side*0.13,0.08,-0.15)*strength
			hand.rotation.z += side*strength*0.55
		elif active_profile=="mark":
			hand.position += Vector3(side*0.03,-0.05,-0.10)*strength
			hand.rotation.x += strength*0.7
		elif active_delivery=="dash":
			hand.position += Vector3(side*0.025,-0.08,0.05)*strength
	glow.visible = elemental and active_delivery in ["projectile","cone","ground"] and remaining>duration*0.55
	glow.position = hands[1].position+Vector3(-0.005,0,-0.29)
	var grip_hand := hands[0] if CombatVisuals.BASE_ROLES.get(weapon_base,"")=="bow" else hands[1]
	weapon.transform = grip_hand.transform * Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*FEEL.weapon_scale),Vector3(0,0,-0.2))
	# Near cover withdraw the held item along with the hands. Hide it for
	# harvesting, where showing a mace would imply it caused an ordinary press.
	weapon.visible = weapon.mesh != null and not (active_profile=="gather" and remaining>0.0) and wall_retract<0.5

func refresh_weapon() -> void:
	var worn: Dictionary = player.combat.sim.equipment().get("weapon",{})
	var base := String(worn.get("base_id",""))
	if base == weapon_base:
		return
	weapon_base = base
	weapon.mesh = CombatVisuals.weapon(base)
