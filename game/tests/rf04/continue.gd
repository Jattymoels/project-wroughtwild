extends "res://tests/rf03/build.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF04_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"904",output.path_join("private-world.json"))
 _restore.call_deferred()
func _restore() -> void:
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("private-world.json")))
 if not check(seed_controls.continue_saved(),"ordinary fresh-process Continue restores the private paid world"): return complete()
 quiet()
 var home:=select_home()
 terrain.ensure_area(Vector3(home.x,home.y,home.z),40)
 await get_tree().physics_frame
 quiet()
 var restored: Dictionary=JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
 check(world_profile=="frontier_v7" and world_seed==77,"Continue restores saved identity before generation despite chooser seed 904")
 check(_sim().export_json()==saved.sim,"exact native possessions/progression restored")
 for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops","broken_blocks"]:
  check(restored.get(key,[])==saved.get(key,[]),"exact saved ownership: "+key)
 check(restored.blocks.size()==9 and restored.stations.size()==1,"paid octagon and station survived")
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
 check(hash(terrain.map.heights)==int(expected.height_digest),"saved V7 geography matches before digging overlays")
 var dug: Array=expected.dug
 check(terrain.block_at(dug[0],dug[1],dug[2])==0,"local dig survives Continue")
 var local:=snapshot()
 StrangeSites.refresh_buildings(self,terrain)
 check(snapshot()==local and hidden_count()>0,"paid grass clearance restores exactly")
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built:
   node.interact(player)
   check(player.work_panel.is_open(),"restored station is usable")
   player.work_panel.close_panel()
 player.set_physics_process(true)
 for i in 30: await get_tree().physics_frame
 check(player.is_on_floor(),"Continue restores real floor contact")
 var start:=player.position
 player.rotation.y=0
 player.test_walk=Vector2(0,-1)
 for i in 16: await get_tree().physics_frame
 player.test_walk=Vector2.ZERO
 check(player.position.distance_to(start)>.6,"Continue restores real movement")
 quiet()
 check(SaveManager.new().write(output.path_join("resaved-world.json"),player),"private ordinary resave succeeds")
 # Fresh local excavation uses the corrected triangles without touching the retained fixture.
 var new_dig:=Vector3i(int(home.x)+10,int(home.y)-1,int(home.z)+9)
 check(terrain.break_block(new_dig.x,new_dig.y,new_dig.z)!="","Continue permits another ordinary local dig")
 await get_tree().physics_frame
 quiet()
 check(terrain.block_at(new_dig.x,new_dig.y,new_dig.z)==0,"Continue local dig changes the actual support cell")
 var roots:=0
 var root_error:=0.0
 for row in poses():
  var at: Vector3=row.pose.origin
  var y: float=terrain.rendered_height(at.x,at.z,at.y)
  if is_finite(y):
   roots+=1
   root_error=maxf(root_error,absf(y-at.y-.025))
 check(roots>0 and root_error<.0001,"grass roots follow corrected ground with retained 2.5 cm embed")
 var workspaces: Dictionary=terrain.reclaimed_cover.workspace_index(terrain,StrangeSites._building_index(terrain))
 var cover_clear:=true
 for row in poses():
  var bounds: AABB=row.pose*row.part.get_meta("clearance_bounds")
  if StrangeSites._building_overlap(workspaces,bounds):
   var transforms: Array=row.part.get_meta("world_transforms")
   # Dummy headless rendering does not retain MultiMesh buffers. Check the
   # exact CPU transforms submitted to it; walk.gd checks the real GPU buffer.
   var displayed: Array=row.part.get_meta("display_transforms")
   var index:=transforms.find(row.pose)
   if displayed[index].basis.determinant()!=0 or not row.part.get_meta("hidden_by_building")[index]:cover_clear=false
 check(cover_clear and hidden_count()>0,"paid octagonal floor and station footprints suppress grass")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"mouse remains free")
 complete()
func complete() -> void:
 var report:={"checks":checks,"failures":failures,"scope":"One private RF03 paid V7 Continue; exact ownership, paid floor movement, station use, retained and new dig, sampled grass roots and footprint clearance. Reuses RF03 acquisition/cost evidence."}
 FileAccess.open(output.path_join("continue-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF04_CONTINUE ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
