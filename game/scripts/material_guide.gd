class_name MaterialGuide
extends RefCounted
## INT-01/INT-02A: bounded source/work notes and native rare-find descriptions.
## Recipes, consumers, building compatibility and fuel stay read-only views.
const EARLY := ["wood", "fieldstone", "timber_wedge", "split_stone", "stone",
	"iron_ore", "iron_ingot", "charcoal", "timber_frame", "workbench_kit",
	"mason_yard_kit", "forge_kit"]
const SOURCES := {
	"wood": ["Ordinary timber trees.", "Work the trunk with E, then collect the freed drop. Recipes naming wood need this wood, not pine or other timber species."],
	"fieldstone": ["Loose field boulders.", "Work the boulder with E and collect the freed pieces. This is rough stone, not dressed building stone."],
	"split_stone": ["Stone seams or cracked ground stone.", "For a seam, set a timber wedge with E, then drive it with E; compatible impact can speed the work. Collect the freed drop."],
	"iron_ore": ["Exposed iron deposits.", "Work the deposit with E, then collect its ore. Iron needs no heat before gathering."]
}

static func producer(sim: WroughtwildSim, id: String) -> String:
	var first := ""
	for recipe_id in sim.recipe_ids():
		var row: Dictionary = sim.recipe(recipe_id)
		if not row.get("outputs", {}).has(id): continue
		# Prefer the existing hand recipe when both hand and bulk station
		# variants exist. Table order must not imply an extra bench gate.
		if bool(row.get("hand_craftable",false)): return String(recipe_id)
		if first == "": first = String(recipe_id)
	return first

static func describe(sim: WroughtwildSim, id: String) -> Dictionary:
	if sim == null: return {}
	var rare: Dictionary = {}
	if not EARLY.has(id):
		for entry: Dictionary in sim.rare_resource_guide():
			if String(entry.id)==id:
				rare=entry
				break
		if rare.is_empty(): return {}
	var result := {"source":"", "work":"", "use":"", "recipe":producer(sim,id), "uses":[], "shape":""}
	if not rare.is_empty():
		result.source = "%s · %s · finite world find." % [rare.display_name,", ".join(rare.properties)]
		result.work = " → ".join(rare.harvest_stages)+". Use E to work it, then collect the freed component."
		result.use = String(rare.use_preview)
	elif SOURCES.has(id):
		result.source = SOURCES[id][0]
		result.work = SOURCES[id][1]
	elif result.recipe != "":
		var row: Dictionary = sim.recipe(result.recipe)
		var station_id := String(row.get("station", ""))
		var where := "by hand (C)" if station_id == "" else "at the " + String(sim.station(station_id).get("display_name", Hud.pretty(station_id)))
		result.source = "%s · %s." % [row.get("display_name",Hud.pretty(id)),where]
		result.work = "View the recipe for its current ingredients and requirements. Stored stock must be taken into your pack."
	var uses := PackedStringArray()
	for recipe_id in sim.recipe_ids():
		var row: Dictionary = sim.recipe(recipe_id)
		if row.get("inputs", {}).has(id):
			result.uses.append(String(recipe_id))
			# Three examples keep the default explanation short; all actual
			# consumers remain in `uses` for deliberate navigation.
			if uses.size() < 3: uses.append(String(row.get("display_name",recipe_id)))
	if result.use.is_empty() and not uses.is_empty(): result.use = "Used for " + ", ".join(uses) + "."
	if id == "timber_wedge":
		# Consumable resource work is not a crafting recipe consumer.
		result.use = "Set it in a stone seam with E, then drive it with E or a compatible impact."
	for family_id in sim.build_material_ids():
		var family: Dictionary = sim.build_material(family_id)
		if String(family.get("source","")) != id: continue
		var forms := PackedStringArray()
		for shape in sim.shape_ids():
			if sim.shape_allows_family(shape,family_id) and forms.size() < 3:
				forms.append(String(sim.shape(shape).get("display_name",shape)))
		if not forms.is_empty(): result.use = "Build with it: " + ", ".join(forms) + ". " + result.use
	var station := sim.kit_station(id)
	if station != "":
		result.shape = id
		result.use = "Place the kit with B → Tab → LMB, then use E at the station."
	if sim.fuels().has(id):
		result.use += " Fuel: %d heat per unit; recipe ingredients are reserved first." % int(sim.fuels()[id])
	return result
