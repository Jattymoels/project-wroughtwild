class_name Hud
extends CanvasLayer
## The always-on layer (docs/systems/interface.md): life bar with defences,
## the action bar with cooldown sweeps, the build chip, a right-aligned
## holdings strip, notices, the pickup ticker, crosshair and target line,
## and the H help overlay. Everything shown is read from the sim or from
## engine-owned timers. The always-on HUD ignores the mouse; the H overlay's
## audio controls receive it only while that overlay is visible.

const NOTICE_SECONDS := 3.0
const REFRESH_SECONDS := 0.1
const GATHER = preload("res://art/gathering_look.tres")
const HELP_TEXT := """{move_forward}/{move_left}/{move_back}/{move_right} move  ·  mouse look  ·  {jump} jump  ·  {dash} dash (movement only)
{interact} interact: harvest, work at a station, read the board, open the gate
{primary_action} harvest  ·  hold {primary_action} on the ground to dig it out (stone yields split stone)
{primary_action} places in build mode  ·  {hand_craft} craft by hand  ·  {toggle_inventory} pack
{toggle_build_mode} build mode  ·  {cycle_shape} visual shape picker  ·  {remove_block} remove  ·  {rotate_preview} turn corners, roofs or a door's hinge
{remove_block} outside build mode blows a carried shrieker's horn
Pieces snap to the nearest free cell, face or edge you look at: walls join walls, posts stack
{toggle_fine} fine pieces: half-scale twins of the cube, wall, post, beam and slab  ·  {interact} opens a door
{cycle_material} building material: timber, stone or iron from your pack - doors need joinery, cut stone needs stone, girders need iron
{skill_slot_1}/{skill_slot_2}/{skill_slot_3}/{skill_slot_4} skill bar (assign skills in the pack screen; {dash} also dashes)
Mobs drop skill pages that teach new skills, and rolled gear that scales them
{spike_mod_1}/{spike_mod_2}/{spike_mod_3} spike mods (debug: force one modifier on)
{toggle_foundry} the Foundry: lay a skill's tablet in a socket and the ingots beside it support that skill
Your class, chosen at the start, sets the plate's rails; the Tyrant's forge opens a further specialisation
{toggle_camera} camera  ·  {toggle_help} this help  ·  Esc close  ·  {save_game} save  ·  {load_game} load"""

var sim: WroughtwildSim
var combat: PlayerCombat
var placement: GridPlacement
var player: WroughtwildPlayer
var damage_compass: DamageCompass

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
var _help_root: Control
var _help_scroll: ScrollContainer
var _help_body: Label
var _ambience_slider: HSlider
var _ambience_mute: CheckBox
var _ambience_value: Label
var _audio_status: Label
var comfort: ComfortControls
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
var _work_display: VBoxContainer
var _work_meter: ProgressBar
var _work_label: Label
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
	_pickup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pickup_label.modulate = UiTheme.GRASS_LIGHT
	column.add_child(_pickup_label)
	var reminder := Label.new()
	InputPrompts.bind(reminder, "{toggle_help} help / settings  ·  {toggle_inventory} pack")
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
	_life_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	# Fixed anchors keep a work update from shifting the crosshair or target.
	_work_display = VBoxContainer.new()
	_work_display.set_anchors_preset(Control.PRESET_CENTER)
	_work_display.offset_left = -GATHER.meter_width / 2.0
	_work_display.offset_right = GATHER.meter_width / 2.0
	_work_display.offset_top = 72
	_ui.add_child(_work_display)
	_work_meter = ProgressBar.new()
	_work_meter.max_value = 1.0
	_work_meter.step = 0.0
	_work_meter.show_percentage = false
	_work_meter.custom_minimum_size = Vector2(GATHER.meter_width, GATHER.meter_height)
	_work_meter.add_theme_stylebox_override("background", UiTheme.flat(Color("292a25"), Color("54584a"), 2))
	_work_meter.add_theme_stylebox_override("fill", UiTheme.flat(Color("abaf83"), Color.TRANSPARENT, 2))
	_work_display.add_child(_work_meter)
	_work_label = Label.new()
	_work_label.add_theme_font_size_override("font_size", 14)
	_work_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_work_display.add_child(_work_label)
	_work_display.hide()

	# Help overlay (H): the control list, off by default.
	var help_layer := CanvasLayer.new()
	help_layer.layer = 12 # Above work, pack and the initial class chooser.
	add_child(help_layer)
	_help_root = Control.new()
	_help_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_help_root.theme = UiTheme.theme()
	_help_root.visible = false
	help_layer.add_child(_help_root)
	_help = PanelContainer.new()
	_help.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_help.visible = false
	_help_root.add_child(_help)
	var help_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		help_margin.add_theme_constant_override(side, 18)
	_help.add_child(help_margin)
	var help_column := VBoxContainer.new()
	help_column.add_theme_constant_override("separation", 8)
	help_margin.add_child(help_column)
	var help_title := Label.new()
	help_title.text = "Controls & comfort"
	var build_version := String(ProjectSettings.get_setting("application/config/version", ""))
	if not build_version.is_empty():
		help_title.text += " · " + build_version
	help_title.add_theme_font_size_override("font_size", 20)
	help_column.add_child(help_title)
	comfort = ComfortControls.new()
	comfort.preferences = player.preferences
	comfort.hud = self
	help_column.add_child(comfort)
	_help_scroll = comfort.scroll

	# The 1 Sep 2026 bug: any HUD control left at MOUSE_FILTER_STOP swallows
	# mouse look under the captured cursor. Never again, for any of them.
	UiTheme.ignore_mouse(_ui)
	# The optional overlay owns input even outside its card. An underlying
	# pack/class button must not react while sound controls are being adjusted.
	_help_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_help.mouse_filter = Control.MOUSE_FILTER_STOP
	_help_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_help_scroll.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().size_changed.connect(_fit_help)
	# Wrapped text can revise its minimum after its first container layout.
	# Refit that measured result as well as the window-resize event.
	_help.minimum_size_changed.connect(_fit_help.call_deferred)
	_fit_help.call_deferred()

	if combat != null:
		damage_compass = DamageCompass.new()
		damage_compass.player = player
		_ui.add_child(damage_compass)
		combat.hit_landed.connect(_on_hit_landed)
		combat.life_changed.connect(_on_life_changed)
		combat.world_worked.connect(_on_world_worked)
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


## The hitmarker tells the hit's types (D-023 slice 2): white for a plain
## blow, the element's tint for one element, and a doubled mark in the
## blended tint for a two-element hit - a packet without a tell is a stat.
const TYPE_TINTS := {
	"physical": Color(1, 1, 1, 0.9),
	"fire": Color(1.0, 0.6, 0.2, 0.95),
	"cold": Color(0.55, 0.8, 1.0, 0.95),
}


func _on_hit_landed(_total_damage: float, kills: int, types: PackedStringArray = PackedStringArray()) -> void:
	_hitmarker_timer = 0.16
	_hitmarker.text = "×" if types.size() <= 1 else "×".repeat(types.size())
	if kills > 0:
		_hitmarker.modulate = Color(1.0, 0.35, 0.3, 1.0)
		return
	var tint: Color = TYPE_TINTS.get(types[0] if not types.is_empty() else "physical", Color(1, 1, 1, 0.9))
	if types.size() > 1:
		tint = tint.lerp(TYPE_TINTS.get(types[1], tint), 0.5)
	_hitmarker.modulate = tint


func _on_life_changed(life: float, _max_life: float) -> void:
	if _last_life >= 0.0 and life < _last_life:
		_damage_flash_timer = 0.25
	_last_life = life


## "4:05" from seconds.
static func clock_text(seconds: float) -> String:
	var whole := maxi(ceili(seconds), 0)
	return "%d:%02d" % [whole / 60, whole % 60]


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


## A refusal or state line under the crosshair in the dig slot (fire-
## setting: "Stone glows - cold will crack it").
func show_dig_text(text: String) -> void:
	_dig_text = text


## Absorbed pickups accumulate into one line while they keep arriving.
func notify_pickup(family: String, amount: int) -> void:
	_pickup_totals[family] = int(_pickup_totals.get(family, 0)) + amount
	_pickup_timer = PICKUP_SECONDS
	var parts := PackedStringArray()
	for id in _pickup_totals:
		parts.append("+%d %s · carried %d" % [_pickup_totals[id], pretty(id), sim.material_count(id)])
	_pickup_label.text = " · ".join(parts)
	refresh()


func toggle_help() -> void:
	_help.visible = not _help.visible
	_help_root.visible = _help.visible
	if _help.visible:
		comfort.refresh()
		_fit_help.call_deferred()
		if player != null: player._release_mouse()
		for button in comfort.tabs.get_children():
			if not button.disabled:
				button.grab_focus()
				break
	elif player != null:
		comfort.cancel_capture()
		for action in player.preferences.actions: Input.action_release(action)
		Input.action_release("blow_horn")
		player._capture_mouse()


func _build_audio_controls(column: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var label := Label.new()
	label.text = "Ambience"
	row.add_child(label)
	_ambience_slider = HSlider.new()
	_ambience_slider.min_value = 0
	_ambience_slider.max_value = 100
	_ambience_slider.step = 5
	_ambience_slider.custom_minimum_size.x = 180
	_ambience_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ambience_slider.tooltip_text = "Occasional air and rustle. 0% is silent."
	row.add_child(_ambience_slider)
	_ambience_value = Label.new()
	_ambience_value.custom_minimum_size.x = 48
	row.add_child(_ambience_value)
	_ambience_mute = CheckBox.new()
	_ambience_mute.text = "Mute"
	row.add_child(_ambience_mute)
	_audio_status = Label.new()
	_audio_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_audio_status.custom_minimum_size.x = 300
	_audio_status.modulate = UiTheme.MUTED
	column.add_child(_audio_status)
	_ambience_slider.value_changed.connect(_audio_level_changed)
	_ambience_mute.toggled.connect(_audio_mute_changed)
	if player != null and not player.audio_preferences.changed.is_connected(_refresh_audio_controls):
		player.audio_preferences.changed.connect(_refresh_audio_controls)
	_refresh_audio_controls()


func _audio_level_changed(value: float) -> void:
	if player != null: player.audio_preferences.set_ambience(value / 100.0, player.audio_preferences.ambience_muted)


func _audio_mute_changed(muted: bool) -> void:
	if player != null: player.audio_preferences.set_ambience(player.audio_preferences.ambience_level, muted)


func _refresh_audio_controls() -> void:
	if player == null or not is_instance_valid(_ambience_slider): return
	var prefs := player.audio_preferences
	_ambience_slider.set_value_no_signal(prefs.ambience_level * 100.0)
	_ambience_mute.set_pressed_no_signal(prefs.ambience_muted)
	_ambience_value.text = "%d%%" % roundi(prefs.ambience_level * 100.0)
	_audio_status.text = "Occasional air and rustle. Work, footsteps and danger keep their own sound."
	if prefs.last_error != OK:
		_audio_status.text = "Audio preference file unavailable. Changes apply now; check again after restarting."


func _fit_help() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var width := minf(760.0, viewport.x - 24.0)
	_help.custom_minimum_size.x = width
	if is_instance_valid(_help_body): _help_body.custom_minimum_size.x = width - 60.0
	comfort.custom_minimum_size.x = width - 56.0
	comfort.status.custom_minimum_size.x = width - 56.0
	var available := clampf(viewport.y - 260.0, 150.0, 450.0)
	_help_scroll.custom_minimum_size.y = clampf(comfort.body.get_combined_minimum_size().y, 150.0, available)
	_help.size = Vector2(width, 0)
	_help.position = ((viewport - _help.size) * 0.5).floor()


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
	if placement.build_mode_enabled and not placement.palette_open:
		_target_label.text = placement.placement_feedback()

	# Hover highlight: glow the harvestable you are looking at.
	var target: Node = probe["target"] as Node
	var show_work := target is ResourceNode and _dig_text == "" and not placement.build_mode_enabled and combat.life > 0.0 and not help_visible()
	for panel in [player.work_panel, player.inventory_panel, player.foundry_panel, player.class_panel, player.chest_panel]:
		if panel != null and panel.is_open():
			show_work = false
	show_work_view((target as ResourceNode).work_view(sim) if show_work else {})
	if target != _hovered:
		if is_instance_valid(_hovered) and _hovered.has_method("set_highlight"):
			_hovered.set_highlight(false)
		_hovered = target
		if is_instance_valid(_hovered) and _hovered.has_method("set_highlight"):
			_hovered.set_highlight(true)

func show_work_view(view: Dictionary) -> void:
	_work_display.visible = not view.is_empty()
	if view.is_empty():
		return
	_work_meter.value = view.fraction
	_work_meter.modulate = Color.WHITE if view.ready else Color("ba8875")
	_work_label.text = view.text


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
			# The haul (Wave 6 slice 6): a capped family shows its cap.
			var cap: int = sim.carry_cap(id)
			parts.append("%s %d/%d" % [pretty(id), held[id], cap] if cap > 0 else "%s %d" % [pretty(id), held[id]])
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
	var era: Dictionary = sim.era()
	if not era.is_empty():
		lines.append("Era %d of %d: %s" % [era["index"], era.get("count", 1), era["display_name"]])
	# The hour (Wave 6 slice 5): dusk counts down to the night, the night to dawn.
	var day: Dictionary = sim.day()
	if not day.is_empty():
		var phase := String(day.get("phase", "day"))
		var when := ""
		if phase == "dusk":
			when = "  ·  night in %s" % clock_text(float(day.get("seconds_to_night", 0.0)))
		elif phase == "night":
			when = "  ·  dawn in %s" % clock_text(float(day.get("seconds_to_dawn", 0.0)))
		lines.append("Day %d, %s%s" % [int(day.get("index", 1)), phase, when])
	# The curios held (Wave 8 slice 2): each one's reading names its lock.
	for hint in sim.curio_hints():
		lines.append(String(hint))
	# The economy's own milestones (crafts, world effects, eras) forge ingots.
	for id in sim.foundry_notices():
		if String(id).begins_with("manner:"):
			# A manner the world taught (D-023 slice 9): a rail pattern.
			var pattern: Dictionary = sim.foundry_pattern(String(id).trim_prefix("manner:"))
			notify(InputPrompts.formatted("The Foundry: the %ss have taught you %s. It goes in a rail; {toggle_foundry} opens the plate.", [pattern.get("teacher_name", "fallen"), pattern.get("display_name", id)]))
		else:
			notify(InputPrompts.formatted("The Foundry: a %s is yours. {toggle_foundry} opens the plate.", sim.foundry_ingot(id).get("display_name", id)))
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
			rest = "  ·  resting +%.1f/s" % combat.regen_per_second() if combat.resting() else "  ·  sheltered"
		elif combat.verb_text() != "":
			rest = "  ·  " + combat.verb_text()
		elif combat.night_text() != "":
			rest = "  ·  " + combat.night_text()
		elif combat.shelter_text() != "":
			rest = "  ·  " + combat.shelter_text()
		# Cold resistance (D-023 slice 4) shows once something gives it.
		var cold := ""
		if float(ds.get("cold_resistance_percent", 0.0)) > 0.0:
			cold = "  ·  cold resistance %d%%" % int(ds.get("cold_resistance_percent", 0.0))
		_life_text.text = "Life %d / %d  ·  armour %d  ·  fire resistance %d%%%s  ·  wearing %s%s" % [
			ceili(combat.life), ceili(combat.max_life), int(ds.get("armour", 0.0)),
			int(ds.get("fire_resistance_percent", 0.0)), cold, worn.get("display_name", "nothing"), rest]

	if placement != null:
		if placement.build_mode_enabled:
			_build_chip.modulate = UiTheme.FROST
			_build_chip.text = InputPrompts.formatted("%s · %s\n%s\n{cycle_shape} shapes · {cycle_material} material · {remove_block} remove · {toggle_build_mode} finish%s", [
				placement.selection_label(),placement.cost_label(),placement.orientation_label(),
				InputPrompts.text(" · {toggle_fine} half-size") if placement.has_fine_twin() else ""])
		else:
			_build_chip.modulate = UiTheme.MUTED
			InputPrompts.bind(_build_chip, "{toggle_build_mode}  build")


func _on_world_worked(what: String, count: int) -> void:
	if what == "cracked":
		notify("The cold cracks the hot rock (%d)." % count if count > 1 else "The cold cracks the hot rock.")
	elif what == "heated":
		notify("The rock glows.")
