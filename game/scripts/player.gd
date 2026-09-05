class_name WroughtwildPlayer
extends CharacterBody3D
## Spike pawn: a controllable capsule with third-person camera, resource
## harvesting and grid build mode. Mouse and keyboard only (D-008).
## Controls: WASD move, mouse look, Space jump, E harvest, B build mode,
## LMB place (or harvest outside build mode), X remove, R turn an oriented
## block, G fine (half-scale) pieces.

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
var foundry_panel: FoundryPanel
## The class chosen before play begins (D-004, D-023 slice 9): the sandpit
## opens this when no class stands; it blocks play until one is chosen.
var class_panel: ClassPanel
## The lamp (Wave 6 slice 5): a small warm light the player carries after
## dark, so the night keeps its shapes close by and the way home is walkable.
var _lamp: OmniLight3D
## The chest panel (Wave 6 slice 6): E at a placed chest opens its store.
var chest_panel: ChestPanel
## When each family was last called full, so the word comes once in a while.
var _full_said := {}
## The shrieker's horn (Wave 7 slice 3): X blows it, everything in its
## radius comes, and it rings a while before it will blow again.
var _horn_left := 0.0
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

## Hold-to-dig (Wave 3): a held LMB on a generic terrain block digs it out
## over the block's dig_seconds; letting go or looking away resets.
var _dig_cell := Vector3i(-1, -1, -1)
var _dig_progress := 0.0
var _terrain: Terrain
## The one-time line when hands first meet rock (D-020 fire-setting).
var _fire_hint_shown := false


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
	body_mesh.mesh = preload("res://art/character_look.tres").build("player")
	body_mesh.position.y = -0.96
	body_mesh.scale = Vector3.ONE * 1.12
	var body_material := StandardMaterial3D.new()
	body_material.vertex_color_use_as_albedo = true
	body_material.vertex_color_is_srgb = true
	body_material.roughness = 1.0
	body_mesh.material_override = body_material
	_apply_camera_mode()
	var hands := FirstPersonHands.new()
	hands.name = "FirstPersonHands"
	hands.player = self
	camera.add_child(hands)

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

	foundry_panel = FoundryPanel.new()
	foundry_panel.sim = inventory.get_sim()
	foundry_panel.player = self
	foundry_panel.closed.connect(_capture_mouse)
	add_child(foundry_panel)

	class_panel = ClassPanel.new()
	class_panel.sim = inventory.get_sim()
	class_panel.player = self
	class_panel.closed.connect(_capture_mouse)
	add_child(class_panel)

	chest_panel = ChestPanel.new()
	chest_panel.sim = inventory.get_sim()
	chest_panel.player = self
	chest_panel.closed.connect(_capture_mouse)
	add_child(chest_panel)

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


## E at a placed chest (Wave 6 slice 6): its store opens.
func open_chest(block: PlacedBlock) -> void:
	placement.set_build_mode_enabled(false)
	inventory_panel.close_panel()
	work_panel.close_panel()
	chest_panel.open_at(block)
	_release_mouse()


## The pack is full of a family (Wave 6 slice 6): said once in a while,
## not every frame a chip lies at your feet.
func note_pack_full(family: String) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_full_said.get(family, -100000)) < 8000:
		return
	_full_said[family] = now
	hud.notify("Your pack can carry no more %s (%d). A chest at home would take it." % [
		Hud.pretty(family), inventory.carry_cap(StringName(family))])


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
		elif class_panel.is_open():
			pass # the class is chosen, not dismissed
		elif inventory_panel.is_open():
			inventory_panel.close_panel()
		elif foundry_panel.is_open():
			foundry_panel.close_panel()
		elif chest_panel.is_open():
			chest_panel.close_panel()
		else:
			work_panel.close_panel()
	elif event.is_action_pressed("toggle_help"):
		hud.toggle_help()
	elif event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
	elif event.is_action_pressed("toggle_foundry"):
		toggle_foundry()
	elif event.is_action_pressed("blow_horn"):
		blow_horn()
	elif event.is_action_pressed("save_game"):
		save_game()
	elif event.is_action_pressed("load_game"):
		load_game()
	elif work_panel.is_open() or inventory_panel.is_open() or foundry_panel.is_open() or class_panel.is_open() or chest_panel.is_open():
		return
	elif event.is_action_pressed("hand_craft"):
		open_hand_crafting()
	elif event.is_action_pressed("cycle_shape"):
		placement.cycle_shape()
		var hint: String = inventory.get_sim().shape(placement.placing_shape()).get("hint", "")
		hud.notify("Placing: %s%s" % [placement.selection_label(), "  -  " + hint if hint != "" else ""])
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
	elif event.is_action_pressed("cycle_material"):
		placement.cycle_material()
		hud.notify("Building in %s" % placement.material_label())
	elif event.is_action_pressed("toggle_fine"):
		var fine := placement.toggle_fine()
		hud.notify("Fine pieces: %s" % ("on - half-scale twins of the basic shapes" if fine else "off"))


## The pack screen (I): opens over the world with the mouse released; a
## station's work panel takes precedence while it is open.
## Pack management: drop a stack at your feet as pickups (recoverable) -
## the sim gives it up, the world keeps it.
func drop_material(id: StringName, amount: int) -> bool:
	if amount <= 0 or not inventory.consume_material(id, amount):
		return false
	Pickup.scatter(world_root(), global_position + Vector3(0, 0.6, 0), {String(id): amount},
		ambush_rng.randi(), global_position.y - 0.9)
	hud.notify("Dropped %d %s." % [amount, Hud.pretty(String(id))])
	return true


## The Foundry (D-019): opened from a built forge's panel.
func open_foundry() -> void:
	placement.set_build_mode_enabled(false)
	inventory_panel.close_panel()
	work_panel.close_panel()
	foundry_panel.open_panel()
	_release_mouse()


## F: the plate is yours wherever you stand (D-022). Lifting an ingot
## still costs metal; the forge is where the metal comes from, not where
## the plate lives.
func toggle_foundry() -> void:
	if foundry_panel.is_open():
		foundry_panel.close_panel()
		_capture_mouse()
		return
	if work_panel.is_open() or inventory_panel.is_open() or class_panel.is_open() or chest_panel.is_open():
		return
	open_foundry()


## Before play begins (D-004): the class. Opened by the sandpit when no
## class stands; nothing to do once one does.
func offer_class() -> void:
	if not bool(inventory.get_sim().foundry().get("can_choose_class", false)):
		return
	placement.set_build_mode_enabled(false)
	inventory_panel.close_panel()
	work_panel.close_panel()
	foundry_panel.close_panel()
	class_panel.open_panel()
	_release_mouse()


func toggle_inventory() -> void:
	if work_panel.is_open() or foundry_panel.is_open() or class_panel.is_open() or chest_panel.is_open():
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
		# A save that carries a class needs no choosing.
		if class_panel.is_open() and not bool(inventory.get_sim().foundry().get("can_choose_class", false)):
			class_panel.close_panel()
	hud.notify("Loaded." if ok else "Load failed: %s" % manager.last_error)
	return ok


## The hour, from the sandpit each frame (Wave 6 slice 5): the cold and the
## night's regen go to combat, the lamp brightens as the daylight goes.
func set_day(day: Dictionary, rules: Dictionary) -> void:
	combat.set_day(day, rules)
	if _lamp == null:
		_lamp = OmniLight3D.new()
		_lamp.name = "Lamp"
		_lamp.light_color = Color(1.0, 0.82, 0.6)
		_lamp.omni_range = 9.0
		_lamp.omni_attenuation = 1.4
		_lamp.shadow_enabled = false
		_lamp.position = Vector3(0.0, 1.6, 0.0)
		add_child(_lamp)
	var dark := 1.0 - clampf(float(day.get("daylight", 1.0)), 0.0, 1.0)
	_lamp.light_energy = dark * 1.4
	_lamp.visible = dark > 0.05


## The horn: density on your own terms. False without a horn or while it
## still rings.
func blow_horn() -> bool:
	var sim := inventory.get_sim()
	if inventory.get_count(&"shrieker_horn") <= 0:
		hud.notify("You have no horn to blow. The shriekers of the forest carry them.")
		return false
	if _horn_left > 0.0:
		hud.notify("The horn still rings (%s)." % Hud.clock_text(_horn_left))
		return false
	var rules: Dictionary = sim.noise_rules()
	_horn_left = float(rules.get("horn_cooldown_seconds", 0.0))
	var radius := float(rules.get("radius_m", {}).get("horn", 0.0))
	var woken := MobPacks.noise(get_tree(), global_position, "horn", combat.sheltered)
	PulseRing.burst(world_root(), global_position + Vector3(0, 0.3, 0), radius * (0.35 if combat.sheltered else 1.0), Color(1.0, 0.75, 0.3, 0.45), 1.2)
	hud.notify("You blow the shrieker's horn: everything within %d metres is coming%s." % [
		int(radius), " (%d heard it)" % woken if woken > 0 else ""])
	return true


func horn_cooldown_left() -> float:
	return _horn_left


## Where death sends you (Wave 7 slice 3): home, the last shelter you
## rested in, or the spawn clearing before you have one.
func respawn_point() -> Vector3:
	if combat.has_home:
		return combat.home_position + Vector3(0, 1.2, 0)
	return spawn_position


func _physics_process(delta: float) -> void:
	_horn_left = maxf(0.0, _horn_left - delta)
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
		# A dash breaks a root (Wave 8 slice 1).
		combat.break_root()
		velocity.x = dash.x
		velocity.z = dash.z
	elif combat.rooted():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var input := test_walk if test_walk != Vector2.ZERO else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
		velocity.x = direction.x * move_speed * combat.haste_multiplier()
		velocity.z = direction.z * move_speed * combat.haste_multiplier()

	var fall_speed := -velocity.y
	_step_up(delta)
	move_and_slide()

	# A hard landing dips the camera briefly - weight without screen shake.
	if is_on_floor() and not _was_on_floor and fall_speed > 5.5:
		_land_dip = clampf(fall_speed * 0.014, 0.04, 0.13)
	_was_on_floor = is_on_floor()
	_land_dip = move_toward(_land_dip, 0.0, delta * 0.7)
	spring_arm.position.y = (FP_EYE_HEIGHT if first_person else _tp_arm_position.y) - _land_dip

	_update_digging(delta)


## Stairs and half cubes: a CharacterBody3D climbs slopes but never a
## vertical step, so when the next stride is blocked at foot level, test
## the same stride from STEP_HEIGHT higher; if it is clear there and there
## is ground within a step below the far end, lift onto it. Mobs hop
## (enemy.gd); the player steps.
const STEP_HEIGHT := 0.55
## Test hook: a fake stick input (integration tests walk the player).
var test_walk := Vector2.ZERO


func _step_up(delta: float) -> void:
	if velocity.y > 0.5:
		return  # jumping
	var stride := Vector3(velocity.x, 0.0, velocity.z) * delta
	if stride.length_squared() < 1e-8:
		return
	var here := global_transform
	# Grounded, or as good as: a capsule riding up a block's edge loses its
	# floor contact, and that is exactly when the step is needed.
	if not is_on_floor() and not test_move(here, Vector3.DOWN * 0.3):
		return
	if not test_move(here, stride):
		return  # nothing in the way at foot level
	var lift := Vector3.UP * STEP_HEIGHT
	if test_move(here, lift):
		return  # headroom missing
	var raised := here.translated(lift)
	if test_move(raised, stride):
		return  # still blocked higher up: a wall, not a step
	var landing := KinematicCollision3D.new()
	var over := raised.translated(stride)
	if not test_move(over, -lift, landing):
		return  # no ground within a step below: a ledge, not a step
	var drop := -landing.get_travel().y
	if drop < 0.0 or drop > STEP_HEIGHT:
		return
	global_position.y += STEP_HEIGHT - drop + 0.01
	velocity.y = 0.0


func _find_terrain() -> Terrain:
	if _terrain == null or not is_instance_valid(_terrain):
		_terrain = world_root().get_node_or_null("Terrain") as Terrain
	return _terrain


## The dig loop: while LMB is held on a breakable terrain block (build mode
## off, no panel open), progress fills at the block's dig_seconds; moving
## the aim to a different block starts over. Position is the tool - there
## are no tool tiers yet, only time (worldgen.json block_rules).
func _update_digging(delta: float) -> void:
	var digging := false
	if Input.is_action_pressed("primary_action") and not placement.build_mode_enabled \
			and not work_panel.is_open() and not inventory_panel.is_open():
		var terrain := _find_terrain()
		if terrain != null and not terrain.map.is_empty():
			var from := camera.global_position
			var to := from + (-camera.global_transform.basis.z) * interact_range
			var query := PhysicsRayQueryParameters3D.create(from, to)
			query.exclude = [self]
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and terrain.is_terrain_body(hit.get("collider")):
				var cell := terrain.block_from_surface_hit(hit)
				if terrain.kind_at(cell.x, cell.y, cell.z) == "":
					# Backface hit: the normal faced away; the block is behind.
					cell = terrain.block_from_hit(hit["position"], -hit["normal"])
				var kind := terrain.kind_at(cell.x, cell.y, cell.z)
				var rule: Dictionary = terrain.block_rules.get(kind, {})
				if kind != "" and not rule.get("breakable", false):
					hud.show_dig(kind, -1.0)
					digging = true
				elif kind != "" and not terrain.diggable_by_hand(cell):
					# Fire-setting: rock wants heat and then cold before hands.
					hud.show_dig_text(terrain.dig_refusal(cell))
					digging = true
					if not _fire_hint_shown:
						_fire_hint_shown = true
						hud.notify("The rock will not yield to hands. Fire heats stone; cold cracks what is hot.")
				elif kind != "":
					if cell != _dig_cell:
						_dig_cell = cell
						_dig_progress = 0.0
					_dig_progress += delta
					digging = true
					var need := maxf(rule.get("dig_seconds", 1.0), 0.05)
					hud.show_dig(kind, clampf(_dig_progress / need, 0.0, 1.0))
					if _dig_progress >= need:
						_finish_dig(terrain, cell, rule)
	if not digging:
		_dig_cell = Vector3i(-1, -1, -1)
		_dig_progress = 0.0
		hud.show_dig("", 0.0)


func _finish_dig(terrain: Terrain, cell: Vector3i, rule: Dictionary) -> void:
	_dig_cell = Vector3i(-1, -1, -1)
	_dig_progress = 0.0
	if terrain.break_block(cell.x, cell.y, cell.z) == "":
		return
	var yields: Dictionary = rule.get("yields", {})
	if not yields.is_empty():
		var cs: float = terrain.map["cell_size"]
		var at := Vector3((cell.x + 0.5) * cs, cell.y + 0.6, (cell.z + 0.5) * cs)
		# The yield pops out as physical chips, like every other harvest.
		Pickup.scatter(world_root(), at, yields, ambush_rng.randi(), float(cell.y) + 0.02)


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
	if combat.has_home:
		hud.notify("You wake at home.")
	global_position = respawn_point()
	velocity = Vector3.ZERO
	combat.restore_life()
	combat.invulnerable_left = 2.0


## What a node's work() or strike() returned: chips out for a yield, a
## line for a step, a refusal. Fires the milestone when a blow did the work.
func _apply_work(node: ResourceNode, result: Dictionary) -> void:
	if result.is_empty():
		return
	if result.has("refusal"):
		hud.notify("%s: %s." % [Hud.pretty(String(node.material_family)), result["refusal"]])
		return
	if result.has("text"):
		hud.notify(result["text"])
		# A press is heard (Wave 7 slice 1): the world answers what you do.
		MobPacks.noise(get_tree(), node.global_position, "work", combat.sheltered)
	if result.get("struck", false):
		MobPacks.noise(get_tree(), node.global_position, "strike", combat.sheltered)
	var granted: int = int(result.get("granted", 0))
	if granted > 0:
		if node.drive_presses > 1:
			# A tree coming down, a boulder cracking: heard across the meadow.
			MobPacks.noise(get_tree(), node.global_position, "tree_fall" if node.visual == &"tree" else "rock_crack", combat.sheltered)
		# Feel: the yield pops out of the node as physical chips that
		# vacuum into you; the inventory add happens on absorb.
		Pickup.scatter(world_root(), node.global_position + Vector3(0, 0.9, 0),
			{String(node.material_family): granted}, ambush_rng.randi(), node.global_position.y + 0.02)
		maybe_ambush(node)
		if result.get("struck", false) and node.is_seam():
			# The click that the two halves are one game is a milestone.
			inventory.get_sim().foundry_event("work:strike_split")
			if result.get("synergy", false):
				hud.notify("The hot seam gives way whole.")
			else:
				hud.notify("The blow drives the wedge home.")


## A strike that found no enemy reaches the world instead (D-021: skills
## have properties, materials have responses). A set wedge splits, a hot
## rock cracks. Returns true when something answered.
func strike_world() -> bool:
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * interact_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider: Object = hit.get("collider")
	if collider is ResourceNode:
		var result: Dictionary = (collider as ResourceNode).strike()
		_apply_work(collider as ResourceNode, result)
		return not result.is_empty()
	var terrain := _find_terrain()
	if terrain != null and terrain.is_terrain_body(collider):
		var cell := terrain.block_from_surface_hit(hit)
		if terrain.kind_at(cell.x, cell.y, cell.z) == "":
			cell = terrain.block_from_hit(hit["position"], -hit["normal"])
		if terrain.crack_block(cell):
			hud.notify("The hot rock cracks under the blow.")
			return true
	return false


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
		# The clothed silhouette casts shadows without obscuring the first-person view.
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
		return {"state": "interact", "target": node, "label": node.interact_label(inventory.get_sim())}
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
	if collider is Landmark:
		return {"state": "interact", "label": (collider as Landmark).interact_label(inventory.get_sim()), "target": collider}
	if collider is PlacedBlock and ((collider as PlacedBlock).is_door() or (collider as PlacedBlock).is_chest()):
		return {"state": "interact", "label": (collider as PlacedBlock).interact_label(), "target": collider}
	if collider is Peddler:
		return {"state": "interact", "label": (collider as Peddler).interact_label(), "target": collider}
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
		_apply_work(node, node.work(inventory.get_sim()))
	elif collider is StationSite:
		(collider as StationSite).interact(self)
	elif collider is OrderBoard:
		(collider as OrderBoard).interact(self)
	elif collider is DroppedBundle:
		(collider as DroppedBundle).interact(self)
	elif collider is PlacedBlock:
		if (collider as PlacedBlock).is_chest():
			open_chest(collider as PlacedBlock)
		else:
			(collider as PlacedBlock).toggle()
	elif collider is Peddler:
		(collider as Peddler).interact(self)
	elif collider is TrialGate:
		(collider as TrialGate).interact(self)
	elif collider is Landmark:
		(collider as Landmark).interact(self)
