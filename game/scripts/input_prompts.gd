class_name InputPrompts
extends RefCounted
## Read the same live map that dispatches input. Tokens are explicit, never a
## search/replace of ordinary prose (E is also an element and compass bearing).
static func key(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty(): return "Unbound"
	var event: InputEvent = events[0]
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if event.physical_keycode and DisplayServer.get_name() != "headless":
			code = DisplayServer.keyboard_get_keycode_from_physical(code)
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		return {1:"LMB", 2:"RMB", 3:"MMB", 8:"Mouse 4", 9:"Mouse 5"}.get(event.button_index, event.as_text())
	return event.as_text()

static func text(template: String) -> String:
	var result := template
	var start := result.find("{")
	while start >= 0:
		var end := result.find("}", start)
		if end < 0: break
		var action := result.substr(start + 1, end - start - 1)
		if InputMap.has_action(action):
			result = result.substr(0, start) + key(action) + result.substr(end + 1)
			start = result.find("{", start + 1)
		else:
			start = result.find("{", end + 1)
	return result

static func bind(control: Control, template: String) -> void:
	control.set_meta("input_prompt", template)
	control.set("text", text(template))

static func formatted(template: String, arguments: Variant) -> String:
	# A keyboard-layout label can itself contain a percent sign. Resolve key
	# names after formatting data, so a binding cannot become a format directive.
	return text(template % arguments)

static func refresh_tree(root: Node) -> void:
	if root.has_meta("input_prompt"):
		root.set("text", text(root.get_meta("input_prompt")))
	for child in root.get_children(): refresh_tree(child)
