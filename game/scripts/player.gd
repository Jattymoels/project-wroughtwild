class_name WroughtwildPlayer
extends CharacterBody3D
## Spike pawn: a controllable capsule with third-person camera, resource
## harvesting and grid build mode. Mouse and keyboard only (D-008).
## Controls: WASD move, mouse look, Space jump, E harvest, B build mode,
## LMB place (or harvest outside build mode), X remove, R rotate preview.

## Tunable: harvesting pace and how close the player must stand.
@export var interact_range: float = 3.5
@export var move_speed: float = 5.0
## High enough to hop onto a placed 1 m block with room to spare.
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.003

## Jump feel: a jump pressed just after stepping off a ledge (coyote) or
## just before landing (buffer) still fires - inputs stop feeling eaten.
const COYOTE_SECONDS := 0.12
const JUMP_BUFFER_SECONDS := 0.12

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var inventory: WroughtwildInventory = $Inventory
@onready var placement: GridPlacement = $Placement
@onready var combat: PlayerCombat = $Combat
@onready var body_mesh: MeshInstance3D = $MeshInstance3D

## First person is the default view (D-012); V toggles third person for
## greybox debugging. Eye height sits near the top of the capsule.
var first_person := true
const FP_EYE_HEIGHT := 0.72
const FP_PITCH_LIMIT := 1.35
const TP_PITCH_LIMIT := PI / 3.0
var _tp_arm_length := 4.5
var _tp_arm_position := Vector3(0, 0.6, 0)

const DROPPED_BUNDLE_SCENE := preload("res://scenes/dropped_bundle.tscn")

var hud: Hud
var work_panel: WorkPanel
var inventory_panel: InventoryPanel
var trial: TrialController
## Where the player returns after an open-world death.
var spawn_position := Vector3.ZERO
## Rolls gathering ambushes; tests seed it or spawn ambushes directly.
var ambush_rng := RandomNumberGenerator.new()

var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _was_on_floor := true
## Landing camera dip: set on a hard landing, eased back to zero.
var _land_dip := 0.0

## Grammar-spike scaffolding: F1-F3 flip the three test mods on and off so
## the freeze-shatter sentence can be felt with and without each word.
## Wave 2 replaces these hotkeys with mods that live on gear.
const SPIKE_MODS: Array[StringName] = [&"forked_lattice", &"deep_frost", &"wide_shatter"]


func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	ambush_rng.randomize()
	placement.camera = camera
	placement.inventory = inventory
	combat.setup(self, inventory.get_sim())
	combat.died.connect(_on_died)

	_tp_arm_length = spring_arm.spring_length
	_tp_arm_position = spring_arm.position
	_apply_camera_mode()

	hud = Hud.new()
	hud.sim = inventory.get_sim()
	hud.combat = combat
	hud.placement = placement
	hud.player = self
	add_child(hud)

	work_panel = WorkPanel.new()
	work_panel.sim = inventory.get_sim()
	work_panel.closed.connect(_capture_mouse)
	add_child(work_panel)

	inventory_panel = InventoryPanel.new()
	inventory_panel.sim = inventory.get_sim()
	inventory_panel.combat = combat
	inventory_panel.closed.connect(_capture_mouse)
	add_child(inventory_panel)

	trial = TrialController.new()
	trial.setup(self)
	add_child(trial)

	_capture_mouse()


## Where runtime-spawned nodes (blocks, enemies, packs) live: the current
## scene, or the player's parent when a harness built the tree by hand.
func world_root() -> Node:
	var scene := get_tree().current_scene
	return scene if scene != null else get_parent()


func _capture_mouse() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _release_mouse() -> void:
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func open_crafting(station: StationSite) -> void:
	placement.set_build_mode_enabled(false)
	inventory_panel.close_panel()
	work_panel.open_crafting(station)
	_release_mouse()


func open_order(order_id: StringName) -> void:
	placement.set_build_mode_enabled(false)
	inventory_panel.close_panel()
	work_panel.open_order(order_id)
	_release_mouse()


func open_hand_crafting() -> void:
	placement.set_build_mode_enabled(false)
	inventory_panel.close_panel()
	work_panel.open_hand_crafting()
	_release_mouse()


func open_custom_panel(title: String, rows: Array, message_text: String = "") -> void:
	placement.set_build_mode_enabled(false)
	inventory_panel.close_panel()
	work_panel.open_custom(title, rows, message_text)
	_release_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var pitch_limit := FP_PITCH_LIMIT if first_person else TP_PITCH_LIMIT
		rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			-pitch_limit, pitch_limit)
	elif event.is_action_pressed("toggle_camera"):
		first_person = not first_person
		_apply_camera_mode()
		hud.notify("First person" if first_person else "Third person")
	elif event.is_action_pressed("ui_cancel"):
		if hud.help_visible():
			hud.toggle_help()
		elif inventory_panel.is_open():
			inventory_panel.close_panel()
		else:
			work_panel.close_panel()
	elif event.is_action_pressed("toggle_help"):
		hud.toggle_help()
	elif event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
	elif event.is_action_pressed("save_game"):
		save_game()
	elif event.is_action_pressed("load_game"):
		load_game()
	elif work_panel.is_open() or inventory_panel.is_open():
		return
	elif event.is_action_pressed("hand_craft"):
		open_hand_crafting()
	elif event.is_action_pressed("cycle_shape"):
		placement.cycle_shape()
		hud.notify("Placing: %s" % placement.selection_label())
	elif event.is_action_pressed("skill_slot_1"):
		combat.use_slot(0)
	elif event.is_action_pressed("skill_slot_2"):
		combat.use_slot(1)
	elif event.is_action_pressed("skill_slot_3"):
		combat.use_slot(2)
	elif event.is_action_pressed("skill_slot_4"):
		combat.use_slot(3)
	elif event.is_action_pressed("spike_mod_1"):
		_toggle_spike_mod(0)
	elif event.is_action_pressed("spike_mod_2"):
		_toggle_spike_mod(1)
	elif event.is_action_pressed("spike_mod_3"):
		_toggle_spike_mod(2)
	elif event.is_action_pressed("dash"):
		# Shift casts whichever slot holds a dash skill (D-016): the reflex
		# key survives rearranging the bar.
		var slot := combat.dash_slot()
		if slot >= 0:
			combat.use_slot(slot)
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("toggle_build_mode"):
		placement.set_build_mode_enabled(not placement.build_mode_enabled)
	elif event.is_action_pressed("primary_action"):
		if placement.build_mode_enabled:
			placement.try_place_block()
		else:
			interact()
	elif event.is_action_pressed("remove_block"):
		placement.try_remove_block()
	elif event.is_action_pressed("rotate_preview"):
		placement.rotate_preview()


## The pack screen (I): opens over the world with the mouse released; a
## station's work panel takes precedence while it is open.
func toggle_inventory() -> void:
	if work_panel.is_open():
		return
	if inventory_panel.is_open():
		inventory_panel.close_panel()
	else:
		placement.set_build_mode_enabled(false)
		inventory_panel.open_panel()
		_release_mouse()


func _toggle_spike_mod(index: int) -> void:
	if index < 0 or index >= SPIKE_MODS.size():
		return
	var sim := inventory.get_sim()
	var id := String(SPIKE_MODS[index])
	var now_active := not sim.skill_mod_active(id)
	sim.set_skill_mod_active(id, now_active)
	var mod: Dictionary = sim.skill_mod(id)
	hud.notify("%s %s (spike mod F%d)" % [
		mod.get("display_name", id), "ON" if now_active else "off", index + 1])


func save_game(path: String = SaveManager.DEFAULT_PATH) -> bool:
	if trial.active():
		hud.notify("You cannot save inside the trial.")
		return false
	var manager := SaveManager.new()
	var ok := manager.write(path, self)
	hud.notify("Saved." if ok else "Save failed: %s" % manager.last_error)
	return ok


func load_game(path: String = SaveManager.DEFAULT_PATH) -> bool:
	if trial.active():
		hud.notify("You cannot load inside the trial.")
		return false
	work_panel.close_panel()
	inventory_panel.close_panel()
	var manager := SaveManager.new()
	var ok := manager.read(path, self)
	if ok:
		# The save restored known skills and the bar; the HUD rebuilds.
		combat.loadout_changed.emit()
	hud.notify("Loaded." if ok else "Load failed: %s" % manager.last_error)
	return ok


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_left = JUMP_BUFFER_SECONDS
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)

	if is_on_floor():
		_coyote_left = COYOTE_SECONDS
	else:
		velocity += get_gravity() * delta
		_coyote_left = maxf(0.0, _coyote_left - delta)

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_left = 0.0
		_coyote_left = 0.0

	var dash := combat.dash_velocity()
	if dash != Vector3.ZERO:
		velocity.x = dash.x
		velocity.z = dash.z
	else:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

	var fall_speed := -velocity.y
	move_and_slide()

	# A hard landing dips the camera briefly - weight without screen shake.
	if is_on_floor() and not _was_on_floor and fall_speed > 5.5:
		_land_dip = clampf(fall_speed * 0.014, 0.04, 0.13)
	_was_on_floor = is_on_floor()
	_land_dip = move_toward(_land_dip, 0.0, delta * 0.7)
	spring_arm.position.y = (FP_EYE_HEIGHT if first_person else _tp_arm_position.y) - _land_dip


func _on_died() -> void:
	if trial.active():
		# Trial death is the sim's contract: deposit safe, run loot lost,
		# catalysts kept. Nothing drops in the arena.
		trial.on_player_died()
		return
	var sim := inventory.get_sim()
	var dropped: Dictionary = sim.drop_inventory()
	if not dropped.is_empty():
		var bundle: DroppedBundle = DROPPED_BUNDLE_SCENE.instantiate()
		world_root().add_child(bundle)
		bundle.global_position = global_position
		bundle.contents = dropped
		hud.notify("You fell. Your pack lies where you died; go back for it.")
	else:
		hud.notify("You fell.")
	work_panel.close_panel()
	global_position = spawn_position
	velocity = Vector3.ZERO
	combat.restore_life()
	combat.invulnerable_left = 2.0


## Rolls the gathering site's ambush; returns the enemies spawned (if any).
func maybe_ambush(node: ResourceNode) -> Array:
	if node.gather_site_id == &"":
		return []
	var sim := inventory.get_sim()
	var site: Dictionary = sim.gather_site(node.gather_site_id)
	if site.is_empty():
		return []
	var removed_by: String = site.get("ambush_removed_by_world_effect", "")
	if removed_by != "" and sim.world_effect_active(removed_by):
		return []
	if ambush_rng.randf() >= site.get("ambush_chance", 0.0):
		return []
	return spawn_ambush(node)


## Spawns the site's ambush party around the node regardless of the roll.
func spawn_ambush(node: ResourceNode) -> Array:
	var sim := inventory.get_sim()
	var site: Dictionary = sim.gather_site(node.gather_site_id)
	var spawned: Array = []
	var ids: PackedStringArray = site.get("ambush_enemies", PackedStringArray())
	for i in ids.size():
		var angle := TAU * float(i) / float(maxi(ids.size(), 1)) + 0.7
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * 3.0
		spawned.append(Enemy.spawn(world_root(), ids[i], node.global_position + offset))
	if not spawned.is_empty():
		hud.notify("Ambush! %s" % site.get("display_name", ""))
	return spawned


func _apply_camera_mode() -> void:
	if first_person:
		spring_arm.spring_length = 0.0
		spring_arm.position = Vector3(0.0, FP_EYE_HEIGHT, 0.0)
		# The capsule stays for shadows only, so the camera never sits inside it.
		body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	else:
		spring_arm.spring_length = _tp_arm_length
		spring_arm.position = _tp_arm_position
		spring_arm.rotation.x = clampf(spring_arm.rotation.x, -TP_PITCH_LIMIT, TP_PITCH_LIMIT)
		body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## What the crosshair is over, for HUD feedback: a state ("none" |
## "interact" | "enemy"), a short label naming the target, and the target
## node itself (for hover highlighting).
func aim_probe() -> Dictionary:
	var none := {"state": "none", "label": "", "target": null}
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * interact_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return none
	var collider: Object = hit.get("collider")
	if collider is Enemy:
		var enemy := collider as Enemy
		if enemy.life > 0.0 and hit["position"].distance_to(from) <= combat.melee_reach + 1.0:
			return {"state": "enemy", "label": "", "target": enemy}
		return none
	if collider is ResourceNode:
		var node := collider as ResourceNode
		return {"state": "interact", "target": node,
			"label": "%s ×%d — E to gather" % [Hud.pretty(String(node.material_family)), node.remaining_units]}
	if collider is StationSite:
		var site := collider as StationSite
		var sim := inventory.get_sim()
		var info: Dictionary = sim.station(site.current_station_id(sim))
		var verb := "E to work" if site.is_built(sim) else "E to build"
		return {"state": "interact", "target": site,
			"label": "%s — %s" % [info.get("display_name", "Station"), verb]}
	if collider is OrderBoard:
		return {"state": "interact", "label": "Order board — E to read", "target": collider}
	if collider is DroppedBundle:
		return {"state": "interact", "label": "Your dropped pack — E to recover", "target": collider}
	if collider is TrialGate:
		return {"state": "interact", "label": "Trial gate — E to enter", "target": collider}
	return none


func aim_state() -> String:
	return aim_probe()["state"]


func interact() -> void:
	# Inside a run with no fight on, E brings the doors or offer back.
	if trial.active() and trial.state != "fighting":
		trial.reopen()
		return
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * interact_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider: Object = hit.get("collider")
	if collider is ResourceNode:
		var node := collider as ResourceNode
		var family := node.material_family
		var granted := node.harvest()
		if granted > 0:
			# Feel: the yield pops out of the node as physical chips that
			# vacuum into you; the inventory add happens on absorb.
			Pickup.scatter(world_root(), node.global_position + Vector3(0, 0.9, 0),
				{String(family): granted}, ambush_rng.randi(), node.global_position.y + 0.02)
			maybe_ambush(node)
	elif collider is StationSite:
		(collider as StationSite).interact(self)
	elif collider is OrderBoard:
		(collider as OrderBoard).interact(self)
	elif collider is DroppedBundle:
		(collider as DroppedBundle).interact(self)
	elif collider is TrialGate:
		(collider as TrialGate).interact(self)
