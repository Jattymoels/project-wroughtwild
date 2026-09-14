extends "res://scripts/resource_node.gd"
## C5 copied-game fallback adapter; work, time, stock, collider and saves stay inherited.
## R6 adds material detail on exact native ribbon vertices; fallback source stays retained.
var ribbon_material: ShaderMaterial
var art:Node3D
var models:Dictionary={}
var row:Dictionary
var art_clock:=0.0
var art_paused:=false
var displayed_state:=""
func _refresh_wedge_look()->void:
	super._refresh_wedge_look();_refresh_state_look()
func _apply_visual()->void:
	super._apply_visual()
	if _terrain()!=null and _terrain().faceted_surface:
		var cfg_surface: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://c5/kit.json"))
		var kind := "ember_iron_vein" if visual == &"ember_vein" else String(visual)
		for candidate in cfg_surface.ores:
			if candidate.id == kind: row = candidate
		if not row.is_empty():
			ribbon_material = preload("res://r6/surface.gd").attach(self, row)
			_refresh_state_look()
		return
	var cfg:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://c5/kit.json"))
	for r in cfg.ores:
		if r.id==resource_id:row=r
	if row.is_empty():return # Unrecognized legacy fallback IDs retain their native picture.
	var pivot:MeshInstance3D=get_node("MeshInstance3D");pivot.mesh=null
	art=Node3D.new();art.name="C5 solid source candidate";pivot.add_child(art)
	for units in range(int(row.units),0,-2):
		for crack in ([false] if resource_id=="iron_vein" else [false,true]):
			var key:="u%d-%s"%[units,"cracked" if crack else "cold"]
			var model:Node3D=load("res://c5/assets/"+resource_id+"-"+key+"-lod0.gltf").instantiate();art.add_child(model)
			var mats:Array=preload("res://c5/materials.gd").apply(model,row);_own_materials.append_array(mats);models[key]=model
	sync_state()
func _process(delta:float)->void:
	super._process(delta)
	if not art_paused:art_clock+=delta
	for mat in _own_materials:
		if mat is ShaderMaterial:mat.set_shader_parameter("clock_seconds",art_clock)
func refresh_surface()->void:
	super.refresh_surface()
	if ribbon_material != null:
		var mesh: MeshInstance3D = get_node("MeshInstance3D")
		mesh.material_override = ribbon_material
		if remaining_units <= 0: mesh.visible = false
func sync_state()->void:
	if ribbon_material != null:
		ribbon_material.set_shader_parameter("remaining_fraction", clampf(float(remaining_units)/float(row.units), 0.0, 1.0))
		ribbon_material.set_shader_parameter("native_cracked", cracked)
		ribbon_material.set_shader_parameter("heat_active", hot_level > 0)
		displayed_state = "surface-u%d-%s" % [remaining_units, "cracked" if cracked else "cold"]
		# Native depletion scales its retiring node; hide the surface immediately so
		# that animation cannot detach a ribbon from its retained slope.
		if remaining_units <= 0: get_node("MeshInstance3D").visible = false
	if art==null:return
	var key:="u%d-%s"%[remaining_units,"cracked" if cracked and resource_id!="iron_vein" else "cold"]
	for k in models:models[k].visible=k==key
	displayed_state=key
	for mat in _own_materials:
		if mat is ShaderMaterial:mat.set_shader_parameter("heat_active",hot_level>0)
func _refresh_state_look()->void:
	super._refresh_state_look();sync_state()
func harvest()->int:
	var amount:=super.harvest();sync_state();return amount
