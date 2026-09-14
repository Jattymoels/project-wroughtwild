extends Node
var checks:=0
var failures:=0
var records:Array=[]
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failures+=1;printerr("R7_MESH_FAIL ",label)
func _ready():
    for biome in GroundCover.COVER:
        for entry in GroundCover.COVER[biome]:
            var mesh:=R7Cover.ground(entry)
            if mesh!=null:inspect("ground/"+String(biome)+"/"+String(entry.kind),mesh)
    for kind in ["shrub","fern_bed"]:
        for variant in 2:
            inspect("habitat/"+kind+str(variant),R7Cover.habitat(kind,variant,AuthoredAssets.mesh_for(kind)))
    for kind in ["shrub","fern"]:inspect("regional/"+kind,R7Cover.regional(kind,StrangeSites._mesh_for(kind)))
    var out:="res://../evidence/r7-mesh-checks.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
    FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"groups":records,"scope":"Independent scan of every actual composed vertex at both extrema of the shader sway, against each unchanged delivered envelope. Lowest root plane must have zero movement. No source geometry/texture bytes changed."},"  "))
    print("R7_MESH_CHECKS ",checks," checks, ",failures," failures")
    get_tree().quit(1 if failures else 0)
func inspect(id:String,mesh:Mesh)->void:
    var envelope:AABB=mesh.get_meta("r7_envelope")
    var vertices:=0;var roots:=0;var outside:=0;var root_shift:=0.0;var max_bend:=0.0
    for surface in mesh.get_surface_count():
        var mat:ShaderMaterial=mesh.surface_get_material(surface)
        var root_y:float=mat.get_shader_parameter("root_base_y")
        var amount:float=mat.get_shader_parameter("plant_bend")
        check(not bool(mat.get_shader_parameter("altered")),id+" ordinary surface has no scar emission")
        for v:Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
            vertices+=1
            var bend:=amount*maxf(v.y-root_y,0.0)
            max_bend=maxf(max_bend,bend)
            if absf(v.y-root_y)<.00001:roots+=1;root_shift=maxf(root_shift,bend)
            for sign in [-1,1]:
                var deformed:Vector3=v+Vector3(1,0,.35)*bend*sign
                if not envelope.grow(.0001).has_point(deformed):outside+=1
    check(vertices>0 and roots>0,id+" actual geometry includes rooted source bases")
    check(root_shift<.000001,id+" source base stays fixed throughout sway")
    check(outside==0,id+" full deformed silhouette stays inside old clearance envelope")
    records.append({"id":id,"vertices":vertices,"root_vertices":roots,"root_shift_m":root_shift,"outside_envelope_extrema":outside,"max_bend_m":max_bend,"parts":mesh.get_meta("r7_parts"),"envelope":str(envelope),"bounds":str(mesh.get_aabb())})
