extends "res://tests/rf07/placement.gd"
var view_rows: Array=[]
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF09_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"904",output.path_join("fixtures/rf07/checked-world.json"))
 walk_cleanup.call_deferred()
func read_bench() -> void:
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("fixtures/rf07/expected.json")))
 bench=Vector3(expected.bench[0],expected.bench[1],expected.bench[2])
func face(target: Vector3) -> void:
 var offset:=target-player.camera.global_position
 player.rotation.y=atan2(-offset.x,-offset.z)
 player.spring_arm.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
func record_view(label: String) -> void:
 check(player.is_on_floor(),label+" has ordinary grounded player height")
 check(player.is_physics_processing() and is_physics_processing() and terrain.is_processing() and mob_packs.is_physics_processing(),label+" normal world systems active")
 await still(label+".png")
 view_rows.append({"name":label,"feet":[player.position.x,player.position.y,player.position.z],"camera_height":player.camera.global_position.y-player.position.y})
func walk_cleanup() -> void:
 if not check(seed_controls.continue_saved(),"ordinary Continue opens paid highland"):return finish_cleanup()
 read_bench()
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("fixtures/rf07/expected.json")))
 var floor_at:=Vector3(expected.target[0],expected.target[1],expected.target[2])
 var station_at:=Vector3(expected.station[0],expected.station[1],expected.station[2])
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"mouse and window focus remain free")
 check(RenderingServer.get_current_rendering_method()=="forward_plus","Forward+ only")
 set_physics_process(true)
 # Disclosed staging in retained scenes; subsequent highland route is real walking.
 ready_at(bench+Vector3(6,1.1,0))
 player.rotation.y=PI*.5
 player.spring_arm.rotation.x=-.10
 for i in 50:await tick()
 await record_view("01-highland")
 check(SaveManager.new().write(output.path_join("view-highland.json"),player),"private highland starting state")
 check(await travel(floor_at+Vector3(2.5,0,1.5),240),"ordinary highland approach")
 check(await travel(floor_at,200),"ordinary walk onto paid octagonal floor")
 check(player.is_on_floor(),"paid floor supports player")
 check(await travel(floor_at+Vector3(2.5,0,1),180),"ordinary floor exit")
 check(await travel(station_at+Vector3(2,0,0),220),"ordinary workbench approach")
 var station: StationSite
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built:station=node
 face(station.get_node("CollisionShape3D").global_position)
 for i in 20:await tick()
 player.interact()
 check(player.work_panel.is_open(),"aimed E opens existing paid workbench")
 player.work_panel.close_panel()
 # Shared shader consumers: one retained bank and one retained impact view.
 if not check(player.load_game(output.path_join("fixtures/rf06b/checked-world.json")),"retained fen/lake fixture opens"):return finish_cleanup()
 setup_lake()
 var bank:=Vector3(lake.x,0,lake.z)+axis*(float(lake.radius_m)+3)
 bank.y=terrain.height_at(floori(bank.x),floori(bank.z))+1.1
 ready_at(bank)
 set_physics_process(true)
 player.rotation.y=atan2(axis.x,axis.z)
 player.spring_arm.rotation.x=-.12
 for i in 50:await tick()
 await record_view("02-shaded-bank")
 check(not player.swimming,"bank remains dry")
 check(SaveManager.new().write(output.path_join("view-bank.json"),player),"private bank starting state")
 if not check(player.load_game(output.path_join("fixtures/rf08/approach-world.json")),"retained impact fixture opens"):return finish_cleanup()
 ready_at(Vector3(481.5,terrain.height_at(481,180)+1.1,180.5))
 set_physics_process(true)
 for i in 50:await tick()
 face(Vector3(479.5,30.5,171.5))
 await record_view("03-impact-growth")
 check(SaveManager.new().write(output.path_join("view-impact.json"),player),"private impact starting state")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"comfort retained throughout")
 finish_cleanup()
func finish_cleanup() -> void:
 player.test_walk=Vector2.ZERO
 var report:={"checks":checks,"failures":failures,"distance_m":route_distance,"views":view_rows}
 FileAccess.open(output.path_join("walk-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF09_WALK ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
