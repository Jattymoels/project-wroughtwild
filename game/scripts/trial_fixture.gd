class_name TrialFixture
extends StaticBody3D
## A physical route seal, shrine, lift, secret catch or furnace conduit.
## Eligibility/reward remains in TrialSession through the controller.
var fixture_kind := "route"
var stage_index := -1
var choice_index := -1
var title := ""
var detail := ""
var available := false
var claimed := false
var label: Label3D
var glow: MeshInstance3D
var entry_point := Vector3.ZERO
var payload: Dictionary = {}

func trial_label() -> String:
	var name := _single_line(title)
	if fixture_kind == "boundary" and bool(payload.get("terminal", false)): return name
	if claimed: return "%s — %s" % [name, finished_label()]
	if not available: return "%s — Sealed" % name
	match fixture_kind:
		"route":
			var preview := reward_label()
			var danger := danger_label()
			if not danger.is_empty(): preview += " · " + danger
			return InputPrompts.formatted("%s — {interact} · Enter · %s", [name, preview])
		"boundary": return InputPrompts.formatted("%s — {interact} · Continue, bank or suspend", name)
		"secret": return InputPrompts.formatted("%s — {interact} · Inspect", name)
		"conduit": return InputPrompts.formatted("%s — {interact} · %s", [name,"Drain active channel" if bool(payload.get("emergency_release",false)) else "Cool ward protection"])
	return InputPrompts.formatted("%s — {interact} · %s", [name, reward_action() if fixture_kind == "reward" else _single_line(detail)])

func finished_label() -> String:
	match fixture_kind:
		"route": return "Chosen"
		"secret": return "Searched"
		"conduit": return "Cooling"
	return "Finished"

func reward_label() -> String:
	var provided := _single_line(String(payload.get("reward_label", "")))
	if not provided.is_empty(): return provided
	return {"boon_offer":"Blessing", "weakness_offer":"Bargain", "materials":"Material haul", "equipment":"Equipment cache", "catalyst":"Ember Catalyst", "completion":"Boss reward"}.get(String(payload.get("reward", "")), "Encounter")

func reward_action() -> String:
	return {"boon_offer":"Choose a blessing", "weakness_offer":"Review the bargain", "materials":"Claim materials", "equipment":"Claim equipment", "catalyst":"Claim catalyst", "completion":"Claim boss spoils"}.get(String(payload.get("reward_type", "")), _single_line(detail))

func danger_label() -> String:
	var provided := _single_line(String(payload.get("danger_summary", "")))
	if not provided.is_empty(): return provided
	var count: int = payload.get("encounter", []).size()
	return "%d foe%s" % [count, "" if count == 1 else "s"] if count > 0 else ""

func world_lines() -> PackedStringArray:
	var lines := PackedStringArray([_single_line(title)])
	if claimed:
		lines.append(finished_label())
	elif not available:
		lines.append("Sealed")
	elif fixture_kind == "route":
		lines.append(reward_label())
		var danger := danger_label()
		if not danger.is_empty(): lines.append(danger)
	elif fixture_kind == "boundary":
		lines.append("Continue · Bank · Suspend")
	elif fixture_kind == "secret":
		lines.append("Inspect the catch")
	elif fixture_kind == "conduit":
		lines.append("Drain active channel" if bool(payload.get("emergency_release",false)) else "Cool ward protection")
	elif fixture_kind == "reward":
		lines.append(reward_action())
	else:
		lines.append(_single_line(detail))
	return lines

func _single_line(text: String) -> String:
	return " ".join(text.replace("\n", " ").replace("\r", " ").split(" ", false))

func refresh() -> void:
	TrialFixtureArt.refresh(self)

func interact(player: WroughtwildPlayer) -> void:
	if player.trial != null:
		player.trial.interact_fixture(self)
