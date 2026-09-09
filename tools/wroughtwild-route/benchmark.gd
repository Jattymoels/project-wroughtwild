extends "res://art05/review.gd"
func execute():
    assert(DisplayServer.get_name()!="headless","Performance evidence requires the renderer")
    camera=Camera3D.new();add_child(camera);camera.current=true;camera.fov=60
    player.hide();player.hud.hide();mood.set_process(false)
    var viewport:=get_viewport().get_viewport_rid()
    RenderingServer.viewport_set_measure_render_time(viewport,true)
    var samples:Array=[]
    for scene in ["source","one-boar","24-boar-fixture"]:
        var at:Vector3=route[0] if scene=="source" else host_record.position
        player.global_position=at+Vector3(0,1.2,24)
        terrain.ensure_area(player.global_position,64)
        terrain.resource_stream.focus(player.global_position,true)
        terrain.set_process(false)
        var actors:Array=[]
        if scene!="source":
            for i in (1 if scene=="one-boar" else 24):
                var offset:=Vector3.ZERO if scene=="one-boar" else Vector3((i%6-2.5)*1.8,0,(i/6-1.5)*2.0)
                var native_ground:Vector3=terrain.surface_position(floori(at.x+offset.x),floori(at.z+offset.z))
                var ground:float=terrain.rendered_height(at.x+offset.x,at.z+offset.z,native_ground.y,2.0)
                assert(is_finite(ground),"Stress actor needs its actual supported terrain height")
                var e:=Enemy.spawn(self,&"lf_red_boar",Vector3(at.x+offset.x,ground+1,at.z+offset.z));actors.append(e)
            for frame in 100:await get_tree().physics_frame
        camera.position=at+Vector3(3,1.8,4) if scene!="24-boar-fixture" else at+Vector3(11,5,13)
        camera.look_at(at+Vector3.UP*.65)
        for lighting in ["day","dusk"]:
            mood._target=mood.active_mood(mood._biome_under_player());mood._apply(1.0)
            if lighting=="dusk":$Sun.light_energy*=.48;$Sun.light_color=Color("d9bd91")
            for frame in 120:await get_tree().process_frame
            var wall:Array[float]=[];var gpu:Array[float]=[];var cpu:Array[float]=[]
            var previous:=Time.get_ticks_usec()
            for frame in 300:
                await get_tree().process_frame
                var now:=Time.get_ticks_usec();wall.append(float(now-previous)/1000.0);previous=now
                gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport));cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport))
            wall.sort();gpu.sort();cpu.sort()
            samples.append({"scene":scene,"lighting":lighting,"samples":300,"resource_count":get_tree().get_nodes_in_group("resources").size(),"resource_ids_hash":str(terrain.resource_stream.active.keys()).sha256_text(),"chunk_count":terrain.chunks.size(),"frame_ms_median":wall[150],"frame_ms_p95":wall[285],"gpu_ms_median":gpu[150],"gpu_ms_p95":gpu[285],"render_cpu_ms_median":cpu[150],"draw_calls":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"primitives":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"texture_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),"camera":str(camera.global_position)})
            await RenderingServer.frame_post_draw
            get_viewport().get_texture().get_image().save_png(output+"/benchmark-"+scene+"-"+lighting+".png")
        for e in actors:if is_instance_valid(e):e.queue_free()
        for frame in 3:await get_tree().process_frame
    var f=FileAccess.open(output+"/performance.json",FileAccess.WRITE)
    f.store_string(JSON.stringify({"baseline":baseline,"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":str(get_viewport().size),"vsync_mode":DisplayServer.window_get_vsync_mode(),"cases":samples,"note":"Actual game with existing terrain/resources. 24 live Enemy nodes form an isolated approved-cap stress fixture; this is not a world spawn-density change. Native resource arrivals are completed before timing and terrain streaming is held stationary for the fixed-camera comparison. Walking tests separately exercise live streaming. No screenshot work inside timed samples."},"  "))
    complete()
