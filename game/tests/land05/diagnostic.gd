extends "res://tests/rf05/water.gd"
## Chosen ordinary V12 seed 77 lake-to-smithy approach, not the unknown owner route.
## Only initial relocation is staged. World, creatures, controller and streaming stay active.
var trace: Node
var setup_began: int
var label := "entry"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND05_OUTPUT")
 world_profile="frontier_v12"
 setup_began=Time.get_ticks_usec()
 trace=preload("res://scripts/play03_trace.gd").install(self,PackedStringArray(["--play03-trace="+output.path_join("traces")]))
 trace._metadata["land05_route"]="Seed 77 V12; staged start at outer lakeside outlook route; walk 48m towards smithy and revisit same path. No owner reproduction seed supplied."
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("diagnostic-private.json"))
 player.class_panel.choose("warden")
 trace.get_tree().process_frame.connect(mark_window)
 run.call_deferred()
func mark_window() -> void:
 if trace.active: trace._interval["land05_window"]=label
func walk_point(target: Vector3) -> bool:
 var prior:=player.position
 var stuck:=0
 for i in 180:
  var delta: Vector3=(target-player.position)*Vector3(1,0,1)
  if delta.length()<.5:
   player.test_walk=Vector2.ZERO
   return true
  player.rotation.y=atan2(-delta.x,-delta.z)
  player.test_walk=Vector2(0,-1)
  await tick()
  if (player.position-prior).length()<.005:stuck+=1
  else:stuck=0
  prior=player.position
  if stuck>90:break
 player.test_walk=Vector2.ZERO
 return false
func run() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 check(not terrain.map.is_empty(),"ordinary entry creates world")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"mouse visible and capture cannot focus")
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=120
 var route: PackedVector3Array=terrain.map.scarwater[0].outlook_route
 var selected: Array[Vector3]=[]
 var distance:=0.0
 for at: Vector3 in route:
  if not selected.is_empty():distance+=at.distance_to(selected.back())
  selected.append(at)
  if distance>=48:break
 var report:={"setup_ms":(Time.get_ticks_usec()-setup_began)/1000.0,"profile":world_profile,"seed":world_seed,"route":selected,"route_m":distance,"scope":"Staged start then actual controller out/back; live actors and all ordinary systems. First process, existing driver cache retained. VSync off, 120fps cap, 1280x720 Forward+."}
 label="staged_arrival"
 # Preparation at relocation is separately timed; no large radius or settle loop.
 player.set_physics_process(false)
 player.position=selected[0]+Vector3.UP*1.1
 player.velocity=Vector3.ZERO
 terrain.ensure_area(player.position,12)
 player.set_physics_process(true)
 set_physics_process(true)
 for i in 2:await tick()
 label="first_walk"
 var reached:=true
 for at in selected:
  if not await walk_point(at):reached=false;report["stopped_at"]=player.position;break
 check(reached,"ordinary lakeside first route reaches endpoint")
 label="turnaround"
 player.test_walk=Vector2.ZERO
 for i in 60:await tick()
 label="revisit"
 if reached:
  selected.reverse()
  for at in selected:
   if not await walk_point(at):reached=false;report["return_stopped_at"]=player.position;break
 check(reached,"same route revisit reaches start")
 label="stationary"
 for i in 120:await tick()
 report["retention"]=terrain.chunk_stream.retention()
 report["stage_samples"]=terrain.chunk_stream.preparation_samples()
 report["checks"]=checks;report["failures"]=failures
 report["trace"]=trace.output_path
 trace.stop("LAND05 bounded route finished")
 FileAccess.open(output.path_join("diagnostic-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("LAND05_DIAGNOSTIC ",checks," checks / ",failures," failures; route=",distance)
 get_tree().quit(0 if failures==0 else 1)
