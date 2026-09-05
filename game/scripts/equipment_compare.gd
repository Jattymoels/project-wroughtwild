class_name EquipmentCompare
extends PanelContainer
## Presentation of a read-only sim preview. No rule resolution or inventory writes.
signal back_requested
signal equip_requested
var content: VBoxContainer
var _scroll: ScrollContainer
var _columns: HBoxContainer
var delta_count := 0

func _ready() -> void:
	theme = UiTheme.theme()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(960,0)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,18)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "Compare equipment"
	title.add_theme_font_size_override("font_size",22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := Button.new()
	back.text = "Back to pack"
	back.pressed.connect(func(): back_requested.emit())
	header.add_child(back)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(_scroll)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(content)
	var equip := Button.new()
	equip.text = "Equip candidate"
	equip.pressed.connect(func(): equip_requested.emit())
	layout.add_child(equip)
	hide()
	resized.connect(_centre)
	get_viewport().size_changed.connect(_fit)

func display(preview: Dictionary, make_card: Callable) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	delta_count = 0
	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation",18)
	content.add_child(_columns)
	for key in ["current","candidate"]:
		var side := VBoxContainer.new()
		side.custom_minimum_size.x = 440
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_columns.add_child(side)
		var heading := Label.new()
		heading.text = "Wearing now" if key=="current" else "Candidate"
		heading.modulate = UiTheme.MUTED
		side.add_child(heading)
		if preview[key].is_empty():
			var empty := Label.new()
			empty.text = "Empty "+Hud.pretty(preview.slot)+" slot"
			side.add_child(empty)
		else:
			side.add_child(make_card.call(preview[key],"",Callable()))
	var heading := Label.new()
	heading.text = "Your build after the swap"
	heading.add_theme_font_size_override("font_size",18)
	content.add_child(heading)
	var changes := GridContainer.new()
	changes.columns = 4
	changes.add_theme_constant_override("h_separation",24)
	changes.add_theme_constant_override("v_separation",5)
	content.add_child(changes)
	for text in ["Stat / skill","Now","After","Change"]:
		_cell(changes,text,UiTheme.MUTED)
	for key in preview.before:
		var labels := {"max_life":"Max life","armour":"Armour","fire_resistance_percent":"Fire resistance (%)","cold_resistance_percent":"Cold resistance (%)","area_bonus":"Area bonus (%)"}
		_delta(changes,labels.get(key,Hud.pretty(key)),float(preview.before[key]),float(preview.after[key]),false,key=="area_bonus")
	for skill in preview.skills:
		for key in skill.before:
			if not is_equal_approx(float(skill.before[key]),float(skill.after[key])):
				_delta(changes,skill.display_name+" · "+Hud.pretty(key),float(skill.before[key]),float(skill.after[key]),key=="cooldown_seconds")
	var note := Label.new()
	note.text = "Hit payload is per hit before enemy defence, critical rolls and trial boons. It is not DPS.\nConditional effects and held-back tiers are listed on the item cards above."
	note.modulate = UiTheme.MUTED
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	show()
	_scroll.scroll_vertical = 0
	_fit.call_deferred()

func _delta(grid: GridContainer, label: String, before: float, after: float, lower_better: bool=false, percent: bool=false) -> void:
	if percent:
		before *= 100.0
		after *= 100.0
	var diff := after-before
	_cell(grid,label,UiTheme.PARCHMENT)
	_cell(grid,"%.2f" % before,UiTheme.MUTED)
	_cell(grid,"%.2f" % after,UiTheme.PARCHMENT)
	var colour := UiTheme.MUTED if is_zero_approx(diff) else UiTheme.GRASS_LIGHT if (diff<0.0 if lower_better else diff>0.0) else UiTheme.EMBER
	_cell(grid,"—" if is_zero_approx(diff) else "%+.2f" % diff,colour)
	if not is_zero_approx(diff):
		delta_count += 1

func _cell(grid: GridContainer, text: String, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = colour
	label.add_theme_font_size_override("font_size",14)
	grid.add_child(label)

func _fit() -> void:
	await get_tree().process_frame
	var viewport_size := get_viewport_rect().size
	_scroll.custom_minimum_size.y = minf(content.get_combined_minimum_size().y+8,viewport_size.y*0.66)
	_centre()

func _centre() -> void:
	position = (get_viewport_rect().size-size)*0.5
