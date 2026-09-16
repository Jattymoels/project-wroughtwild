extends "res://tests/land02b/use.gd"
## Focused continuation of the observed exit snag; paid-use evidence is reused.
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND02B_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("contact-private.json"))
 player.class_panel.choose("warden")
 contact_run.call_deferred()
func contact_run() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 if terrain.map.is_empty():get_tree().quit(1);return
 quiet();place_data=terrain.map.scarwater[0];setup_lake()
 var side: Vector3=place_data.direction
 var along:=Vector3(-side.z,0,side.x)
 var scar: Vector3=place_data.scar+side*2.15
 scar.y=terrain.height_at(floori(scar.x),floori(scar.z))
 var entry:=scar-along*(float(place_data.fissure_length_m)*.5+2)
 var end:=scar+along*(float(place_data.fissure_length_m)*.5+2)
 entry.y=terrain.height_at(floori(entry.x),floori(entry.z))+1.1
 ready_at(entry);terrain.set_process(true)
 for i in 15:await tick()
 for target: Vector3 in [scar,end,scar,entry]:
  var ok:=await travel(target,450)
  check(ok,"fissure controller leg reaches "+str(target))
  if not ok:
   print("LAND02B_EXIT_STOP target=",target," player=",player.position)
   for i in player.get_slide_collision_count():
    var hit:=player.get_slide_collision(i)
    print("LAND02B_EXIT_CONTACT ",hit.get_collider().get_path()," ",hit.get_position()," ",hit.get_normal())
 check(not player.swimming and player.is_on_floor(),"both exits leave the existing controller grounded and dry")
 ready_at(place_data.reveal+Vector3.UP*1.1)
 for i in 35:await tick()
 face_at(place_data.centre+side*(float(place_data.ridge_offset_m)+5)+Vector3.UP*float(place_data.relief_m)*.15)
 check(player.is_on_floor(),"final reveal at grounded player height")
 await still("final-reveal.png")
 var look: Vector3=place_data.scar-side*4-along*7
 look.y=terrain.height_at(floori(look.x),floori(look.z))+1.1
 ready_at(look)
 for i in 35:await tick()
 face_at(place_data.scar+along*2+Vector3.UP*1.4)
 await still("final-scar.png")
 for material in terrain._materials.values():
  if material is ShaderMaterial:material.set_shader_parameter("land02b_emission",0.0)
 await still("final-scar-unlit.png")
 FileAccess.open(output.path_join("contact-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"walk_distance_m":route_distance,"entry_horizon_ms":terrain.chunk_stream.horizon_build_ms,"scope":"Specific fissure-exit correction and final actual player-height appearance; previous paid-use and full bank-route evidence retained."},"\t"))
 print("LAND02B_CONTACT ",checks," checks / ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)
