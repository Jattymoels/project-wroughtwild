class_name Hud
extends CanvasLayer
## The always-on layer (docs/systems/interface.md): life bar with defences,
## the action bar with cooldown sweeps, the build chip, a right-aligned
## holdings strip, notices, the pickup ticker, crosshair and target line,
## and the H help overlay. Everything shown is read from the sim or from
## engine-owned timers. Nothing here takes the mouse: every control ignores
## it, recursively, once built.

const NOTICE_SECONDS := 3.0
const REFRESH_SECONDS := 0.1
const HELP_TEXT := """WASD move  ·  mouse look  ·  Space jump  ·  Shift dash (movement only)
E interact: harvest, work at a station, read the board, open the gate
LMB harvest  ·  hold LMB on the ground to dig it out (stone pays stone)
LMB places in build mode  ·  C craft by hand  ·  I pack
B build mode  ·  Tab shape or kit  ·  X remove  ·  R turn stairs, wedges, a door's hinge
Pieces snap to the nearest free cell, face or edge you look at: walls join walls, posts stack
G fine pieces: half-scale twins of the cube, wall, post, beam and slab  ·  E opens a door
Q building material: timber, stone or iron from your pack - doors need joinery, cut stone needs stone, girders need iron
1–4 skill bar (assign skills in the pack screen; Shift also dashes)
Mobs drop skill pages that teach new skills, and rolled gear that scales them
F1–F3 spike mods (debug: force one modifier on)
V camera  ·  H this help  ·  Esc close  ·  F5 save  ·  F9 load"""

var sim: WroughtwildSim
var combat: PlayerCombat
var placement: GridPlacement
var player: WroughtwildPlayer

var _ui: Control
var _status: Label
var _trial_prompt: Label
var _notice: Label
var _notice_timer := 0.0
var _refresh_timer := 0.0
var _holdings: Label
var _life_bar: ProgressBar
var _life_text: Label
var _build_chip: Label
var _help: PanelContainer
var action_bar: ActionBar

# First-person feedback (D-012): crosshair that reads the aim, a hitmarker
# blip when a strike connects, and a red flash when damage lands on you.
var _crosshair: Label
var _hitmarker: Label
var _hitmarker_timer := 0.0
var _damage_flash: ColorRect
var _damage_flash_timer := 0.0
var _last_life := -1.0

# Look-at feedback: the target names itself under the crosshair and
# harvestables glow while aimed at.
var _target_label: Label
var _hovered: Node = null
## While digging, this replaces the target label (set by show_dig).
var _dig_text := ""

# Pickup ticker: absorbed drops aggregate into one green line ("+3 wood ·
# +1 iron ore") instead of a notify per chip.
const PICKUP_SECONDS := 2.4
var _pickup_label: Label
var _pickup_totals := {}
var _pickup_timer := 0.0

const CROSSHAIR_NEUTRAL := Color(1, 1, 1, 0.8)
const CROSSHAIR_INTERACT := Color(0.35, 1.0, 0.45, 0.95)
const CROSSHAIR_ENEMY := Color(1.0, 0.35, 0.3, 0.95)


func _ready() -> void:
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.theme = UiTheme.theme()
	add_child(_ui)

	# Top-left: progress, notices, the pickup ticker, one-line reminder.
	var column := VBoxContainer.new()
	column.position = Vector2(12, 12)
	column.custom_minimum_size = Vector2(620, 0)
	_ui.add_child(column)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	_trial_prompt = Label.new()
	_trial_prompt.add_theme_font_size_override("font_size", 18)
	_trial_prompt.modulate = UiTheme.SUN_WARM
	column.add_child(_trial_prompt)
	_notice = Label.new()
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.modulate = Color(1.0, 0.9, 0.5)
	column.add_child(_notice)
	_pickup_label = Label.new()
	_pickup_label.modulate = UiTheme.GRASS_LIGHT
	column.add_child(_pickup_label)
	var reminder := Label.new()
	reminder.text = "H help  ·  I pack"
	reminder.add_theme_font_size_override("font_size", 13)
	reminder.modulate = UiTheme.MUTED
	column.add_child(reminder)

	# Top-right: what you carry, at a glance.
	_holdings = Label.new()
	_holdings.anchor_left = 1.0
	_holdings.anchor_right = 1.0
	_holdings.offset_left = -560
	_holdings.offset_right = -12
	_holdings.offset_top = 12
	_holdings.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_holdings.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_holdings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_holdings.modulate = UiTheme.PARCHMENT
	_ui.add_child(_holdings)

	# Bottom-left: life and defences, on a dark backing so the text reads
	# over bright meadow as well as dark wastes.
	var vitals_panel := PanelContainer.new()
	vitals_panel.anchor_top = 1.0
	vitals_panel.anchor_bottom = 1.0
	vitals_panel.offset_left = 12
	vitals_panel.offset_right = 400
	vitals_panel.offset_top = -66
	vitals_panel.offset_bottom = -12
	vitals_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	vitals_panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(UiTheme.INK, 0.7), Color(0, 0, 0, 0), 5))
	_ui.add_child(vitals_panel)
	var vitals := VBoxContainer.new()
	vitals.add_theme_constant_override("separation", 2)
	vitals_panel.add_child(vitals)
	_life_bar = ProgressBar.new()
	_life_bar.show_percentage = false
	_life_bar.custom_minimum_size = Vector2(360, 16)
	_life_bar.add_theme_stylebox_override("fill", UiTheme.flat(UiTheme.EMBER, Color(0, 0, 0, 0), 3))
	vitals.add_child(_life_bar)
	_life_text = Label.new()
	_life_text.add_theme_font_size_override("font_size", 13)
	vitals.add_child(_life_text)

	# Bottom-centre: the action bar, centred; the life panel sits to its left
	# and the build chip to its right, so nothing overlaps at 1280 wide.
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bottom.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_top = -80
	bottom.offset_bottom = -12
	bottom.alignment = BoxContainer.ALIGNMENT_END
	_ui.add_child(bottom)
	if combat != null:
		action_bar = ActionBar.new()
		action_bar.setup(combat)
		action_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bottom.add_child(action_bar)

	# Bottom-right: what build mode would place.
	var chip_panel := PanelContainer.new()
	chip_panel.anchor_left = 1.0
	chip_panel.anchor_right = 1.0
	chip_panel.anchor_top = 1.0
	chip_panel.anchor_bottom = 1.0
	chip_panel.offset_right = -12
	chip_panel.offset_bottom = -12
	chip_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	chip_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	chip_panel.add_theme_stylebox_override("panel", UiTheme.flat(Color(UiTheme.INK, 0.7), Color(0, 0, 0, 0), 5))
	_ui.add_child(chip_panel)
	_build_chip = Label.new()
	_build_chip.add_theme_font_size_override("font_size", 14)
	_build_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chip_panel.add_child(_build_chip)

	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(0.8, 0.05, 0.05, 0.0)
	_damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_damage_flash)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(centre)
	_crosshair = Label.new()
	_crosshair.text = "+"
	_crosshair.add_theme_font_size_override("font_size", 24)
	_crosshair.modulate = CROSSHAIR_NEUTRAL
	centre.add_child(_crosshair)

	var marker_centre := CenterContainer.new()
	marker_centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(marker_centre)
	_hitmarker = Label.new()
	_hitmarker.text = "×"
	_hitmarker.add_theme_font_size_override("font_size", 34)
	_hitmarker.modulate = Color(1, 1, 1, 0)
	marker_centre.add_child(_hitmarker)

	# The target line sits a fixed distance below the crosshair (a spacer in
	# a centred column keeps the crosshair itself from shifting).
	var target_centre := CenterContainer.new()
	target_centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(target_centre)
	var target_column := VBoxContainer.new()
	target_centre.add_child(target_column)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 84)
	target_column.add_child(spacer)
	_target_label = Label.new()
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_label.modulate = Color(1, 1, 1, 0.85)
	target_column.add_child(_target_label)

	# Help overlay (H): the control list, off by default.
	_help = PanelContainer.new()
	_help.set_anchors_preset(Control.PRESET_CENTER)
	_help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_help.grow_vertical = Control.GROW_DIRECTION_BOTH
	_help.visible = false
	_ui.add_child(_help)
	var help_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		help_margin.add_theme_constant_override(side, 18)
	_help.add_child(help_margin)
	var help_column := VBoxContainer.new()
	help_column.add_theme_constant_override("separation", 8)
	help_margin.add_child(help_column)
	var help_title := Label.new()
	help_title.text = "Controls"
	help_title.add_theme_font_size_override("font_size", 20)
	help_column.add_child(help_title)
	var help_body := Label.new()
	help_body.text = HELP_TEXT
	help_body.custom_minimum_size = Vector2(640, 0)
	help_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_column.add_child(help_body)
	var help_footer := Label.new()
	help_footer.text = "H or Esc to close"
	help_footer.modulate = UiTheme.MUTED
	help_column.add_child(help_footer)

	# The 1 Sep 2026 bug: any HUD control left at MOUSE_FILTER_STOP swallows
	# mouse look under the captured cursor. Never again, for any of them.
	UiTheme.ignore_mouse(_ui)

	if combat != null:
		combat.hit_landed.connect(_on_hit_landed)
		combat.life_changed.connect(_on_life_changed)
		combat.hit_taken.connect(_on_hit_taken)
		combat.shelter_changed.connect(_on_shelter_changed)
	refresh()


## Every hit names its source in the notice line: "-6  Gloom Crawler".
## Owner playtest (2 Sep 2026): damage with no visible attacker must at
## least say who.
func _on_shelter_changed(sheltered: bool) -> void:
	if sheltered:
		notify("Sheltered. Rest here and your wounds close.")
	else:
		notify("Out in the open again.")


func _on_hit_taken(damage: float, source_name: String) -> void:
	notify("-%d  %s" % [ceili(damage), source_name if source_name != "" else "unknown"])


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


## Dig feedback under the crosshair: a filling bar per held block, a flat
## refusal for the unbreakable, "" to clear (fraction ignored then).
func show_dig(kind: String, fraction: float) -> void:
	if kind == "":
		_dig_text = ""
		return
	if fraction < 0.0:
		_dig_text = "%s will not break" % pretty(kind)
		return
	var filled := clampi(roundi(fraction * 10.0), 0, 10)
	_dig_text = "Digging %s  [%s%s]" % [pretty(kind), "#".repeat(filled), "-".repeat(10 - filled)]


## Absorbed pickups accumulate into one line while they keep arriving.
func notify_pickup(family: String, amount: int) -> void:
	_pickup_totals[family] = int(_pickup_totals.get(family, 0)) + amount
	_pickup_timer = PICKUP_SECONDS
	var parts := PackedStringArray()
	for id in _pickup_totals:
		parts.append("+%d %s" % [_pickup_totals[id], pretty(id)])
	_pickup_label.text = " · ".join(parts)
	refresh()


func toggle_help() -> void:
	_help.visible = not _help.visible


func help_visible() -> bool:
	return _help.visible


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
	if _pickup_timer > 0.0:
		_pickup_timer -= delta
		if _pickup_timer <= 0.0:
			_pickup_totals.clear()
			_pickup_label.text = ""


func _refresh_crosshair() -> void:
	if _crosshair == null or player == null:
		return
	var probe: Dictionary = player.aim_probe()
	match probe["state"]:
		"enemy": _crosshair.modulate = CROSSHAIR_ENEMY
		"interact": _crosshair.modulate = CROSSHAIR_INTERACT
		_: _crosshair.modulate = CROSSHAIR_NEUTRAL
	_target_label.text = _dig_text if _dig_text != "" else probe["label"]

	# Hover highlight: glow the harvestable you are looking at.
	var target: Node = probe["target"] as Node
	if target != _hovered:
		if is_instance_valid(_hovered) and _hovered.has_method("set_highlight"):
			_hovered.set_highlight(false)
		_hovered = target
		if is_instance_valid(_hovered) and _hovered.has_method("set_highlight"):
			_hovered.set_highlight(true)


static func pretty(id: String) -> String:
	return id.replace("_", " ")


## Test surface: the holdings strip text.
func holdings_text() -> String:
	return _holdings.text


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
	_holdings.text = " · ".join(parts) if parts.size() > 0 else "Nothing gathered yet"

	var lines := PackedStringArray()
	var skill: Dictionary = sim.skill_progress("blacksmithing")
	if not skill.is_empty():
		var next: String = "max" if skill["next_level_xp"] < 0 else str(skill["next_level_xp"])
		lines.append("%s level %d  (%d / %s xp)" % [skill["display_name"], skill["level"], skill["xp"], next])
	if sim.trial_active():
		var state: Dictionary = sim.trial_run_state()
		var names := PackedStringArray()
		for b in state["boons"]:
			names.append(b["display_name"])
		for w in state["weaknesses"]:
			names.append("cursed: " + w["display_name"])
		lines.append("IN THE TRIAL  ·  loot: %s  ·  %s" % [
			WorkPanel.amounts_text(sim.trial_loot()) if not sim.trial_loot().is_empty() else "nothing yet",
			", ".join(names) if not names.is_empty() else "no blessings"])
	_status.text = "\n".join(lines)
	_trial_prompt.text = player.trial.prompt() if player != null and player.trial != null else ""

	if combat != null and combat.sim != null:
		var ds: Dictionary = sim.derived_stats()
		var worn: Dictionary = sim.equipment().get("chest", {})
		_life_bar.max_value = maxf(combat.max_life, 1.0)
		_life_bar.value = combat.life
		var rest := ""
		if combat.sheltered:
			rest = "  ·  resting +%.0f/s" % combat.regen_per_second() if combat.resting() else "  ·  sheltered"
		_life_text.text = "Life %d / %d  ·  armour %d  ·  fire resistance %d%%  ·  wearing %s%s" % [
			ceili(combat.life), ceili(combat.max_life), int(ds.get("armour", 0.0)),
			int(ds.get("fire_resistance_percent", 0.0)), worn.get("display_name", "nothing"), rest]

	if placement != null:
		if placement.build_mode_enabled:
			_build_chip.modulate = UiTheme.FROST
			var refusal := placement.family_refusal()
			_build_chip.text = "B  Building: %s  (%s, %d each  ·  Tab change  ·  Q material%s%s%s)" % [
				placement.selection_label(), placement.material_label(),
				sim.shape(placement.placing_shape()).get("material_cost", 0),
				"  ·  R turn" if placement.rotatable() else "",
				"  ·  G fine" if placement.has_fine_twin() else "",
				"  ·  " + refusal if refusal != "" else ""]
		else:
			_build_chip.modulate = UiTheme.MUTED
			_build_chip.text = "B  build"
