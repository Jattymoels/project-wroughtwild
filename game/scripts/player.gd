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

var hud: Hud
var work_panel: WorkPanel


func _ready() -> void:
	placement.camera = camera
	placement.inventory = inventory

	hud = Hud.new()
	hud.sim = inventory.get_sim()
	add_child(hud)

	work_panel = WorkPanel.new()
	work_panel.sim = inventory.get_sim()
	work_panel.closed.connect(_capture_mouse)
	add_child(work_panel)

	_capture_mouse()


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		spring_arm.rotation.x = clampf(
			spring_arm.rotation.x - event.relative.y * mouse_sensitivity,
			-PI / 3.0, PI / 3.0)
	elif event.is_action_pressed("ui_cancel"):
		work_panel.close_panel()
	elif work_panel.is_open():
		return
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


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	move_and_slide()


func interact() -> void:
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
	elif collider is StationSite:
		(collider as StationSite).interact(self)
	elif collider is OrderBoard:
		(collider as OrderBoard).interact(self)
