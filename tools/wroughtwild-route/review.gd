extends "res://tests/living_frontier_flow.gd"
var art:Node
var route:PackedVector3Array
var host_record:Dictionary
var baseline:=false
var report:Dictionary={"checks":[],"views":[],"walk":{},"baseline":false}
var camera:Camera3D
var output:String
func _ready():
    world_seed=77;world_profile="living_frontier_wave3"
    _build_world(world_seed);player.class_panel.choose("warden")
    for n in [player,player.placement,player.combat,player.spring_arm,mob_packs]:n.set_physics_process(false)
    mob_packs.set_process(false)
    baseline="--baseline" in OS.get_cmdline_user_args();report.baseline=baseline
    for h in terrain.map.frontier_hosts:
        if h.id=="lf3_red_rooting":host_record=h;route=h.source_route
    if not baseline:
        art=load("res://art05/route_art.gd").new();add_child(art);art.setup(self)
    output="res://../evidence-"+("baseline" if baseline else "art")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    execute.call_deferred()
func check(ok:bool,label:String)->bool:
    super.check(ok,label);report.checks.append({"ok":ok,"label":label});return ok
func execute():
    camera=Camera3D.new();add_child(camera);camera.current=true;camera.fov=60
    player.hide();player.hud.hide();mood.set_process(false)
    if DisplayServer.get_name()=="headless":return complete()
    for lighting in ["day","dusk"]:
        for view in ["source","trail","boar"]:
            var at:Vector3=route[0] if view=="source" else route[66] if view=="trail" else host_record.position
            terrain.ensure_area(at,36);player.global_position=at+Vector3(8,1.2,10)
            if view=="boar":
                for pack in mob_packs.packs:
                    if pack.get("frontier_host_id","")==host_record.id and not pack.spawned:mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
                for frame in 90:await get_tree().physics_frame
                for e in get_tree().get_nodes_in_group("enemies"):e.set_physics_process(false)
            mood._target=mood.active_mood(mood._biome_under_player());mood._apply(1.0)
            var sun:DirectionalLight3D=get_node("Sun")
            if lighting=="dusk":sun.light_energy*=.48;sun.light_color=Color("d9bd91")
            camera.global_position=at+Vector3(3,1.8,4) if view=="source" else at+Vector3(-3,1.65,5) if view=="boar" else at+Vector3(0,1.65,0)
            camera.look_at(at+Vector3(0,.65,0) if view!="trail" else route[76]+Vector3.UP*1.65)
            for frame in 45:await get_tree().process_frame
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png(output+"/"+view+"-"+lighting+".png")
            report.views.append({"id":view+"-"+lighting,"camera":str(camera.global_position),"sun_energy":sun.light_energy})
    var manager:=SaveManager.new()
    check(manager.read("res://art05/route-checkpoint.json",player),"capture the actual paid workshop checkpoint")
    freeze_fixtures()
    var buffer:=fixture("red_heat_buffer")
    check(buffer!=null and machine(buffer).heat==1,"capture existing stored paid heat")
    for frame in 4:await get_tree().process_frame
    player.hide();player.hud.hide()
    for lighting in ["day","dusk"]:
        mood._target=mood.active_mood(mood._biome_under_player());mood._apply(1.0)
        if lighting=="dusk":$Sun.light_energy*=.48;$Sun.light_color=Color("d9bd91")
        camera.position=buffer.position+Vector3(2.5,1.7,3.5);camera.look_at(buffer.position+Vector3.UP*.65)
        for frame in 45:await get_tree().process_frame
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(output+"/buffer-"+lighting+".png")
        report.views.append({"id":"buffer-"+lighting,"camera":str(camera.global_position),"native_heat":machine(buffer).heat,"owned_salt":_sim().material_count("red_salt")})
    complete()
func complete():
    report["fits"]=art.fits if art else []
    report["failures"]=failures
    var f=FileAccess.open(output+"/"+get_script().resource_path.get_file().get_basename()+("-restart" if "--restart" in OS.get_cmdline_user_args() else "")+"-checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "))
    print("ART05_REVIEW ",checks," checks, ",failures," failures")
    get_tree().quit(0 if failures==0 else 1)
