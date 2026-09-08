class_name WorldSeedControls
extends Node
## Seed choice shares the existing class decision; no world is generated until
## that decision or a validated saved-world restore selects its actual identity.
const MAX_SEED := 2147483647 # Exactly representable by existing native seed APIs and JSON saves.
var world: Node3D
var player: WroughtwildPlayer
var field: LineEdit
var message: Label
var continue_button: Button
var row: VBoxContainer
var save_path := SaveManager.DEFAULT_PATH
var loading := false
var finished := false
var _physics: Array[bool] = []
var _scroll: ScrollContainer
var _column: VBoxContainer
var _backdrop: ColorRect
var _preparing: Label
var _rules_before_choice := ""

static func parse_seed(text: String) -> Dictionary:
	var value := text.strip_edges()
	if value.length()>10 or not value.is_valid_int(): return {"valid":false}
	var number := value.to_int()
	return {"valid":number>=0 and number<=MAX_SEED,"seed":number}

static func random_seed() -> int:
	var random := RandomNumberGenerator.new()
	random.randomize()
	return random.randi_range(0,MAX_SEED)

static func argument_seed(args: PackedStringArray) -> Dictionary:
	for arg in args:
		if arg.begins_with("--world-seed="): return {"provided":true,"text":arg.trim_prefix("--world-seed=")}
	return {"provided":false,"text":""}

func configure(host: Node3D, seed_text: String, path := SaveManager.DEFAULT_PATH) -> void:
	world = host
	player = host.get_node("Player") as WroughtwildPlayer
	save_path = path
	_rules_before_choice = player.inventory.get_sim().export_json()
	for subject in [player,player.combat,player.placement]:
		_physics.append(subject.is_physics_processing())
		subject.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.offer_class()
	_backdrop = ColorRect.new()
	_backdrop.name = "WorldSeedBackdrop"
	_backdrop.color = UiTheme.INK
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	player.class_panel.add_child(_backdrop)
	player.class_panel.move_child(_backdrop,0)
	player.class_panel.closed.connect(_chosen)
	row = VBoxContainer.new()
	row.name = "WorldSeedChoices"
	# ClassPanel scrolls its choices inside the outer introduction column.
	# Seed/Continue controls belong beside that scroll, not inside it.
	var column := player.class_panel._scroll.get_parent()
	column.add_child(row)
	column.move_child(row,2)
	var inputs := HBoxContainer.new()
	row.add_child(inputs)
	var label := Label.new()
	label.text = "New world seed"
	inputs.add_child(label)
	field = LineEdit.new()
	field.custom_minimum_size.x = 210
	field.text = seed_text
	field.tooltip_text = "Any whole number from 0 to 2147483647. The same seed and world version recreate the same geography."
	inputs.add_child(field)
	var randomise := Button.new()
	randomise.text = "Randomise"
	randomise.pressed.connect(func(): field.text = str(random_seed()); _validate())
	inputs.add_child(randomise)
	message = Label.new()
	message.modulate = UiTheme.MUTED
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(message)
	if FileAccess.file_exists(path) or FileAccess.file_exists(path+".previous"):
		continue_button = Button.new()
		continue_button.text = "Continue saved world / suspended trial"
		continue_button.pressed.connect(continue_saved)
		row.add_child(continue_button)
	field.text_changed.connect(func(_text: String): _validate())
	_validate()
	# Keep the existing class descriptions reachable on ordinary laptop-size
	# windows without turning this into another startup decision.
	_column = column as VBoxContainer
	var margin := _column.get_parent()
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.remove_child(_column)
	margin.add_child(_scroll)
	_scroll.add_child(_column)
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel.call_deferred()

func _fit_panel() -> void:
	if finished or not is_instance_valid(_scroll): return
	_scroll.custom_minimum_size = Vector2(960,minf(_column.get_combined_minimum_size().y,maxf(180,get_viewport().get_visible_rect().size.y-72)))

func _validate() -> void:
	var valid := bool(parse_seed(field.text).valid)
	message.text = "Choose a class to begin. Your existing save changes only when you save." if valid else "Enter a whole seed from 0 to 2147483647."
	for choice in player.class_panel._choices.get_children():
		for control in choice.get_children():
			if control is Button: control.disabled = not valid

func _chosen() -> void:
	if loading or finished: return
	var parsed := parse_seed(field.text)
	if not bool(parsed.valid): return
	loading = true
	_preparing = Label.new()
	_preparing.text = "Preparing your world…"
	_preparing.theme = UiTheme.theme()
	_preparing.add_theme_font_size_override("font_size",22)
	_preparing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preparing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preparing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preparing.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.add_child(_preparing)
	# Generation is synchronous. Submit the feedback frame before beginning
	# that work so a normal launch does not appear frozen on its class click.
	if DisplayServer.get_name()=="headless": await get_tree().process_frame
	else: await RenderingServer.frame_post_draw
	var prepared := bool(world.call("start_chosen_world",int(parsed.seed)))
	if not prepared:
		var sim := player.inventory.get_sim()
		var reason := sim.last_error()
		if not sim.import_json(_rules_before_choice):
			_preparing.text = "The initial player state could not be restored. Close and reopen the game."
			return
		player.combat.loadout_changed.emit()
		_preparing.queue_free()
		loading = false
		player.offer_class()
		_validate()
		message.text = "This seed could not be prepared. Choose another seed and try again."
		if not reason.is_empty(): message.text += "\n"+reason
		_scroll.scroll_vertical = 0
		_fit_panel.call_deferred()
		return
	loading = false
	finished = true
	release()

func continue_saved() -> bool:
	if loading or finished: return false
	loading = true
	var loaded := player.load_game(save_path)
	loading = false
	if not loaded:
		message.text = player.hud._notice.text
		return false
	finished = true
	player.class_panel.close_panel()
	world.call("saved_world_started")
	release()
	return true

func release() -> void:
	if is_instance_valid(row): row.queue_free()
	if is_instance_valid(_backdrop): _backdrop.queue_free()
	if get_viewport().size_changed.is_connected(_fit_panel): get_viewport().size_changed.disconnect(_fit_panel)
	if is_instance_valid(_scroll):
		var margin := _scroll.get_parent()
		_scroll.remove_child(_column)
		margin.remove_child(_scroll)
		margin.add_child(_column)
		_scroll.queue_free()
	if player.class_panel.closed.is_connected(_chosen): player.class_panel.closed.disconnect(_chosen)
	var subjects := [player,player.combat,player.placement]
	for i in subjects.size(): subjects[i].set_physics_process(_physics[i])
	player.set_process_unhandled_input(true)
	player.offer_class() # Only a save without a chosen class still needs this.

static func show_identity(owner_player: WroughtwildPlayer, seed_value: int, profile: String) -> void:
	var column := owner_player.hud._help.get_child(0).get_child(0)
	var label := column.get_node_or_null("WorldIdentity") as Label
	if label == null:
		label = Label.new()
		label.name = "WorldIdentity"
		label.modulate = UiTheme.MUTED
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	label.text = "World seed: %d · %s" % [seed_value,profile]
