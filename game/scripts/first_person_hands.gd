class_name FirstPersonHands
extends Node3D
## Visual observer of committed skills. Never aims, spends, hits or moves a camera.
const LOOK = preload("res://art/first_person_look.tres")
const GATHER = preload("res://art/gathering_look.tres")
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
	_previous = player.global_position
	player.combat.skill_committed.connect(present_skill)
	player.combat.hit_landed.connect(_on_hit)
	sample(0.0)

func present_skill(skill_id: StringName) -> void:
	var def: Dictionary = player.combat.skills.get(skill_id,{})
	active_delivery = def.get("delivery","")
	duration = LOOK.strike_seconds if active_delivery in ["strike","cone"] else LOOK.cast_seconds
	remaining = duration
	var tags: PackedStringArray = def.get("tags",PackedStringArray())
	elemental = "cold" in tags or "fire" in tags
	var colour := Color("a9d9e5") if "cold" in tags else Color("e7a15f") if "fire" in tags else Color("d5c59d")
	(glow.material_override as StandardMaterial3D).albedo_color = colour
	(glow.material_override as StandardMaterial3D).emission = colour

func _on_hit(_damage: float, _kills: int, _types: PackedStringArray) -> void:
	impact = LOOK.impact_seconds

func present_work() -> void:
	active_delivery = "gather"
	duration = GATHER.hand_seconds
	remaining = duration
	elemental = false

func _process(delta: float) -> void:
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
		hand.position = Vector3(side*LOOK.hand_position.x,LOOK.hand_position.y+sin(walk_phase)*LOOK.stride_sway,LOOK.hand_position.z+recoil+wall_retract)
		hand.rotation = Vector3(-0.13,side*-0.18,side*-0.18)
		if active_delivery=="gather" and i==1:
			hand.position += Vector3(-0.055, 0.045, -GATHER.hand_reach)*strength
			hand.rotation.x -= strength*0.5
		elif active_delivery=="strike" and i==1:
			hand.position += Vector3(-0.09,0.06,-0.18)*strength
			hand.rotation.x -= strength*0.4
		elif active_delivery=="cone":
			hand.position += Vector3(-side*0.06,0.055,-0.10)*strength
			hand.rotation.z += side*strength*0.45
		elif active_delivery=="projectile":
			hand.position += Vector3(-side*0.025,0.035,-0.12)*strength
			hand.rotation.x -= strength*0.3
		elif active_delivery=="dash":
			hand.position += Vector3(side*0.025,-0.08,0.05)*strength
	glow.visible = elemental and active_delivery in ["projectile","cone"] and remaining>duration*0.55
	glow.position = hands[1].position+Vector3(-0.005,0,-0.29)
