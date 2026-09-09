extends "res://art05/review.gd"
const SAVE="user://art05-paid-route.json"
var harvested_id:=""
var walked_metres:=0.0
var release_count:=0
var walk_frames:=0
var walk_images:=0
func execute():
    var manager:=SaveManager.new()
    if "--restart" in OS.get_cmdline_user_args():
        var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
        var route_report:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output+"/check_route-checks.json"))
        check(manager.read(SAVE,player),"fresh process loads isolated complete save: "+manager.last_error)
        freeze_fixtures()
        check(JSON.parse_string(_sim().export_json())==JSON.parse_string(expected.sim),"restart exact inventory and progression")
        check(_sim().leyline_save()==expected.leylines,"restart exact finite source lots/work/claims")
        check(_sim().contraption_save()==expected.contraptions,"restart exact paid fixture and stored heat")
        for frame in 3:await get_tree().process_frame
        var b:=fixture("red_heat_buffer")
        check(b!=null and b.has_meta("art05"),"restart recreates one fitted usable paid buffer")
        check(not terrain.resource_stream.records.has(route_report.harvested_id),"restart cannot regrow the harvested route tree")
        check(_sim().world_effect_active("host_defeated:lf3_red_rooting"),"restart retains finite boar defeat")
        check(get_tree().get_nodes_in_group("contraptions").size()==_sim().contraption_ids().size(),"restart exactly one scene per native fixture")
        return complete()
    # Acquisition is paced by existing no-grants journey helpers. Interaction and
    # construction dispatch through the real work panel, aim probe and click path.
    if not await gather("wood",65):return complete()
    if not craft("workbench_kit"):return complete()
    if not await place_paid_kit("workbench_kit",route[0]+Vector3(5,0,5)):return complete()
    refresh_stations()
    if not craft("timber_frame",2,bench):return complete()
    if not await gather("fieldstone",6) or not craft("mason_yard_kit",1,bench):return complete()
    if not await place_paid_kit("mason_yard_kit",route[0]+Vector3(9,0,5)):return complete()
    var yard:StationSite
    for station in get_tree().get_nodes_in_group("crafting_stations"):
        if station.player_built and station.station_id==&"mason_yard":yard=station
    if not craft("timber_wedge",4) or not await gather("split_stone",16) or not craft("dress_stone",8,yard):return complete()
    if not await gather("iron_ore",16) or not craft("forge_kit",1,bench):return complete()
    if not await place_paid_kit("forge_kit",route[0]+Vector3(5,0,9)):return complete()
    refresh_stations()
    if not craft("smelt_iron",2,forge):return complete()
    for source in get_tree().get_nodes_in_group("leyline_sources"):
        if source.source_id=="red_home_margin":red=source
    await aim_at(red);player.interact()
    for step in 4:await press(String(red.state().next_work))
    check(int(red.state().claim.get("red_salt",0))==16,"real source produces one finite 16-salt claim")
    await press("Collect Red Salt")
    check(_sim().material_count("red_salt")==16 and red.state().claim.get("red_salt",0)==0,"collection transfers exactly once")
    player.work_panel.close_panel()
    if not craft("assemble_red_heat_buffer",1,bench):return complete()
    await blocked_placement()
    if not await place_paid_kit("red_heat_buffer_kit",route[0]+Vector3(7,0,9)):return complete()
    freeze_fixtures()
    var buffer:=fixture("red_heat_buffer")
    await aim_at(buffer);player.interact();await press("Pay for 1 heat");player.work_panel.close_panel()
    check(machine(buffer).heat==1 and _sim().material_count("red_salt")==10,"placed buffer's heat costs two real salt after four-salt frame")
    await get_tree().process_frame
    check(baseline or buffer.has_meta("art05"),"paid buffer owns the fitted art")
    # One surviving route tree: partial harvest, streaming retirement/recreation,
    # then normal depletion. No shadow resource record or stock refill is allowed.
    await harvest_and_stream()
    check(manager.write(SAVE,player),"write paid full-world checkpoint: "+manager.last_error)
    var inventory_before:=_sim().inventory().duplicate(true)
    var before:Dictionary=manager.capture(player)
    check(manager.read(SAVE,player),"same-process full restore: "+manager.last_error)
    freeze_fixtures();refresh_stations()
    check(_sim().inventory()==inventory_before,"restored inventory available")
    player.global_position=route[0]+Vector3(3,1.2,5);player.velocity=Vector3.ZERO
    check(manager.write("user://art05-before-hunt.json",player),"retain paid playable route before finite hunt")
    await walk_route()
    await fight_host()
    if is_instance_valid(buffer):pass
    # Leave a safe playable checkpoint at the paid workshop after the finite hunt.
    player.global_position=route[0]+Vector3(3,1.2,5);player.velocity=Vector3.ZERO
    check(manager.write(SAVE,player),"save finite hunt and paid workshop for fresh-process restart")
    complete()
func blocked_placement():
    var build:=player.placement
    build.set_build_mode_enabled(true);player.build_palette.open_panel();player.build_palette.select_entry(&"red_heat_buffer_kit","kit");player.build_palette.close_panel()
    # Use actual source body as obstruction, with the same native preview lattice.
    var c:=Vector3i(floori(red.position.x),ceili(red.position.y),floori(red.position.z))
    player.position=red.position+Vector3(0,2.3,3)
    build.preview_element={"kind":"volume","axis":0,"cell":c*2};build.preview_visible=true
    var before:=_sim().inventory().duplicate(true)
    var machines:=_sim().contraption_save()
    check(not build.try_place_block(),"real source collision rejects overlapping kit")
    check(_sim().inventory()==before and _sim().contraption_save()==machines,"rejected overlap preserves kit and native ownership")
    build.set_build_mode_enabled(false)
func harvest_and_stream():
    var tree:ResourceNode
    terrain.ensure_area(route[0],30)
    for n in get_tree().get_nodes_in_group("resources"):
        if n.visual==&"tree" and n.remaining_units>0 and n.global_position.distance_to(route[0])<24:tree=n;break
    if not check(tree!=null,"surviving actual route tree exists"):return
    harvested_id=tree.resource_id
    var original_units:=tree.remaining_units
    player.global_position=tree.global_position+Vector3(0,1.2,1.3)
    player._apply_work(tree,tree.work(_sim()))
    check(tree.drive_progress>0,"route tree keeps partial native work")
    var progress:=tree.drive_progress
    var phase:float=tree.get_meta("art05_phase",-1.0)
    var old_instance:=tree.get_instance_id()
    var at:=tree.global_position
    terrain.resource_stream.capture()
    terrain.resource_stream.focus(Vector3(800,40,800),true)
    check(not is_instance_valid(tree),"real stream retirement frees harvested actor")
    terrain.resource_stream.focus(at,true)
    tree=terrain.resource_stream.materialise(harvested_id)
    for frame in 2:await get_tree().process_frame
    check(tree.get_instance_id()!=old_instance and tree.drive_progress==progress and tree.remaining_units==original_units,"stream reentry restores exact stock and partial work")
    check(baseline or tree.has_meta("art05"),"streamed tree gets one fitted presentation")
    check(baseline or (phase>=0 and tree.get_meta("art05_phase",-2)==phase),"stream reentry preserves its independent scar phase")
    var carried:=_sim().material_count("wood")
    for attempt in 12:
        if tree.remaining_units==0:break
        player._apply_work(tree,tree.work(_sim()))
    check(tree.remaining_units==0,"normal work exhausts route tree")
    await collect()
    terrain.resource_stream.capture()
    check(not terrain.resource_stream.records.has(harvested_id),"depletion survives in authoritative finite ledger")
    check(_sim().material_count("wood")>=carried,"released wood uses ordinary capacity-aware pickups")
func walk_route():
    player.work_panel.close_panel();player.build_palette.close_panel();player.placement.set_build_mode_enabled(false)
    player.position=route[2]+Vector3.UP*1.2;player.velocity=Vector3.ZERO;player.rotation=Vector3.ZERO
    player.set_physics_process(true);player.combat.set_physics_process(true)
    if DisplayServer.get_name()!="headless":
        player.hide();player.hud.hide();player.camera.position=Vector3(0,.65,0);player.camera.rotation=Vector3.ZERO
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output+"/walk"))
    for frame in 45:await get_tree().physics_frame
    var previous:=player.global_position
    var positions:Array=[]
    var stalled:=false
    Input.action_press("move_forward")
    for i in range(3,route.size()-3):
        var target:Vector3=route[i]
        var reached:=false
        for frame in 180:
            var delta:Vector3=(target-player.global_position)*Vector3(1,0,1)
            if delta.length()<.55:reached=true;break
            player.look_at(player.global_position+delta)
            await get_tree().physics_frame
            walked_metres+=player.global_position.distance_to(previous);previous=player.global_position
            walk_frames+=1
            if DisplayServer.get_name()!="headless" and walk_frames%18==0:
                await RenderingServer.frame_post_draw
                get_viewport().get_texture().get_image().save_png(output+"/walk/%04d.png"%walk_images);walk_images+=1
            if frame%20==0:positions.append([previous.x,previous.y,previous.z])
        if not reached:stalled=true;report.walk["stalled_waypoint"]=i;break
    Input.action_release("move_forward")
    report.walk.merge({"metres":walked_metres,"positions":positions,"stalled":stalled})
    check(not stalled and walked_metres>100,"actual input/controller traverses existing source route without teleport or collision changes")
func fight_host():
    var pack:Dictionary
    for p in mob_packs.packs:
        if p.get("frontier_host_id","")==host_record.id:pack=p;break
    if not pack.spawned:mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
    if not check(pack.members.size()==1,"one native finite route boar"):return
    var enemy:Enemy=pack.members[0]
    enemy.set_physics_process(true)
    enemy.attack_released.connect(func(_kind):release_count+=1)
    if not baseline:
        enemy.apply_chill(100)
        for tick in 3:await get_tree().physics_frame
        var binding:Dictionary
        for b in art.bindings:
            if b.kind=="boar" and b.owner.get_ref()==enemy:binding=b;break
        check(not binding.is_empty(),"native actor owns exactly one fitted animation adapter")
        var pose_time:float=binding.animation.current_animation_position
        for tick in 15:await get_tree().physics_frame
        check(enemy.is_frozen() and is_equal_approx(binding.animation.current_animation_position,pose_time),"native freeze holds fitted pose")
        check(binding.material.get_shader_parameter("status_tint").a>0.5 and not enemy.get_node("FrontierHostLook").tell.visible,"native freeze has visible material priority and cancels warning")
        for tick in 180:
            if not enemy.is_frozen():break
            await get_tree().physics_frame
        check(not enemy.is_frozen(),"freeze expires through native time")
    var casts:=0
    var combat_images:=0
    if DisplayServer.get_name()!="headless":DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output+"/combat"))
    var tell_seen:=false
    var skin_seen:=baseline
    # Observe and dodge a complete native attack before casting. This keeps the
    # check meaningful even when starting casts can kill during recovery.
    for frame in 600:
        if release_count>0:break
        var to:Vector3=(enemy.position-player.position)*Vector3(1,0,1)
        var forward:=to.normalized();var distance:=to.length()
        player.look_at(player.position+forward)
        var move:=forward if distance>1.5 else Vector3.ZERO
        if enemy.state=="windup":
            tell_seen=tell_seen or enemy.get_node("FrontierHostLook").tell.visible
            move=-forward if distance<enemy.release_radius+.35 else Vector3.ZERO
            if not baseline:
                for b in art.bindings:
                    if b.kind=="boar" and b.owner.get_ref()==enemy and b.pose=="windup":skin_seen=true
        var local:Vector3=player.global_basis.inverse()*move
        player.test_walk=Vector2(local.x,local.z)
        await get_tree().physics_frame
    for frame in 60*60:
        if not is_instance_valid(enemy) or enemy.life<=0 or player.combat.life<=0:break
        if enemy.state=="windup" and enemy.get_node("FrontierHostLook").tell.visible:tell_seen=true
        if not baseline and enemy.has_meta("art05"):
            for b in art.bindings:
                if b.kind=="boar" and b.owner.get_ref()==enemy and b.pose=="windup":skin_seen=true
        var to:Vector3=(enemy.position-player.position)*Vector3(1,0,1)
        var forward:=to.normalized();var distance:=to.length()
        player.look_at(player.position+forward);player.camera.look_at(enemy.position+Vector3.UP*.7)
        var move:=forward if distance>1.3 else Vector3.ZERO
        if enemy.state in ["windup","release"]:move=-forward if distance<enemy.release_radius+.35 else Vector3.ZERO
        var local:Vector3=player.global_basis.inverse()*move
        player.test_walk=Vector2(local.x,local.z)
        for skill in _sim().skill_bar():
            var definition:Dictionary=player.combat.skills.get(skill,{})
            if definition.get("delivery","")=="dash":continue
            if definition.get("delivery","") in ["cone","strike"] and distance>player.combat.strike_reach(skill):continue
            if player.combat.use_skill(skill):casts+=1;break
        await get_tree().physics_frame
        if DisplayServer.get_name()!="headless" and frame%12==0:
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png(output+"/combat/%04d.png"%combat_images);combat_images+=1
    player.test_walk=Vector2.ZERO;player.set_physics_process(false);player.combat.set_physics_process(false)
    report["harvested_id"]=harvested_id
    report["combat"]={"casts":casts,"releases":release_count,"player_life":player.combat.life,"enemy_life":enemy.life if is_instance_valid(enemy) else 0.0}
    check((not is_instance_valid(enemy) or enemy.life<=0) and player.combat.life>0,"actual starting casts defeat native boar with live incoming damage")
    check(casts>0 and release_count>0,"native attacks and player casts actually occur")
    check(tell_seen and skin_seen,"actual windup retains native warning and drives fitted skin")
    check(player.combat.invulnerable_left==0,"no dash invulnerability or test protection")
