class_name Hud
extends CanvasLayer
## Greybox HUD: material families, currency, Blacksmithing progress, control
## hints and a transient notice line. Everything shown is read from the sim.

const NOTICE_SECONDS := 3.0
const REFRESH_SECONDS := 0.1

var sim: WroughtwildSim
var combat: PlayerCombat
var placement: GridPlacement

var _status: Label
var _notice: Label
var _notice_timer := 0.0
var _refresh_timer := 0.0


func _ready() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(12, 12)
	add_child(column)

	_status = Label.new()
	column.add_child(_status)

	var hints := Label.new()
	hints.text = "E interact  ·  B build mode  ·  Tab shape  ·  LMB place / harvest  ·  X remove  ·  R rotate  ·  1 area strike  ·  2 heavy strike  ·  Shift dash  ·  Esc close panel  ·  F5 save  ·  F9 load"
	hints.modulate = Color(1.0, 1.0, 1.0, 0.6)
	column.add_child(hints)

	_notice = Label.new()
	_notice.modulate = Color(1.0, 0.9, 0.5)
	column.add_child(_notice)
	refresh()


func notify(text: String) -> void:
	_notice.text = text
	_notice_timer = NOTICE_SECONDS
	refresh()


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_SECONDS
		refresh()
	if _notice_timer > 0.0:
		_notice_timer -= delta
		if _notice_timer <= 0.0:
			_notice.text = ""


static func pretty(id: String) -> String:
	return id.replace("_", " ")


func refresh() -> void:
	if sim == null:
		return
	var parts := PackedStringArray()
	var held: Dictionary = sim.inventory()
	for id in held:
		if held[id] > 0:
			parts.append("%s %d" % [pretty(id), held[id]])
	var coins: Dictionary = sim.currency()
	for id in coins:
		if coins[id] > 0:
			parts.append("%s %d" % [pretty(id), coins[id]])
	var holdings := " · ".join(parts) if parts.size() > 0 else "Nothing gathered yet"

	var skill: Dictionary = sim.skill_progress("blacksmithing")
	var progress := ""
	if not skill.is_empty():
		var next: String = "max" if skill["next_level_xp"] < 0 else str(skill["next_level_xp"])
		progress = "\n%s level %d  (%d / %s xp)" % [skill["display_name"], skill["level"], skill["xp"], next]

	var vitals := ""
	if combat != null and combat.sim != null:
		var ds: Dictionary = sim.derived_stats()
		var worn: Dictionary = sim.equipment().get("chest", {})
		vitals = "\nLife %d / %d  ·  armour %d  ·  fire resistance %d%%  ·  wearing %s    [1] Area %s   [2] Heavy %s   [Shift] Dash %s" % [
			ceili(combat.life), ceili(combat.max_life), int(ds.get("armour", 0.0)), int(ds.get("fire_resistance_percent", 0.0)),
			worn.get("display_name", "nothing"),
			_cooldown_text(PlayerCombat.AREA_SKILL), _cooldown_text(PlayerCombat.HEAVY_SKILL),
			_cooldown_text(PlayerCombat.DASH_SKILL)]
	if placement != null:
		var shape: Dictionary = sim.shape(placement.selected_shape)
		vitals += "\nBuild: %s (%s, %d per block; Tab to change)" % [
			shape.get("display_name", placement.selected_shape), pretty(placement.selected_material_family),
			shape.get("material_cost", 0)]
	var run := ""
	if sim.trial_active():
		var state: Dictionary = sim.trial_run_state()
		var names := PackedStringArray()
		for b in state["boons"]:
			names.append(b["display_name"])
		for w in state["weaknesses"]:
			names.append("cursed: " + w["display_name"])
		run = "\nIN THE TRIAL  ·  loot: %s  ·  %s" % [
			WorkPanel.amounts_text(sim.trial_loot()) if not sim.trial_loot().is_empty() else "nothing yet",
			", ".join(names) if not names.is_empty() else "no blessings"]
	_status.text = holdings + progress + vitals + run


func _cooldown_text(skill_id: StringName) -> String:
	var left := combat.cooldown_left(skill_id)
	return "ready" if left <= 0.0 else "%.1fs" % left
