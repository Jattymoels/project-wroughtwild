extends Node
## ART-05 pilot. Presentation follows existing owners; this node never writes simulation state.
const ROOT="res://art05/assets/"
var world:Node3D
var route:PackedVector3Array
var index:Dictionary
var bindings:Array[Dictionary]=[]
var clock:=0.0
var fits:Array[Dictionary]=[]
var enabled:=true
var scenes:Dictionary={}
var materials:Dictionary={}
var quiet_mask:Texture2D
var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art05/route.json"))
func setup(owner_world:Node3D):
    world=owner_world
    if world.world_profile!="living_frontier_wave3" or world.world_seed!=77:
        enabled=false
        return
    for h in world.terrain.map.frontier_hosts:
        if h.id=="lf3_red_rooting":route=h.source_route
    assert(not route.is_empty())
    index=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"asset-index.json"))
    get_tree().node_added.connect(observe)
    for group in ["resources","leyline_sources","contraptions","enemies"]:
        for n in get_tree().get_nodes_in_group(group):bind(n)
func observe(n:Node):
    if n is ResourceNode or n is LeylineSource or n is ContraptionSite or n is Enemy:bind_weak.call_deferred(weakref(n))
func bind_weak(reference:WeakRef):
    var node=reference.get_ref()
    if is_instance_valid(node):bind(node)
func near_route(p:Vector3)->bool:
    for r in route:
        if Vector2(r.x,r.z).distance_squared_to(Vector2(p.x,p.z))<=pow(float(settings.corridor_radius_m),2):return true
    return false
func load_scene(id:String,parent:Node3D)->Node3D:
    if not scenes.has(id):scenes[id]=load(ROOT+id+".glb")
    var instance:Node3D=scenes[id].instantiate()
    parent.add_child(instance)
    return instance
func hide_meshes(n:Node):
    if n is MeshInstance3D:n.hide()
    for c in n.get_children():hide_meshes(c)
func bounds(n:Node3D,root:Node3D)->AABB:
    var result:=AABB()
    var first:=true
    for m in n.find_children("*","MeshInstance3D",true,false):
        var b: AABB=(root.global_transform.affine_inverse()*m.global_transform)*m.get_aabb()
        result=b if first else result.merge(b);first=false
    return result
func fit(n:Node3D,target:AABB,id:String):
    var b:=bounds(n,n)
    var factor:=minf(target.size.x/b.size.x,minf(target.size.y/b.size.y,target.size.z/b.size.z))
    n.scale=Vector3.ONE*factor
    n.position=Vector3(target.get_center().x-b.get_center().x*factor,-b.position.y*factor,target.get_center().z-b.get_center().z*factor)
    fits.append({"id":id,"scale":factor,"original_envelope":str(target),"fitted_size":str(b.size*factor)})
func scar(family:String,shader_name:String="boar_scar")->ShaderMaterial:
    var key:=family+":"+shader_name
    if materials.has(key):return materials[key].duplicate()
    var m:=ShaderMaterial.new();m.shader=load("res://art05/"+shader_name+".gdshader")
    for k in index.bindings[family]:m.set_shader_parameter(k+"_texture",load(ROOT+index.bindings[family][k]))
    m.set_shader_parameter("use_normal_map",index.bindings[family].has("normal"))
    if shader_name=="boar_scar":
        var config:Dictionary=index.appearance.boar.scar
        for field in ["peak_emission","minimum_light","period_seconds","crest_width"]:m.set_shader_parameter(field,config[field])
        var c:Array=config.colour
        m.set_shader_parameter("core_colour",Color(c[0],c[1],c[2]).linear_to_srgb())
    else:
        var config:Dictionary=index.appearance.red.scar
        for field in ["peak_emission","minimum_light","period_seconds"]:m.set_shader_parameter(field,config[field])
        var c:Array=config.colour_srgb
        m.set_shader_parameter("core_colour",Color(c[0],c[1],c[2]))
    materials[key]=m
    return m.duplicate()
func material_all(n:Node,m:Material,mineral_only:=false):
    if n is MeshInstance3D:
        if mineral_only:
            for i in n.mesh.get_surface_count():
                var old=n.get_active_material(i)
                if old!=null and old.resource_name.begins_with("RED_"):n.set_surface_override_material(i,m)
        else:n.material_override=m
    for c in n.get_children():material_all(c,m,mineral_only)
func apply_phase(root:Node3D,owner_node:Node,key:String):
    var phase:=float(posmod(hash(key),10000))/10000.0
    owner_node.set_meta("art05_phase",phase)
    for mesh in root.find_children("*","MeshInstance3D",true,false):
        if mesh.material_override is ShaderMaterial:mesh.set_instance_shader_parameter("phase_offset",phase)
func bind(n:Node):
    if not enabled or not is_instance_valid(n) or not n.is_inside_tree() or n.is_queued_for_deletion() or n.has_meta("art05") or not near_route(n.global_position):return
    if n is ResourceNode and n.visual in [&"tree",&"boulder"]:
        var old:MeshInstance3D=n.get_node_or_null("MeshInstance3D")
        if old==null:return
        n.set_meta("art05",true)
        hide_meshes(old)
        var tree:bool=n.visual==&"tree"
        var affected:bool=n.global_position.distance_to(route[0])<float(settings.affected_radius_m) or n.global_position.distance_to(route[-1])<float(settings.affected_radius_m)
        var root:Node3D=load_scene(("altered-tree" if affected else "quiet-tree") if tree else "fractured-rock",n)
        if tree:load_scene("canopy-far",root).set_meta("art05_canopy",true)
        fit(root,old.get_aabb(),n.resource_id)
        var m:=scar("tree" if tree else "rock")
        m.set_shader_parameter("peak_emission",settings.grove_peak_emission)
        m.set_shader_parameter("minimum_light",settings.grove_minimum_light)
        m.set_shader_parameter("pulse_mode",3 if affected else 0)
        if not affected:
            if quiet_mask==null:
                var blank:=Image.create(1,1,false,Image.FORMAT_RGBA8);blank.fill(Color(0,0,0,1));quiet_mask=ImageTexture.create_from_image(blank)
            m.set_shader_parameter("scar_texture",quiet_mask)
        # Canopy keeps the approved leaf materials; only the woody/mineral host changes.
        for c in root.get_children():
            if c.has_meta("art05_canopy"):continue
            material_all(c,m)
        apply_phase(root,n,n.resource_id)
        bindings.append({"owner":weakref(n),"root":root,"kind":"resource","material":m,"original":old,"fit_transform":root.transform})
    elif n is LeylineSource and n.source_id=="red_home_margin":
        n.set_meta("art05",true);hide_meshes(n)
        var root:=load_scene("red-source-mid",n)
        var m:=scar("red","red_scar");material_all(root,m,true)
        var claims:=Node3D.new();n.add_child(claims)
        for i in 3:
            var fragment:=load_scene("red-fragment-%d"%(i+1),claims)
            fragment.position=Vector3(-.29+i*.22,.002,.58);fragment.scale=Vector3.ONE*.52
            var fm:=scar("fragment-%d"%(i+1),"red_scar");fm.set_shader_parameter("native_gain",index.appearance.red.presentation.claim_gain);fm.set_shader_parameter("state_mode",1)
            material_all(fragment,fm,true)
        bindings.append({"owner":weakref(n),"root":root,"claim":claims,"kind":"source","material":m})
    elif n is ContraptionSite and n.kind=="red_heat_buffer":
        bind_buffer(n)
    elif n is Enemy and n.enemy_id==&"lf_red_boar":
        n.set_meta("art05",true);hide_meshes(n._mesh)
        var motion=n._mesh.get_node_or_null("Motion")
        if motion:motion.set_physics_process(false)
        var root:=load_scene("boar-mid",n)
        fit(root,n._mesh.transform*n._mesh.get_aabb(),"lf_red_boar")
        var m:=scar("boar");material_all(root,m)
        apply_phase(root,n,String(n.get_meta("frontier_host_id",str(n.global_position))))
        var a:AnimationPlayer=root.find_children("*","AnimationPlayer",true,false)[0]
        a.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
        a.play("idle");a.seek(0.0,true);a.advance(0.0)
        bindings.append({"owner":weakref(n),"root":root,"kind":"boar","material":m,"animation":a,"last_position":n.global_position,"stride":0.0,"pose":""})
func bind_buffer(n:ContraptionSite):
    n.set_meta("art05",true);hide_meshes(n._visual)
    var root:=load_scene("red-buffer-mid",n)
    var m:=scar("red","red_scar");material_all(root,m,true)
    var record:Dictionary=n.sim.contraption_state(n.machine_key)
    var feeder:Dictionary=n.sim.contraption_state(record.get("link",""))
    var progress:=float(feeder.get("cycle_seconds",0)) if feeder.get("heat_key","")==n.machine_key else 0.0
    var cycles:=int(feeder.get("completed_cycles",0))
    bindings.append({"owner":weakref(n),"root":root,"kind":"buffer","material":m,"work_clock":progress,"previous_progress":progress,"previous_cycles":cycles})
func _process(delta:float):
    if not enabled:return
    clock+=delta
    for i in range(bindings.size()-1,-1,-1):
        var b:Dictionary=bindings[i]
        var n=b.owner.get_ref()
        if not is_instance_valid(n) or n.is_queued_for_deletion():bindings.remove_at(i);continue
        var m:ShaderMaterial=b.material
        m.set_shader_parameter("scar_clock",clock)
        m.set_shader_parameter("cosmetic_clock",clock)
        match b.kind:
            "resource":
                b.root.transform=b.original.transform*b.fit_transform
                b.original.hide()
                m.set_shader_parameter("status_tint",Color(.75,.8,.62,.15 if n._highlighted else 0.0))
            "source":
                var s:Dictionary=n.state()
                m.set_shader_parameter("state_mode",2 if s.lot<s.lots and s.claim.is_empty() and n.supported() else 0)
                m.set_shader_parameter("native_gain",index.appearance.red.presentation.source_work_gain if s.work>0 else index.appearance.red.presentation.source_ready_gain)
                b.claim.visible=int(s.claim.get("red_salt",0))>0
                # Native rare claim remains a separate marker after collecting raw material.
                n._claim.visible=s.claim.has(s.rare_item)
                n._crystals.hide()
            "buffer":
                var s:Dictionary=n.sim.contraption_state(n.machine_key)
                var f:Dictionary=n.sim.contraption_state(s.get("link",""))
                var progress:=float(f.get("cycle_seconds",0)) if f.get("heat_key","")==n.machine_key else 0.0
                var cycles:=int(f.get("completed_cycles",0))
                var advanced:float=(cycles-int(b.previous_cycles))*float(n.sim.contraption_config().feeder_cycle_seconds)+progress-float(b.previous_progress)
                var working:bool=advanced>0.0
                if working:b.work_clock+=advanced
                b.previous_progress=progress;b.previous_cycles=cycles
                m.set_shader_parameter("work_clock",b.work_clock)
                m.set_shader_parameter("native_gain",index.appearance.red.presentation.working_gain if working else float(index.appearance.red.presentation.stored_gain)*minf(1.0,float(int(s.get("heat",0))+int(f.get("escrow_heat",0)))/float(n.sim.contraption_config().heat_capacity)))
                m.set_shader_parameter("state_mode",3 if working else 1 if int(s.get("heat",0))+int(f.get("escrow_heat",0))>0 else 0)
            "boar":
                var distance:float=n.global_position.distance_to(b.last_position);b.last_position=n.global_position
                var pose:="idle";var time:=0.0
                if not n.is_frozen() and not n.staggered():
                    if n.state=="windup":pose="windup";time=1.0-n._windup_left/maxf(n.windup_seconds,.001)
                    elif n.state=="release":pose="release";time=1.0-n._release_left/maxf(n.release_seconds,.001)
                    elif distance>.0001 and distance<1.0:
                        b.stride+=distance/float(settings.boar_stride_m);pose="walk";time=fmod(b.stride,1.0)
                    elif n.state=="idle":pose="root";time=fmod(clock/float(settings.root_pose_seconds),1.0)
                    var a:AnimationPlayer=b.animation
                    if b.pose!=pose:a.play(pose);b.pose=pose
                    a.seek(time*a.get_animation(pose).length,true);a.advance(0.0)
                # Keep the actual status/hit material's priority above the cosmetic scar.
                var tint:Color=n._material.albedo_color
                var priority:bool=n.is_frozen() or n._flash_left>0.0 or n.burning_left>0.0 or n.bleeding_left>0.0
                m.set_shader_parameter("status_tint",Color(tint.r,tint.g,tint.b,0.65 if priority else 0.0))
                m.set_shader_parameter("status_emission",n._material.emission*n._material.emission_energy_multiplier if priority and n._material.emission_enabled else Color.BLACK)
