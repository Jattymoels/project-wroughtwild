extends "res://scripts/resource_node.gd"
## Copied-game-only presentation adapter; all work, quantities, body, save and depletion clocks inherited.
var art:Node3D
var stages:Array=[]
func _process(delta:float)->void:
	super._process(delta);sync_state()
func _refresh_wedge_look()->void:
	super._refresh_wedge_look();_refresh_state_look()
func _apply_visual()->void:
	super._apply_visual()
	var pivot:MeshInstance3D=get_node("MeshInstance3D")
	art=Node3D.new();art.name="B3 candidate";pivot.add_child(art)
	if visual==&"boulder":
		pivot.mesh=null;pivot.rotation.y=0.0
		for state in ["boulder-full","boulder-worked","boulder-remnant"]:
			var model:Node3D=load("res://b3/assets/"+state+"-lod0.glb").instantiate();art.add_child(model);stages.append(model);own_materials(model)
	else:
		var model:Node3D=load("res://b3/assets/stone-seam-lod0.glb").instantiate();art.add_child(model);own_materials(model)
		if _terrain()==null:art.scale=Vector3(.88,1,1)
		reproject()
	sync_state()
func own_materials(model:Node3D)->void:
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for s in mesh.mesh.get_surface_count():
			var mat:StandardMaterial3D=mesh.mesh.surface_get_material(s).duplicate();mat.emission_enabled=true;mat.emission_energy_multiplier=0;mesh.set_surface_override_material(s,mat);_own_materials.append(mat)
func sync_state()->void:
	if stages.is_empty():return
	var state:=0 if remaining_units>6 else (1 if remaining_units>3 else 2)
	for i in stages.size():stages[i].visible=i==state
func _refresh_state_look()->void:
	super._refresh_state_look();sync_state()
func harvest()->int:
	var result:=super.harvest();sync_state();return result
func refresh_surface()->void:
	super.refresh_surface()
	if art!=null:reproject()
func reproject()->void:
	var terrain:=_terrain()
	if visual!=&"seam" or terrain==null or not terrain.faceted_surface or art==null:return
	# Conform each original triangle independently; holes/steep discontinuities remove unsupported triangles.
	# The original GroundedSeam and its picking collider are retained, never replaced by dressing.
	var along_x:=_visual_seed()%2==0
	var basis:=Basis.IDENTITY if along_x else Basis(Vector3.UP,PI*.5)
	for mesh in art.find_children("*","MeshInstance3D",true,false):
		if not mesh.has_meta("b3_source_mesh"):mesh.set_meta("b3_source_mesh",mesh.mesh);mesh.set_meta("b3_source_transform",mesh.transform)
		var source:Mesh=mesh.get_meta("b3_source_mesh");var result:=ArrayMesh.new()
		var source_transform:Transform3D=mesh.get_meta("b3_source_transform")
		for s in source.get_surface_count():
			var arrays:=source.surface_get_arrays(s);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX];var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var emitted:=0
			for t in range(0,indices.size(),3):
				var points:Array[Vector3]=[];var valid:=true
				for k in 3:
					var p:Vector3=basis*(source_transform*vertices[indices[t+k]])
					var y:=terrain.rendered_height(position.x+p.x,position.z+p.z,position.y,1.25)
					if not is_finite(y):valid=false
					points.append(Vector3(p.x,y-position.y+p.y-.11,p.z))
				if not valid:continue
				for sample in [(points[0]+points[1]+points[2])/3.0,(points[0]+points[1])*.5,(points[1]+points[2])*.5,(points[2]+points[0])*.5]:
					if not is_finite(terrain.rendered_height(position.x+sample.x,position.z+sample.z,position.y,1.25)):valid=false
				if not valid:continue
				if maxf(points[0].y,maxf(points[1].y,points[2].y))-minf(points[0].y,minf(points[1].y,points[2].y))>.5:continue
				for k in 3:st.set_uv(uv[indices[t+k]]);st.add_vertex(points[k]);emitted+=1
			if emitted>0:st.generate_normals();st.set_material(source.surface_get_material(s));st.commit(result)
		mesh.transform=Transform3D.IDENTITY;mesh.mesh=result;mesh.visible=result.get_surface_count()>0
