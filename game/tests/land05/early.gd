extends "res://tests/land04/common.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND05_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("art-private.json"))
 player.class_panel.choose("warden")
 run.call_deferred()
func run() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 if terrain.map.is_empty():get_tree().quit(1);return
 quiet();journeys=terrain.map.force_journeys
 check(world_profile=="frontier_v13","fresh V13 ordinary entry")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"verified capture comfort")
 var green:=journey("green")
 ready_at(green.reveal+Vector3.UP*1.1);terrain.set_process(true)
 for i in 20:await tick()
 face_at(green.position+Vector3.UP)
 await still("green-reveal-early.png")
 var route: PackedVector3Array=green.source_route
 var reached:=true
 for at: Vector3 in route:
  if not await travel(at,200):reached=false;break
 check(reached,"Green source revealed through actual walking approach")
 face_at(green.position+Vector3.UP*.6)
 check(player.aim_probe().get("target")==source("green_home_margin"),"approach ends at actual resin source interaction")
 await still("green-work-early.png")
 await journey_picture(journey("green",true),"green-steppe-early")
 finish_job("early",{"green":green,"stats":terrain.force_journeys.stats,"position":player.position})
