class_name UiTheme
## The interface's palette tokens (docs/art/art-direction.md master palette)
## and the one Theme every HUD element and panel shares, built in code so
## the look stays reviewable text (docs/systems/interface.md).

const INK := Color("1A1714")          # panel ground
const ASH := Color("342E2E")          # cards, slots
const ASH_LIGHT := Color("4A4040")    # hover
const PARCHMENT := Color("F2E6CC")    # primary text
const MUTED := Color("B8AC98")        # secondary text, borders
const GRASS_LIGHT := Color("8CBC56")  # ready / affordable / positive
const EMBER := Color("EC6E1E")        # danger, warnings
const CINDER := Color("C72E1A")       # missing / cannot
const FROST := Color("8CD2F0")        # cold, information
const IRON_RUST := Color("C4742C")    # currency, crafting glow
const SUN_WARM := Color("FFF5E0")     # highlights
const BARK := Color("5C4026")
const STONE := Color("74747A")

## Swatch colour per material family or item, so the pack reads at a glance.
const FAMILY_COLOURS := {
	"wood": BARK,
	"stone": STONE,
	"iron_ore": IRON_RUST,
	"iron_ingot": MUTED,
	"iron_fittings": MUTED,
	"charcoal": ASH_LIGHT,
	"workbench_kit": FROST,
	"forge_kit": FROST,
	"iron_chest_armour": SUN_WARM,
	"ember_catalyst": EMBER,
	"trade_currency": IRON_RUST,
}

static var _theme: Theme


static func theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func family_colour(id: String) -> Color:
	if FAMILY_COLOURS.has(id):
		return FAMILY_COLOURS[id]
	if id.ends_with("_kit"):
		return FROST
	if id.contains("catalyst"):
		return EMBER
	if id.contains("currency"):
		return IRON_RUST
	return MUTED


static func flat(bg: Color, border: Color = Color(0, 0, 0, 0), radius := 6, border_width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width if border.a > 0.0 else 0)
	style.border_color = border
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


## Card style for a work-panel row: bright edge when its action is available.
static func card(enabled: bool) -> StyleBoxFlat:
	return flat(Color(ASH, 0.75), Color(GRASS_LIGHT, 0.55) if enabled else Color(MUTED, 0.2), 5)


static func _build() -> Theme:
	var t := Theme.new()
	t.set_stylebox("panel", "PanelContainer", flat(Color(INK, 0.92), Color(MUTED, 0.35), 8))

	t.set_stylebox("normal", "Button", flat(ASH, Color(MUTED, 0.5), 4))
	t.set_stylebox("hover", "Button", flat(ASH_LIGHT, Color(PARCHMENT, 0.6), 4))
	t.set_stylebox("pressed", "Button", flat(Color(IRON_RUST, 0.85), Color(SUN_WARM, 0.8), 4))
	t.set_stylebox("disabled", "Button", flat(Color(ASH, 0.45), Color(MUTED, 0.15), 4))
	t.set_stylebox("focus", "Button", flat(Color(0, 0, 0, 0), Color(FROST, 0.6), 4))
	t.set_color("font_color", "Button", PARCHMENT)
	t.set_color("font_hover_color", "Button", SUN_WARM)
	t.set_color("font_pressed_color", "Button", SUN_WARM)
	t.set_color("font_disabled_color", "Button", Color(MUTED, 0.5))

	t.set_color("font_color", "Label", PARCHMENT)
	t.set_color("default_color", "RichTextLabel", PARCHMENT)
	t.set_stylebox("normal", "RichTextLabel", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))

	t.set_stylebox("background", "ProgressBar", flat(Color(INK, 0.8), Color(MUTED, 0.3), 3))
	t.set_stylebox("fill", "ProgressBar", flat(GRASS_LIGHT, Color(0, 0, 0, 0), 3))
	t.set_color("font_color", "ProgressBar", PARCHMENT)

	t.set_stylebox("normal", "CheckButton", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	t.set_color("font_color", "CheckButton", PARCHMENT)
	t.set_color("font_hover_color", "CheckButton", SUN_WARM)
	t.set_color("font_pressed_color", "CheckButton", PARCHMENT)
	return t


## HUD controls must never sit between the captured cursor and the world.
static func ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		ignore_mouse(child)
