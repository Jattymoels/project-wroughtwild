extends "res://tests/rf01/placement.gd"
func _ready() -> void:
 output = OS.get_environment("WROUGHTWILD_RF01_OUTPUT")
 set_physics_process(false)
 seed_controls = SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 _restore.call_deferred()

func _restore() -> void:
 var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
 var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("private-world.json")))
 if not check(seed_controls.continue_saved(),"ordinary Continue handler loads the paid private world"): return _finish_restore()
 quiet()
 check(terrain.reclaimed_cover!=null and world_seed==77 and world_profile=="frontier_v6","Continue selects the same production RF01 path and world")
 for origin: Vector2i in fixture_origins: terrain.ensure_area(Vector3(origin.x+8,32,origin.y+8),16)
 await get_tree().process_frame
 quiet()
 var manager := SaveManager.new()
 var restored: Dictionary = JSON.parse_string(JSON.stringify(manager.capture(player),"",true,true))
 FileAccess.open(output.path_join("restored-capture.json"),FileAccess.WRITE).store_string(JSON.stringify(restored,"\t"))
 check(_sim().export_json()==saved.sim,"exact native possessions and progression survive fresh-process Continue")
 for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops","broken_blocks"]:
  check(restored.get(key,[])==saved.get(key,[]),"exact saved ownership: "+key)
 check(hash(terrain.map.heights)==int(expected.height_digest),"saved world keeps its native height field")
 check(hash(snapshot())==int(expected.cover_digest) and hidden_count()==int(expected.hidden),"Continue restores exact cover transforms and paid floor/station suppression")
 var saved_cover := snapshot()
 StrangeSites.refresh_buildings(self,terrain)
 check(snapshot()==saved_cover,"post-Continue cover already agrees with full ownership refresh")
 player.set_physics_process(true)
 for i in 20: await get_tree().physics_frame
 check(player.is_on_floor(),"Continue places the real player on physical support")
 var direction := Vector3.ZERO
 for candidate in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
  if not player.test_move(player.global_transform,candidate): direction=candidate; break
 check(direction!=Vector3.ZERO,"saved work area has an ordinary clear step")
 var began := player.position
 player.rotation.y=0
 player.test_walk=Vector2(direction.x,direction.z)
 for i in 10: await get_tree().physics_frame
 player.test_walk=Vector2.ZERO
 check(player.position.distance_to(began)>.25,"real controller walks after Continue")
 quiet()
 check(manager.write(output.path_join("resaved-world.json"),player),"ordinary resave succeeds")
 _finish_restore()

func _finish_restore() -> void:
 var report := {"checks":checks,"failures":failures,"scope":"One fresh-process ordinary Continue of the same private paid V6 world; exact ownership, cover and short real controller movement."}
 FileAccess.open(output.path_join("continue-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF01_CONTINUE ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)