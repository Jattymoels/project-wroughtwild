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
	# Native GroundedSeam and its collider already follow current terrain.
	# Hide the decorative overlay until its complete replacement is ready.
	art.visible=false
	_projection={"meshes":art.find_children("*","MeshInstance3D",true,false),"mesh_index":0,
		"surface":0,"triangle":0,"samples":{},"results":[],"result":null,"st":null,
		"basis":Basis.IDENTITY if _visual_seed()%2==0 else Basis(Vector3.UP,PI*.5)}
	if bool(get_meta("stream_projection",false)) and terrain.resource_stream!=null:
		terrain.resource_stream.queue_projection(self)
	else:
		# Initial world preparation and explicit restore return complete art.
		step_projection(0)

var _projection:Dictionary={}

## Shares ResourceStream's existing elapsed work budget. A zero deadline is
## explicit synchronous preparation; ordinary arrivals never request it.
func step_projection(deadline_usec:int)->bool:
	if _projection.is_empty():return true
	var job:=_projection
	var terrain:=_terrain()
	if terrain==null or art==null:
		_projection.clear()
		return true
	while int(job.mesh_index)<job.meshes.size():
		if deadline_usec>0 and Time.get_ticks_usec()>=deadline_usec:return false
		var mesh:MeshInstance3D=job.meshes[job.mesh_index]
		if not mesh.has_meta("b3_source_mesh"):
			mesh.set_meta("b3_source_mesh",mesh.mesh)
			mesh.set_meta("b3_source_transform",mesh.transform)
		var source:Mesh=mesh.get_meta("b3_source_mesh")
		var source_transform:Transform3D=mesh.get_meta("b3_source_transform")
		if job.result==null:job.result=ArrayMesh.new()
		if int(job.surface)>=source.get_surface_count():
			job.results.append(job.result)
			job.result=null
			job.mesh_index+=1
			job.surface=0
			continue
		if job.st==null:
			var arrays:=source.surface_get_arrays(job.surface)
			job.vertices=arrays[Mesh.ARRAY_VERTEX]
			job.indices=arrays[Mesh.ARRAY_INDEX]
			job.uv=arrays[Mesh.ARRAY_TEX_UV]
			job.st=SurfaceTool.new()
			job.st.begin(Mesh.PRIMITIVE_TRIANGLES)
			job.emitted=0
			job.triangle=0
		var st:SurfaceTool=job.st
		var vertices:PackedVector3Array=job.vertices
		var indices:PackedInt32Array=job.indices
		var uv:PackedVector2Array=job.uv
		while int(job.triangle)<indices.size():
			if deadline_usec>0 and Time.get_ticks_usec()>=deadline_usec:return false
			var t:int=job.triangle
			job.triangle+=3
			var points:Array[Vector3]=[]
			var valid:=true
			for k in 3:
				var p:Vector3=job.basis*(source_transform*vertices[indices[t+k]])
				var y:=_r2_height(terrain,job.samples,position.x+p.x,position.z+p.z)
				if not is_finite(y):valid=false
				points.append(Vector3(p.x,y-position.y+p.y-.11,p.z))
			if not valid:continue
			for sample in [(points[0]+points[1]+points[2])/3.0,(points[0]+points[1])*.5,(points[1]+points[2])*.5,(points[2]+points[0])*.5]:
				if not is_finite(_r2_height(terrain,job.samples,position.x+sample.x,position.z+sample.z)):valid=false
			if not valid:continue
			if maxf(points[0].y,maxf(points[1].y,points[2].y))-minf(points[0].y,minf(points[1].y,points[2].y))>.5:continue
			for k in 3:
				st.set_uv(uv[indices[t+k]])
				st.add_vertex(points[k])
				job.emitted+=1
		if int(job.emitted)>0:
			st.generate_normals()
			st.set_material(source.surface_get_material(job.surface))
			st.commit(job.result)
		job.st=null
		job.surface+=1
	# Publish all surfaces together. A refresh replaces the job, so a dig or
	# chunk arrival cannot publish an obsolete partly conformed overlay.
	for i in job.meshes.size():
		var mesh:MeshInstance3D=job.meshes[i]
		mesh.transform=Transform3D.IDENTITY
		mesh.mesh=job.results[i]
		mesh.visible=mesh.mesh.get_surface_count()>0
	art.visible=true
	_projection.clear()
	return true

func _r2_height(terrain:Terrain, samples:Dictionary, x:float, z:float)->float:
	# Float64 array keys preserve the original scalar query coordinates exactly.
	# Vector2 would round them to float32 and could conflate nearby edge samples.
	var key:Array[float]=[x,z]
	if not samples.has(key):samples[key]=terrain.rendered_height(x,z,position.y,1.25)
	return samples[key]
