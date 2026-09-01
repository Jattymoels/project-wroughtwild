class_name Hud
extends CanvasLayer
## Greybox HUD: material families, currency, Blacksmithing progress, control
## hints and a transient notice line. Everything shown is read from the sim.

const NOTICE_SECONDS := 3.0
const REFRESH_SECONDS := 0.1

var sim: WroughtwildSim
var combat: PlayerCombat
var placement: GridPlacement
var player: WroughtwildPlayer

var _status: Label
var _notice: Label
var _notice_timer := 0.0
var _refresh_timer := 0.0

# First-person feedback (D-012): crosshair that reads the aim, a hitmarker
# blip when a strike connects, and a red flash when damage lands on you.
var _crosshair: Label
var _hitmarker: Label
var _hitmarker_timer := 0.0
var _damage_flash: ColorRect
var _damage_flash_timer := 0.0
var _last_life := -1.0

const CROSSHAIR_NEUTRAL := Color(1, 1, 1, 0.8)
const CROSSHAIR_INTERACT := Color(0.35, 1.0, 0.45, 0.95)
const CROSSHAIR_ENEMY := Color(1.0, 0.35, 0.3, 0.95)


func _ready() -> void:
	var column := VBoxContainer.new()
	column.position = Vector2(12, 12)
	column.custom_minimum_size = Vector2(1000, 0)
	add_child(column)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)

	var hints := Label.new()
	hints.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hints.text = "E interact  ·  C craft by hand  ·  B build mode  ·  Tab shape/kit  ·  LMB place / harvest  ·  X remove  ·  R rotate  ·  1 area strike (cone)  ·  2 heavy strike  ·  3 frost orb  ·  F1-F3 spike mods  ·  Shift dash  ·  V camera  ·  Esc close panel  ·  F5 save  ·  F9 load"
	hints.modulate = Color(1.0, 1.0, 1.0, 0.6)
	column.add_child(hints)

	_notice = Label.new()
	_notice.modulate = Color(1.0, 0.9, 0.5)
	column.add_child(_notice)

	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(0.8, 0.05, 0.05, 0.0)
	_damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_damage_flash)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_crosshair = Label.new()
	_crosshair.text = "+"
	_crosshair.add_theme_font_size_override("font_size", 24)
	_crosshair.modulate = CROSSHAIR_NEUTRAL
	centre.add_child(_crosshair)

	var marker_centre := CenterContainer.new()
	marker_centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	marker_centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker_centre)
	_hitmarker = Label.new()
	_hitmarker.text = "×"
	_hitmarker.add_theme_font_size_override("font_size", 34)
	_hitmarker.modulate = Color(1, 1, 1, 0)
	marker_centre.add_child(_hitmarker)

	if combat != null:
		combat.hit_landed.connect(_on_hit_landed)
		combat.life_changed.connect(_on_life_changed)
	refresh()


func _on_hit_landed(_total_damage: float, kills: int) -> void:
	_hitmarker_timer = 0.16
	_hitmarker.modulate = Color(1.0, 0.35, 0.3, 1.0) if kills > 0 else Color(1, 1, 1, 0.9)


func _on_life_changed(life: float, _max_life: float) -> void:
	if _last_life >= 0.0 and life < _last_life:
		_damage_flash_timer = 0.25
	_last_life = life


func notify(text: String) -> void:
	_notice.text = text
	_notice_timer = NOTICE_SECONDS
	refresh()


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_SECONDS
		refresh()
		_refresh_crosshair()
	if _notice_timer > 0.0:
		_notice_timer -= delta
		if _notice_timer <= 0.0:
			_notice.text = ""
	if _hitmarker_timer > 0.0:
		_hitmarker_timer -= delta
		if _hitmarker_timer <= 0.0:
			_hitmarker.modulate.a = 0.0
	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta
		_damage_flash.color.a = maxf(0.0, _damage_flash_timer) * 0.9


func _refresh_crosshair() -> void:
	if _crosshair == null or player == null:
		return
	match player.aim_state():
		"enemy": _crosshair.modulate = CROSSHAIR_ENEMY
		"interact": _crosshair.modulate = CROSSHAIR_INTERACT
		_: _crosshair.modulate = CROSSHAIR_NEUTRAL


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
		vitals = "\nLife %d / %d  ·  armour %d  ·  fire resistance %d%%  ·  wearing %s    [1] Area %s   [2] Heavy %s   [3] Orb %s   [Shift] Dash %s" % [
			ceili(combat.life), ceili(combat.max_life), int(ds.get("armour", 0.0)), int(ds.get("fire_resistance_percent", 0.0)),
			worn.get("display_name", "nothing"),
			_cooldown_text(PlayerCombat.AREA_SKILL), _cooldown_text(PlayerCombat.HEAVY_SKILL),
			_cooldown_text(PlayerCombat.ORB_SKILL), _cooldown_text(PlayerCombat.DASH_SKILL)]
		var active_mods := PackedStringArray()
		for mod_id in sim.skill_mod_ids():
			if sim.skill_mod_active(mod_id):
				active_mods.append(pretty(mod_id))
		if not active_mods.is_empty():
			vitals += "\nSpike mods on: " + " · ".join(active_mods)
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
