class_name BuildPalette
extends CanvasLayer
## Selection only. Prices, unlocks and material compatibility come from the sim.
signal closed
const LOOK = preload("res://art/build_ui_look.tres")
var player: WroughtwildPlayer
var placement: GridPlacement
var root: PanelContainer
var grid: GridContainer
var scroll: ScrollContainer
var material_picker: OptionButton
var group_picker: OptionButton
var fine: CheckButton
var detail: RichTextLabel
var title: Label
var picture: BuildThumbnail
var turn_left: Button
var turn_right: Button
var cards := {}
var group := "All pieces"

func _ready() -> void:
	layer = 10
	root = PanelContainer.new()
	root.theme = UiTheme.theme()
	add_child(root)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,16)
	root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading := Label.new()
	heading.text = "Build · choose a shape"
	heading.add_theme_font_size_override("font_size",22)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close := Button.new()
	close.text = "Close · Tab / Esc"
	close.pressed.connect(close_panel)
	header.add_child(close)
	var choices := HBoxContainer.new()
	column.add_child(choices)
	group_picker = OptionButton.new()
	for name in ["All pieces","Corners & roofs","Walls & floors","Frames","Furnishings & kits"]:
		group_picker.add_item(name)
	group_picker.item_selected.connect(func(index: int) -> void:
		group = group_picker.get_item_text(index)
		refresh())
	choices.add_child(group_picker)
	material_picker = OptionButton.new()
	material_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	material_picker.item_selected.connect(func(index: int) -> void:
		select_material(StringName(material_picker.get_item_metadata(index))))
	choices.add_child(material_picker)
	fine = CheckButton.new()
	fine.text = "Half-size basics"
	fine.toggled.connect(func(on: bool) -> void:
		if placement.fine_mode != on:
			placement.toggle_fine()
		refresh())
	choices.add_child(fine)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",16)
	column.add_child(body)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	var inspector := VBoxContainer.new()
	inspector.custom_minimum_size.x = 290
	body.add_child(inspector)
	title = Label.new()
	title.add_theme_font_size_override("font_size",20)
	inspector.add_child(title)
	picture = BuildThumbnail.new()
	picture.custom_minimum_size = Vector2(260,160)
	inspector.add_child(picture)
	var turns := HBoxContainer.new()
	inspector.add_child(turns)
	turn_left = Button.new()
	turn_left.text = "↶ Turn left"
	turn_left.pressed.connect(func() -> void: turn(-1))
	turns.add_child(turn_left)
	turn_right = Button.new()
	turn_right.text = "Turn right ↷"
	turn_right.pressed.connect(func() -> void: turn(1))
	turns.add_child(turn_right)
	detail = RichTextLabel.new()
	detail.custom_minimum_size = Vector2(290,100)
	detail.fit_content = false
	detail.scroll_active = true
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector.add_child(detail)
	var use := Button.new()
	use.text = "Use selection · return to build"
	use.pressed.connect(close_panel)
	inspector.add_child(use)
	root.hide()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	root.size = Vector2(minf(LOOK.panel_size.x,viewport.x-32),minf(LOOK.panel_size.y,viewport.y-48))
	root.position = (viewport-root.size)/2.0
	grid.columns = 4 if viewport.x >= 1100 else 3

func is_open() -> bool:
	return root != null and root.visible

func open_panel() -> void:
	for panel in [player.work_panel,player.inventory_panel,player.foundry_panel,player.class_panel,player.chest_panel]:
		if panel != null and panel.is_open():
			return
	placement.set_build_mode_enabled(true)
	placement.palette_open = true
	placement._hide_preview()
	root.show()
	refresh()
	player._release_mouse()

func close_panel() -> void:
	if not is_open():
		return
	root.hide()
	placement.palette_open = false
	closed.emit()

func _process(_delta: float) -> void:
	if not is_open():
		return
	# A trial result can open a work panel without a keyboard event.
	for panel in [player.work_panel,player.inventory_panel,player.foundry_panel,player.class_panel,player.chest_panel]:
		if panel != null and panel.is_open():
			close_panel()
			player._release_mouse()
			return

func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cycle_shape"):
		close_panel()
		get_viewport().set_input_as_handled()

func select_entry(id: StringName, kind: String = "shape") -> void:
	if kind == "kit":
		if player.inventory.get_sim().material_count(id) <= 0:
			return
		placement._select_kit(id)
	else:
		placement.select_shape(id)
	refresh()

func select_material(id: StringName) -> void:
	if player.inventory.get_sim().build_material(id).is_empty():
		return
	placement.selected_material_family = id
	placement._refresh_selection()
	refresh()

func turn(direction: int) -> void:
	placement.rotate_preview(direction)
	refresh_detail()

func category(info: Dictionary) -> String:
	var form: String = info.get("form","box")
	if form == "corner" or form == "wedge" or form.begins_with("roof_"):
		return "Corners & roofs"
	if form in ["fire","chest"]:
		return "Furnishings & kits"
	if info.get("element","") in ["post","beam"]:
		return "Frames"
	return "Walls & floors"

func refresh() -> void:
	var sim := player.inventory.get_sim()
	for index in group_picker.item_count:
		if group_picker.get_item_text(index) == group:
			group_picker.select(index)
	material_picker.clear()
	for id in sim.build_material_ids():
		var info: Dictionary = sim.build_material(id)
		material_picker.add_item("%s · %d carried" % [info.display_name,info.carried])
		var index := material_picker.item_count-1
		material_picker.set_item_metadata(index,id)
		if id == String(placement.selected_material_family):
			material_picker.select(index)
	fine.set_pressed_no_signal(placement.fine_mode)
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	cards.clear()
	for entry in placement.placeables():
		var kit: bool = entry.kind == "kit"
		var id: StringName = entry.id
		var actual: StringName = placement._fine_twins.get(id,id) if placement.fine_mode and not kit else id
		var info: Dictionary = sim.shape(actual) if not kit else {}
		var family := "Furnishings & kits" if kit else category(info)
		if group != "All pieces" and family != group:
			continue
		var card := Button.new()
		card.custom_minimum_size = LOOK.tile_size
		card.toggle_mode = true
		card.button_pressed = id == (placement.selected_kit if placement.selected_kit != &"" else placement.selected_shape)
		card.pressed.connect(select_entry.bind(id,entry.kind))
		grid.add_child(card)
		cards[String(id)] = card
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 5
		content.offset_right = -5
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		var icon := BuildThumbnail.new()
		icon.custom_minimum_size = Vector2(140,66)
		icon.mesh = _mesh(id,kit)
		icon.colour = PieceLook.swatch_for(placement.selected_material_family)
		content.add_child(icon)
		var label := Label.new()
		label.text = Hud.pretty(String(id)) if kit else String(info.display_name)
		label.add_theme_font_size_override("font_size",13)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		var cost := Label.new()
		cost.text = "%d held" % sim.material_count(id) if kit else "Locked" if not sim.shape_unlocked(actual) else "%d %s" % [info.material_cost,placement.material_label()]
		cost.modulate = UiTheme.MUTED if kit or sim.shape_unlocked(actual) else UiTheme.EMBER
		cost.add_theme_font_size_override("font_size",12)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(cost)
	refresh_detail()
	_layout()

func _mesh(id: StringName, kit: bool) -> Mesh:
	var sim := player.inventory.get_sim()
	if kit:
		return preload("res://art/station_look.tres").mesh_for(StringName(sim.kit_station(id)))
	var actual: StringName = placement._fine_twins.get(id,id) if placement.fine_mode else id
	var info: Dictionary = sim.shape(actual)
	return PieceLook.mesh_for(actual,info.get("form","box"),info["size"],placement.selected_material_family)

func refresh_detail() -> void:
	var kit := placement.selected_kit != &""
	title.text = placement.selection_label()
	picture.mesh = _mesh(placement.selected_kit if kit else placement.selected_shape,kit)
	picture.colour = PieceLook.swatch_for(placement.selected_material_family)
	picture.show_material(player.inventory.get_sim(),placement.selected_material_family,"station" if kit else placement.shape_form)
	picture.turn = (placement.preview_rotation_step%2)*2 if placement.shape_form == "door" else placement.preview_rotation_step
	picture.arrow = placement.rotatable()
	picture.queue_redraw()
	turn_left.disabled = not placement.rotatable()
	turn_right.disabled = not placement.rotatable()
	var info: Dictionary = player.inventory.get_sim().shape(placement.placing_shape())
	detail.text = "%s\n\n%s\n\n%s" % [placement.cost_label(),placement.orientation_label(),info.get("hint","") if not kit else "Place this crafted station kit on clear ground."]
	var reason := placement.selection_refusal()
	if reason != "":
		detail.text += "\n\n"+reason
