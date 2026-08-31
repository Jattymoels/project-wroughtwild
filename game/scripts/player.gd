class_name WroughtwildPlayer
extends CharacterBody3D
## Spike pawn: a controllable capsule with third-person camera, resource
## harvesting and grid build mode. Mouse and keyboard only (D-008).
## Controls: WASD move, mouse look, Space jump, E harvest, B build mode,
## LMB place (or harvest outside build mode), X remove, R rotate preview.

## Tunable: harvesting pace and how close the player must stand.
@export var interact_range: float = 3.5
@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var inventory: WroughtwildInventory = $Inventory
@onready var placement: GridPlacement = $Placement
@onready var combat: PlayerCombat = $Combat

const DROPPED_BUNDLE_SCENE := preload("res://scenes/dropped_bundle.tscn")

var hud: Hud
var work_panel: WorkPanel
var trial: TrialController
## Where the player returns after an open-world death.
var spawn_position := Vector3.ZERO
## Rolls gathering ambushes; tests seed it or spawn ambushes directly.
var ambush_rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	ambush_rng.randomize()
	placement.camera = camera
	placement.inventory = inventory
	combat.setup(self, inventory.get_sim())
	combat.died.connect(_on_died)

	hud = Hud.new()
	hud.sim = inventory.get_sim()
	hud.combat = combat
	hud.placement = placement
	add_child(hud)

	work_panel = WorkPanel.new()
	work_panel.sim = inventory.get_sim()
	work_panel.closed.connect(_capture_mouse)
	add_child(work_panel)

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
	work_panel.open_crafting(station)
	_release_mouse()


func open_order(order_id: StringName) -> void:
	placement.set_build_mode_enabled(false)
	work_panel.open_order(order_id)
	_release_mouse()


func open_hand_crafting() -> void:
	placement.set_build_mode_enabled(false)
	work_panel.open_hand_crafting()
	_release_mouse()


func open_custom_panel(title: String, rows: Array, message_text: String = "") -> void:
	placement.set_build_mode_enabled(false)
	work_panel.open_custom(title, rows, message_text)
	_release_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			-PI / 3.0, PI / 3.0)
	elif event.is_action_pressed("ui_cancel"):
		work_panel.close_panel()
	elif event.is_action_pressed("save_game"):
		save_game()
	elif event.is_action_pressed("load_game"):
		load_game()
	elif work_panel.is_open():
		return
	elif event.is_action_pressed("hand_craft"):
		open_hand_crafting()
	elif event.is_action_pressed("cycle_shape"):
		placement.cycle_shape()
		hud.notify("Placing: %s" % placement.selection_label())
	elif event.is_action_pressed("skill_area"):
		combat.use_area()
	elif event.is_action_pressed("skill_heavy"):
		combat.use_heavy()
	elif event.is_action_pressed("dash"):
		combat.use_dash()
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
	var manager := SaveManager.new()
	var ok := manager.read(path, self)
	hud.notify("Loaded." if ok else "Load failed: %s" % manager.last_error)
	return ok


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var dash := combat.dash_velocity()
	if dash != Vector3.ZERO:
		velocity.x = dash.x
		velocity.z = dash.z
	else:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	move_and_slide()


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
			inventory.add_material(family, granted)
			hud.notify("+%d %s" % [granted, Hud.pretty(family)])
			maybe_ambush(node)
	elif collider is StationSite:
		(collider as StationSite).interact(self)
	elif collider is OrderBoard:
		(collider as OrderBoard).interact(self)
	elif collider is DroppedBundle:
		(collider as DroppedBundle).interact(self)
	elif collider is TrialGate:
		(collider as TrialGate).interact(self)
