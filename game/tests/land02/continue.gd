extends "res://tests/land02/early.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND02_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"904",output.path_join("private-world.json"))
 restore_run.call_deferred()
func restore_run() -> void:
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("private-world.json")))
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
 var manager:=SaveManager.new()
 if not check(seed_controls.continue_saved(),"fresh-process normal Continue"):return finish_restore()
 quiet()
 for n in get_tree().get_nodes_in_group("contraptions"):n.set_physics_process(false)
 check(world_profile=="frontier_v9" and world_seed==77,"saved identity overrides fresh seed/profile choice")
 check(hash(terrain.map.heights)==int(expected.height_hash) and hash(terrain.map.scarwater[0])==int(expected.place_hash),"exact saved-profile geography and place relationships regenerate")
 check(_sim().export_json()==saved.sim,"progression and paid possessions remain exact")
 var restored: Dictionary=JSON.parse_string(JSON.stringify(manager.capture(player),"",true,true))
 for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops","broken_blocks"]:
  var same: bool=restored.get(key,[])==saved.get(key,[])
  if key=="stations":
   # Scene insertion order is not station ownership; compare every complete
   # record as an unordered collection, retaining keys, poses and paid flags.
   same=canonical_rows(restored.stations)==canonical_rows(saved.stations)
   FileAccess.open(output.path_join("stations-restore.json"),FileAccess.WRITE).store_string(JSON.stringify({"saved":saved.stations,"restored":restored.stations},"\t",true,true))
  check(same,"exact restored owner: "+key)
 var cell:=Vector3i(expected.dug[0],expected.dug[1],expected.dug[2])
 check(terrain.block_at(cell.x,cell.y,cell.z)==0,"actual scar-floor excavation restored")
 check(_sim().contraption_pressure_sources()[0].remaining==20,"spent source never refills on Continue")
 var feeder:=ContraptionSite.find_site(get_tree(),expected.feeder)
 check(feeder!=null and PressurePocket.find_source(get_tree(),_sim().contraption_state(expected.feeder).source_id)!=null,"saved feeder still resolves the original source")
 # Missing/wrong world ownership must reject before changing any live state.
 var ledger:=_sim().contraption_save()
 var rejected:=saved.duplicate(true);rejected.erase("contraptions")
 check(not manager.apply(player,rejected) and _sim().contraption_save()==ledger,"missing finite ledger cannot initialise another source")
 rejected=saved.duplicate(true);rejected.world_seed=78
 check(not manager.apply(player,rejected) and _sim().contraption_save()==ledger,"wrong-world source ownership rejected atomically")
 var scar: Vector3=terrain.map.scarwater[0].scar
 ready_at(scar+Vector3(1.5,2,0));terrain.set_process(true)
 for i in 25:await tick()
 check(player.is_on_floor() and player.position.y<scar.y+1.6,"restored native recess supplies real player contact")
 var pick_at:=scar+Vector3(1.1,0,.2)
 var query:=PhysicsRayQueryParameters3D.create(pick_at+Vector3.UP*3,pick_at-Vector3.UP*2)
 query.exclude=[player]
 var hit:=get_world_3d().direct_space_state.intersect_ray(query)
 check(not hit.is_empty() and terrain.is_terrain_body(hit.get("collider")),"restored floor has real terrain ray contact")
 if not hit.is_empty():
  var picked:=terrain.block_from_surface_hit(hit)
  check(terrain.block_at(picked.x,picked.y,picked.z)!=0,"continuous collision triangle picks its exact remaining native solid")
 var pulse_ok:=true
 for chunk in terrain.chunks.values():
  for part in chunk.get_children():
   if String(part.name)!="Scarwater_inset_pulse":continue
   for pose: Transform3D in part.get_meta("world_transforms",[]):
    if floori(pose.origin.x)==cell.x and floori(pose.origin.z)==cell.z:pulse_ok=false
 check(pulse_ok,"removed floor cell has no unsupported decorative pulse")
 quiet()
 # One V8 fixture checks changed dispatch/guards; immutable generation matrices
 # and prior gameplay evidence are deliberately not replayed.
 var older:=WroughtwildSim.new()
 check(older.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()) and older.set_world_profile("frontier_v8"),"existing V8 still loads")
 var old_map: Dictionary=older.world_map(77)
 older.contraption_bind_world("frontier_v8",77);older.leyline_bind_world("frontier_v8",77)
 var old_save: Dictionary={"schema_version":SaveManager.SCHEMA_VERSION,"world_seed":77,"world_profile":"frontier_v8","sim":older.export_json(),"contraptions":older.contraption_save(),"leylines":older.leyline_save(),"player":{"position":[old_map.spawn_x,old_map.heights[int(old_map.spawn_z)*int(old_map.width)+int(old_map.spawn_x)]+1,old_map.spawn_z],"yaw":0,"pitch":0},"blocks":[],"stations":[],"resource_nodes":[],"world_drops":{"version":1,"pickups":[],"bundles":[]}}
 check(manager.apply(player,old_save),"one existing-profile save restores: "+manager.last_error)
 quiet()
 check(world_profile=="frontier_v8" and terrain.map.get("scarwater",[]).is_empty() and hash(terrain.map.heights)==hash(old_map.heights),"V8 Continue keeps V8 geography with no Scarwater migration")
 check(_sim().contraption_save()==older.contraption_save(),"V8 finite owner preserved")
 finish_restore()
func finish_restore() -> void:
 FileAccess.open(output.path_join("continue-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
 print("LAND02_CONTINUE ",checks," checks / ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)

func canonical_rows(input: Array) -> Array[String]:
 var result: Array[String]=[]
 for row: Dictionary in input:
  var record:=row.duplicate(true)
  # Godot sanitises its autogenerated @ names on explicit restore assignment.
  # station_key remains the exact persistent owner and every other field stays.
  record.name=String(record.name).replace("@","_")
  result.append(JSON.stringify(record,"",true,true))
 result.sort()
 return result
