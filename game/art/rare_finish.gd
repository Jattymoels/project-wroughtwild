class_name RareFinish
extends Resource
## Contained discovery light and close natural grain. No stock, harvest, timing
## or collision authority: callers supply the current native/ResourceNode state.

@export_group("Close detail budget")
## Specimens retain their ordinary distance; added seams and grit retire sooner.
@export var detail_distance_m := 48.0
@export var distance_margin_m := 8.0
## Thin embedded channels remain readable by day without becoming glowing hosts.
@export var filament_radius_m := 0.01
@export var branch_radius_fraction := 0.48
@export var core_emission := 2.4
## Short samples follow real mesh planes; a slight inset makes seams embedded
## instead of free-standing wires. Missed surfaces become deliberate dark gaps.
@export var seam_sample_m := 0.045
@export var seam_inset_m := 0.003
## Small material motion stays within the existing rare-resource body envelope.
@export var drift_m := 0.008
@export var drift_rate := 0.6
## Smooth close grain breaks up wood and mineral planes without noisy pixel dots.
@export var grain_scale := 22.0
@export var grain_strength := 0.3
## Remove only the near buttress across the hollow's lower mouth. The authored
## back and shoulders remain; a player approaching the clue path can see inside.
@export var lantern_cavity_half_width_m := 0.7
@export var lantern_cavity_height_m := 1.25
@export var lantern_cavity_front_m := 0.05
@export var lantern_cavity_raggedness_m := 0.18

@export_group("Material identities")
## Amber paper stays warm; the other embedded cores share the impact's pale light.
@export var core_colours := {
	"lanternheart":Color("ffe4ad"), "thrumroot":Color("cce4df"),
	"stormglass":Color("c7edff"), "pullstone":Color("b5d9e9"),
	"ventlung":Color("dcebe6"), "pressure":Color("c1e8f4")}
## Host colours distinguish weathered fibre, milky glass, ferrous stone and cases.
@export var host_colours := {
	"lanternheart":Color("c8ad79"), "thrumroot":Color("81664b"),
	"stormglass":Color("8badae"), "pullstone":Color("78858a"),
	"ventlung":Color("99978a"), "pressure":Color("737e7f"), "lantern_shell":Color("685440"), "vent_case":Color("626d69")}
## Different grain directions/roughness preserve the resource's physical job.
@export var host_modes := {"lanternheart":4,"thrumroot":0,"stormglass":1,"pullstone":2,"ventlung":3,"pressure":3}
@export var roughness := {"lanternheart":0.86,"thrumroot":0.94,"stormglass":0.44,"pullstone":0.8,"ventlung":0.82,"pressure":0.9}

@export_group("Specimen seam layouts")
## Authored local paths lie inside the unchanged resource envelopes. Branches
## follow the host instead of outlining its silhouette or drawing an icon.
@export var paths: Dictionary = {
	"lanternheart":[PackedVector3Array([Vector3(-.11,.2,.13),Vector3(-.06,.34,.18),Vector3(.035,.44,.16),Vector3(.02,.6,.06)]),PackedVector3Array([Vector3(.035,.44,.16),Vector3(.13,.5,.06),Vector3(.08,.6,-.03)])],
	"thrumroot":[PackedVector3Array([Vector3(-.89,.55,.23),Vector3(-.62,.66,.17),Vector3(-.38,.6,.24),Vector3(-.12,.67,.19),Vector3(.13,.57,.25),Vector3(.4,.65,.18),Vector3(.72,.53,.22)]),PackedVector3Array([Vector3(-.12,.67,.19),Vector3(-.08,.5,.27),Vector3(.13,.37,.22)]),PackedVector3Array([Vector3(.4,.65,.18),Vector3(.52,.5,.27),Vector3(.72,.38,.17)])],
	"stormglass":[PackedVector3Array([Vector3(-.26,.12,.11),Vector3(-.18,.3,.19),Vector3(-.09,.61,.11),Vector3(-.2,.95,.18)]),PackedVector3Array([Vector3(.02,.13,.12),Vector3(.1,.33,.2),Vector3(.17,.66,.105),Vector3(.065,.98,.19)]),PackedVector3Array([Vector3(.3,.13,.12),Vector3(.39,.31,.19),Vector3(.45,.62,.11),Vector3(.34,.96,.18)]),PackedVector3Array([Vector3(-.09,.61,.11),Vector3(.055,.72,.11),Vector3(.17,.66,.105)])],
	"pullstone":[PackedVector3Array([Vector3(-.48,.23,.43),Vector3(-.28,.36,.45),Vector3(-.2,.52,.43),Vector3(.015,.61,.37),Vector3(.12,.8,.26),Vector3(.39,.92,.16)]),PackedVector3Array([Vector3(-.2,.52,.43),Vector3(-.43,.58,.3),Vector3(-.52,.73,.16)]),PackedVector3Array([Vector3(.015,.61,.37),Vector3(.24,.51,.28),Vector3(.46,.56,.18)])],
	"ventlung":[PackedVector3Array([Vector3(-.11,.14,.26),Vector3(-.2,.36,.45),Vector3(-.15,.63,.4),Vector3(-.035,.88,.26),Vector3(0,1.06,.1)]),PackedVector3Array([Vector3(.15,.15,.23),Vector3(.27,.39,.4),Vector3(.22,.66,.35),Vector3(.055,.91,.24)]),PackedVector3Array([Vector3(-.15,.63,.4),Vector3(.05,.69,.41),Vector3(.22,.66,.35)])],
	"pressure":[PackedVector3Array([Vector3(-.27,.37,.43),Vector3(-.19,.48,.46),Vector3(-.06,.53,.43),Vector3(.025,.7,.24),Vector3(0,.91,.06)]),PackedVector3Array([Vector3(-.06,.53,.43),Vector3(.13,.49,.43),Vector3(.29,.63,.33)])]}

## Irregular host fragments expose broken bedding/bark within the existing body.
@export var fragments: Dictionary = {
	"lanternheart":[[Vector3(-.17,.12,-.09),Vector3(.22,.18,.2)],[Vector3(.16,.1,-.06),Vector3(.17,.12,.25)]],
	"thrumroot":[[Vector3(-.85,.15,-.05),Vector3(.42,.23,.5)],[Vector3(.66,.16,-.08),Vector3(.52,.22,.44)]],
	"stormglass":[[Vector3(-.51,.1,-.09),Vector3(.5,.21,.49)],[Vector3(.58,.11,-.05),Vector3(.47,.22,.52)]],
	"pullstone":[[Vector3(-.55,.12,-.11),Vector3(.55,.23,.54)],[Vector3(.42,.11,-.11),Vector3(.37,.22,.51)]],
	"ventlung":[[Vector3(-.36,.13,-.19),Vector3(.38,.26,.43)],[Vector3(.32,.15,-.17),Vector3(.4,.3,.42)]]}

## A few locally suspended iron grains convey attraction without a particle node.
@export var grit_count := 11
@export var grit_radius_m := 0.025
## Small exposed luminous interiors are bounded by paper folds, tube mouths or
## mineral seams. They give a find a bright centre without lighting its host.
@export var core_windows: Dictionary = {
	"lanternheart":[[Vector3(0,.43,0),Vector3(.36,.3,.36)]],
	"stormglass":[[Vector3(-.26,1.017,.12),Vector3(.11,.025,.11)],[Vector3(.02,1.018,.12),Vector3(.11,.025,.11)],[Vector3(.3,1.017,.12),Vector3(.11,.025,.11)]],
	"pullstone":[[Vector3(-.18,.53,.429),Vector3(.06,.085,.028)]],
	"ventlung":[[Vector3(0,.83,.299),Vector3(.11,.055,.055)]],
	"pressure":[[Vector3(.02,.695,.25),Vector3(.11,.13,.055)]]}
var _meshes: Dictionary = {}

func surface(kind: String) -> ShaderMaterial:
	var result:=ShaderMaterial.new()
	result.shader=preload("res://art/rare_finish.gdshader")
	result.set_shader_parameter("host_colour",host_colours.get(kind,Color.GRAY))
	result.set_shader_parameter("host_mode",int(host_modes.get(kind,0)))
	result.set_shader_parameter("host_roughness",float(roughness.get(kind,.9)))
	result.set_shader_parameter("grain_scale",grain_scale)
	result.set_shader_parameter("grain_strength",grain_strength)
	result.set_shader_parameter("movement",drift_m*.5 if kind in ["lanternheart","ventlung"] else 0.0)
	result.set_shader_parameter("movement_rate",drift_rate)
	if kind=="lantern_shell":
		result.set_shader_parameter("cavity_open",true)
		result.set_shader_parameter("cavity_half_width",lantern_cavity_half_width_m)
		result.set_shader_parameter("cavity_height",lantern_cavity_height_m)
		result.set_shader_parameter("cavity_front_start",lantern_cavity_front_m)
		result.set_shader_parameter("cavity_raggedness",lantern_cavity_raggedness_m)
	return result

func build(kind: String) -> Node3D:
	var root:=Node3D.new()
	root.name="RareFinish"
	root.set_meta("kind",kind)
	if not paths.has(kind):return root
	if not _meshes.has(kind):_meshes[kind]=_build_meshes(kind)
	var meshes: Dictionary=_meshes[kind]
	for role: String in meshes:
		var instance:=MeshInstance3D.new()
		instance.name=role
		instance.mesh=meshes[role]
		instance.visibility_range_end=detail_distance_m
		instance.visibility_range_end_margin=distance_margin_m
		if role=="HostFragments":
			instance.material_override=surface("thrumroot" if kind in ["lanternheart","thrumroot"] else "pullstone")
		else:
			var material:=ShaderMaterial.new()
			material.shader=preload("res://art/rare_filament.gdshader")
			material.set_shader_parameter("core_colour",core_colours.get(kind,Color.WHITE))
			material.set_shader_parameter("emission_energy",core_emission*(.3 if role=="SuspendedGrit" else 1.0))
			material.set_shader_parameter("movement_m",drift_m if role=="SuspendedGrit" else 0.0)
			material.set_shader_parameter("movement_rate",drift_rate)
			instance.material_override=material
			instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(instance)
	set_state(root,1,0,false)
	return root

func set_state(root: Node3D, stock_fraction: float, work_fraction: float, highlighted: bool) -> void:
	var stock:=clampf(stock_fraction,0,1)
	var work:=clampf(work_fraction,0,1)
	root.set_meta("stock_fraction",stock)
	root.set_meta("work_fraction",work)
	for child in root.get_children():
		if not child is MeshInstance3D:continue
		if child.name==&"HostFragments":continue
		child.visible=stock>0
		var material:=child.material_override as ShaderMaterial
		material.set_shader_parameter("stock_fraction",stock)
		material.set_shader_parameter("work_fraction",work)
		material.set_shader_parameter("hover_amount",1.0 if highlighted else 0.0)

func _build_meshes(kind: String) -> Dictionary:
	var result: Dictionary={}
	var seam:=ArtGeometry.begin()
	var path_index:=0
	var faces:=PackedVector3Array()
	if kind in ["stormglass","pullstone","ventlung"]:
		faces=AuthoredAssets.mesh_for("strange_"+kind).get_faces()
	for path: PackedVector3Array in paths[kind]:
		var radius:=filament_radius_m*(1.0 if path_index==0 else branch_radius_fraction)
		if not faces.is_empty():
			_conformed_path(seam,path,faces,Vector3.BACK,radius)
			_conformed_path(seam,path,faces,Vector3.FORWARD,radius)
			if kind in ["pullstone","ventlung"] and path_index==0:
				_conformed_path(seam,path,faces,Vector3.RIGHT,radius)
				_conformed_path(seam,path,faces,Vector3.LEFT,radius)
		else:
			for i in range(path.size()-1):
				ArtGeometry.branch(seam,path[i],path[i+1],radius,Color.WHITE,.78)
				if kind=="thrumroot":
					ArtGeometry.branch(seam,path[i]*Vector3(1,1,-1),path[i+1]*Vector3(1,1,-1),filament_radius_m*branch_radius_fraction,Color.WHITE,.78)
		path_index+=1
	for window: Array in core_windows.get(kind,[]):
		ArtGeometry.oval(seam,window[0],window[1],Color.WHITE)
	result["EmbeddedFilaments"]=seam.commit()
	if fragments.has(kind):
		var host:=ArtGeometry.begin()
		# Tiny chips use compact authored bark/outcrop geometry; a full field
		# boulder's unseen surface detail is unnecessary at this fitted scale.
		var source:=AuthoredAssets.mesh_for("deadfall" if kind in ["lanternheart","thrumroot"] else "strange_low_outcrop")
		var bounds:=source.get_aabb()
		for entry: Array in fragments[kind]:
			var size: Vector3=entry[1]
			var scale:=size/bounds.size
			var at: Vector3=entry[0]
			var transform:=Transform3D(Basis.from_scale(scale),at-bounds.get_center()*scale)
			for index in source.get_surface_count():host.append_from(source,index,transform)
		result["HostFragments"]=host.commit()
	if kind=="pullstone":
		var grit:=ArtGeometry.begin()
		for i in grit_count:
			var t:=float(i)/maxf(1,float(grit_count-1))
			var at:=Vector3(.56+sin(t*21)*.09,.28+t*.45,.12+sin(t*13)*.23)
			ArtGeometry.oval(grit,at,Vector3.ONE*grit_radius_m*(.75+float(i%3)*.2),Color.WHITE)
		result["SuspendedGrit"]=grit.commit()
	return result

func _conformed_path(st: SurfaceTool, path: PackedVector3Array, faces: PackedVector3Array, outward: Vector3, radius: float) -> void:
	var previous:=Vector3.INF
	for i in range(path.size()-1):
		var steps:=maxi(1,ceili(path[i].distance_to(path[i+1])/seam_sample_m))
		for step in range(steps+1):
			var at:=path[i].lerp(path[i+1],float(step)/float(steps))
			var point:=_project_surface(at,faces,outward)
			if point.is_finite() and previous.is_finite() and point.distance_to(previous)<seam_sample_m*2.5 and point.distance_squared_to(previous)>.000001:
				_fine_segment(st,previous,point,radius)
			previous=point

func _fine_segment(st: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
	# Eight triangles per short span; internal caps and cylinder height rings
	# cannot be seen on an embedded millimetre-scale line and only waste detail.
	var direction: Vector3=(b-a).normalized()
	var across:=direction.cross(Vector3.UP if absf(direction.y)<.9 else Vector3.RIGHT).normalized()*radius
	var other:=direction.cross(across)
	var ring: Array[Vector3]=[across,other,-across,-other]
	for i in 4:
		var next: int=(i+1)%4
		ArtGeometry.triangle(st,a+ring[i],b+ring[i],b+ring[next],Color.WHITE)
		ArtGeometry.triangle(st,a+ring[i],b+ring[next],a+ring[next],Color.WHITE)

func _project_surface(at: Vector3, faces: PackedVector3Array, outward: Vector3) -> Vector3:
	# A read-only art ray has no physics body, cannot affect an interaction and is
	# cached with the kind's shared detail mesh after this one-time construction.
	var from:=at*(Vector3.ONE-outward.abs())+outward*3.0
	var closest:=Vector3.INF
	var distance:=INF
	for index in range(0,faces.size(),3):
		var a:=faces[index]
		var b:=faces[index+1]
		var c:=faces[index+2]
		if at.y<minf(a.y,minf(b.y,c.y)) or at.y>maxf(a.y,maxf(b.y,c.y)):continue
		if outward.z!=0 and (at.x<minf(a.x,minf(b.x,c.x)) or at.x>maxf(a.x,maxf(b.x,c.x))):continue
		if outward.x!=0 and (at.z<minf(a.z,minf(b.z,c.z)) or at.z>maxf(a.z,maxf(b.z,c.z))):continue
		var hit: Variant=Geometry3D.ray_intersects_triangle(from,-outward,a,b,c)
		if hit==null:continue
		var found: Vector3=hit
		var next:=from.distance_squared_to(found)
		if next<distance:
			distance=next
			closest=found-outward*seam_inset_m
	return closest
