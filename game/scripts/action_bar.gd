class_name ActionBar
extends HBoxContainer
## Bottom-centre skill bar: one card per bar slot (key cap, skill name and a
## cooldown sweep), read from PlayerCombat's timers every frame (the engine
## owns time; the sim owns the cooldown lengths). Since D-016 the slots come
## from the sim's skill bar - keys 1-4 cast whatever sits there - and the
## bar rebuilds itself whenever the loadout changes (a page learned, a slot
## reassigned, a game loaded). Purely presentational: no input handling.

const SLOT_SIZE := Vector2(92, 60)

var combat: PlayerCombat
## One entry per slot: {skill, card, name, state, bar}.
var slots: Array = []


func setup(in_combat: PlayerCombat) -> void:
	combat = in_combat
	add_theme_constant_override("separation", 6)
	combat.loadout_changed.connect(rebuild)
	rebuild()
	UiTheme.ignore_mouse(self)


## Tears the cards down and rebuilds them from the sim's current bar.
func rebuild() -> void:
	while get_child_count() > 0:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	slots.clear()
	var bar := combat.bar_skills()
	var dash_slot := combat.dash_slot()
	for i in bar.size():
		var skill_id := StringName(bar[i])
		var view: Dictionary = combat.skills.get(skill_id, {})
		var card := PanelContainer.new()
		card.custom_minimum_size = SLOT_SIZE
		card.add_theme_stylebox_override("panel", UiTheme.flat(Color(UiTheme.ASH, 0.85), Color(UiTheme.MUTED, 0.4), 5))
		add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		card.add_child(column)

		var head := HBoxContainer.new()
		column.add_child(head)
		var key := Label.new()
		# Shift stays the dash reflex key wherever Dash is slotted.
		key.text = "%d/Shift" % (i + 1) if i == dash_slot else str(i + 1)
		key.add_theme_font_size_override("font_size", 12)
		key.modulate = UiTheme.SUN_WARM
		head.add_child(key)
		var name := Label.new()
		name.text = view.get("display_name", "-") if skill_id != &"" else "-"
		name.add_theme_font_size_override("font_size", 12)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.modulate = UiTheme.MUTED
		head.add_child(name)

		var state := Label.new()
		state.text = "ready" if skill_id != &"" else "empty"
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state.add_theme_font_size_override("font_size", 14)
		column.add_child(state)

		var bar_widget := ProgressBar.new()
		bar_widget.min_value = 0.0
		bar_widget.max_value = 1.0
		bar_widget.value = 1.0
		bar_widget.show_percentage = false
		bar_widget.custom_minimum_size = Vector2(0, 5)
		column.add_child(bar_widget)
		slots.append({"skill": skill_id, "card": card, "name": name, "state": state, "bar": bar_widget})


func _process(_delta: float) -> void:
	if combat == null:
		return
	for slot in slots:
		var skill_id: StringName = slot["skill"]
		if skill_id == &"":
			slot["card"].modulate = Color(1, 1, 1, 0.55)
			continue
		var left: float = combat.cooldown_left(skill_id)
		var total: float = combat.cooldown_total(skill_id)
		var ready := left <= 0.0
		slot["bar"].value = 1.0 if ready else clampf(1.0 - left / maxf(total, 0.01), 0.0, 1.0)
		slot["state"].text = "ready" if ready else "%.1fs" % left
		slot["state"].modulate = UiTheme.GRASS_LIGHT if ready else UiTheme.MUTED
		slot["card"].modulate = Color(1, 1, 1, 1.0 if ready else 0.75)


## Test surface: cooldown fraction shown for a skill (1 = ready).
func shown_fraction(skill_id: StringName) -> float:
	for slot in slots:
		if slot["skill"] == skill_id:
			return slot["bar"].value
	return -1.0
