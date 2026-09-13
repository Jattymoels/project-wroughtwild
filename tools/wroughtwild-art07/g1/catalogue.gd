extends "res://tests/home_workshop_review.gd"
## Separate labelled native catalogue case. Explicit inspection stock/reward;
## actual payment and occupancy. This stock never enters the paid-route save.
var rows:Array=[]
var output:=""
func _run() -> void:
	get_window().size=Vector2i(1440,900)
	output="res://../evidence/catalogue-"+RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/construction.json"))
	check(not sim.shape_unlocked("roof_wedge"),"ordinary roof gate exists before inspection reward")
	sim.record_world_effect("stonecut_blocks")
	for family in sim.build_material_ids():sim.add_material(String(sim.build_material(family).source),4000)
	var build:=player.placement
	var count:=0
	for fi in sim.build_material_ids().size():
		var family:String=sim.build_material_ids()[fi]
		var column:=0
		for def:Dictionary in config.shapes:
			var id:String=def.id
			if not sim.shape_allows_family(id,family):
				var held:=sim.export_json()
				check(not sim.pay_placement(id,family) and sim.export_json()==held,"illegal family refuses without spending: "+id+" / "+family)
				continue
			var kind:String="volume" if def.element=="block" else "face" if def.element in ["wall","floor"] else "edge"
			var axis:=1 if def.element in ["floor","post"] else 2 if kind!="volume" else 0
			var cell:=Vector3i((-5+(column%6)*2)*2,3,(-14+fi*10+(column/6 as int)*2)*2)
			var elem:Dictionary={"kind":kind,"axis":axis,"cell":cell}
			player.position=Vector3(cell)*.5+Vector3(-2,2,-2)
			build.set_build_mode_enabled(true);build.fine_mode=id.begins_with("half_")
			build.selected_material_family=StringName(family)
			build.select_shape(StringName(def.get("fine_of",id)))
			build.preview_element=elem;build.preview_visible=true;build.preview_rotation_step=0
			var source:String=sim.build_material(family).source
			var before:=sim.material_count(source);var owners:=sim.structure_piece_count()
			check(build.try_place_block(),"native placement: "+id+" / "+family+" "+build.preview_reason)
			check(sim.material_count(source)==before-int(def.material_cost) and sim.structure_piece_count()==owners+1,"exact paid owner: "+id+" / "+family)
			var block:=_piece(elem)
			if not check(block!=null,"one physical object: "+id+" / "+family):continue
			check(block._mesh.mesh!=null and block._mesh.mesh.get_surface_count()>0,"actual integrated geometry: "+id+" / "+family)
			var body_count:=0
			for child in block.get_children():
				if child is CollisionShape3D:body_count+=1
			check(body_count==PieceMesh.collision_for(block.form,block.size).size(),"unchanged native collider decomposition: "+id)
			check(not build.try_place_block() and sim.material_count(source)==before-int(def.material_cost),"duplicate retains materials: "+id)
			rows.append({"shape":id,"family":family,"position":str(block.position),"visual_bounds":str(block._mesh.mesh.get_aabb()),"native_size":str(block.size)})
			column+=1;count+=1
	check(count==273,"all 273 current legal shape/material pairs, including chamfers, triangles and octagonal roofs")
	player.placement.set_build_mode_enabled(false);player.hide();player.hud.hide()
	for frame in 3:await get_tree().process_frame
	var camera:=Camera3D.new();add_child(camera);camera.current=true;camera.fov=48
	var layer:=CanvasLayer.new();add_child(layer);var title:=Label.new();layer.add_child(title)
	title.position=Vector2(24,20);title.add_theme_font_size_override("font_size",22)
	if DisplayServer.get_name()!="headless":
		for fi in sim.build_material_ids().size():
			var family:String=sim.build_material_ids()[fi]
			for block in find_children("*","",true,false):
				if block is PlacedBlock:block.visible=String(block.material_family)==family
			# Native trims are siblings of pieces, not children of their body.
			for edge:Dictionary in sim.structure_trim_edges():
				var cell:Vector3i=edge.cell
				var key:="%d_%d_%d"%[cell.x,cell.y,cell.z]
				if build._trims.has(key):build._trims[key].visible=String(edge.get("family",""))==family
			camera.position=Vector3(8,11,-27+fi*10);camera.look_at(Vector3(0,1.5,-11+fi*10))
			title.text="ART-07G1 / "+RenderingServer.get_current_rendering_method()+" / "+family.to_upper()+"\nAll legal native forms / inspection stock / raised to expose undersides"
			for frame in 6:await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(output+"/"+family+".png")
	FileAccess.open(output+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"pairs":rows,"scope":"Inspection stock and existing roof reward; native catalogue/payment/occupancy. Separate from no-grants paid route."},"  "))
	print("G1_CATALOGUE ",checks," checks, ",failures," failures; ",count," legal pairs")
	get_tree().quit(1 if failures else 0)
