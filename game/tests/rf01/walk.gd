extends Sandpit
## One natural daylight walk. Starting pose is a capture placement; every
## subsequent step uses the real controller, collision and active native world.
var output: String
var failures := 0
var captured := 0
var rows: Array = []
var points := [Vector3(440.5,0,445.5),Vector3(411.5,0,445.5),Vector3(391.5,0,440.5),Vector3(363.5,0,439.5)]
func check(ok: bool,label: String) -> void:
 if not ok: failures+=1; printerr("FAIL RF01 WALK: ",label)

func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF01_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 _walk.call_deferred()

func _walk() -> void:
 check(seed_controls.continue_saved(),"normal Continue opens the same private world")
 var settings = preload("res://rf01/low_cover.tres")
 var envelopes_ok := true
 for role in ["grass-meadow","grass-edge","fern-sparse"]:
  var mesh: ArrayMesh = settings.mesh_for(role)
  var bound: AABB = mesh.get_meta("rf01_clearance")
  var radius: float = (settings.fern_width_m if role=="fern-sparse" else settings.grass_width_m)*0.5
  for surface in mesh.get_surface_count():
   for vertex: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
    envelopes_ok = envelopes_ok and Vector2(vertex.x,vertex.z).length()<=radius+.0001 and vertex.y>=-.0001 and bound.has_point(vertex)
 check(envelopes_ok,"filled crowns retain the checked root, radius and sway bounds")
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("private-world.json")))
 var restored: Dictionary=JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
 check(restored.stations==saved.stations,"full-precision station ownership and pose match the saved record")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"mouse capture opt-out is active")
 check(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"window cannot take focus")
 check(RenderingServer.get_current_rendering_method()=="forward_plus","one Forward+ renderer")
 if failures>0: return _finish()
 set_physics_process(true)
 Engine.max_fps=60
 player.set_physics_process(false)
 terrain.ensure_area(points[0],40)
 terrain.resource_stream.focus(points[0],true)
 await get_tree().physics_frame
 var ground := terrain.rendered_height(points[0].x,points[0].z,float(terrain.height_at(floori(points[0].x),floori(points[0].z))))
 check(is_finite(ground),"route has native surface support")
 if not is_finite(ground): return _finish()
 player.position=Vector3(points[0].x,ground+1.02,points[0].z)
 player.velocity=Vector3.ZERO
 player.rotation.y=PI/2
 player.set_physics_process(true)
 for i in 90: await get_tree().process_frame
 check(player.is_on_floor(),"route starts with real floor contact")
 await still("01-meadow.png")
 var started:=player.position
 var distance:=0.0
 var previous:=started
 var frames:=0
 var segment:=1
 var stuck_frames:=0
 var last_progress:=started
 while segment<points.size() and frames<1800:
  var offset: Vector3=(points[segment]-player.position)*Vector3(1,0,1)
  if offset.length()<1.2:
   segment+=1
   if segment==2: await still("02-woodland-edge.png")
   continue
  player.rotation.y=lerp_angle(player.rotation.y,atan2(-offset.x,-offset.z),.09)
  player.test_walk=Vector2(0,-1)
  if player.is_on_floor() and player.test_move(player.global_transform,offset.normalized()*.7):
   Input.action_press("jump")
  else: Input.action_release("jump")
  await get_tree().process_frame
  frames+=1
  distance+=((player.position-previous)*Vector3(1,0,1)).length()
  previous=player.position
  if frames%30==0:
   if ((player.position-last_progress)*Vector3(1,0,1)).length()<.2: stuck_frames+=30
   else: stuck_frames=0
   last_progress=player.position
   rows.append({"frame":frames,"position":[player.position.x,player.position.y,player.position.z],"grounded":player.is_on_floor()})
  # Capture only a short middle stretch: 8 seconds at 15 fps, normal speed.
  if frames>=360 and frames<840 and frames%4==0:
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_jpg(output.path_join("media/walk-%03d.jpg"%captured),.90)
   captured+=1
  if stuck_frames>=120: break
 player.test_walk=Vector2.ZERO
 Input.action_release("jump")
 await still("03-woodland.png")
 check(distance>55.0,"real controller crosses a useful meadow/woodland segment")
 check(captured>0,"short motion sequence was captured")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"capture comfort stays active throughout")
 var report := {"seed":77,"profile":terrain.world_profile(),"distance_m":distance,"controller_frames":frames,"captured_frames":captured,"clip_fps":15,"route_complete":segment==points.size(),"stuck_frames":stuck_frames,"start":[started.x,started.y,started.z],"end":[player.position.x,player.position.y,player.position.z],"failures":failures,"rows":rows,"scope":"Native seed-77 meadow into existing oldgrowth woodland. Native impact locations are distant from this nearby segment; no terrain or trees were moved. One daylight condition, live world/physics, scripted real controller."}
 FileAccess.open(output.path_join("walk-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF01_WALK distance=",distance," frames=",frames," captured=",captured," failures=",failures)
 _finish()

func still(filename: String) -> void:
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join("media/"+filename))

func _finish() -> void:
 get_tree().quit(0 if failures==0 else 1)