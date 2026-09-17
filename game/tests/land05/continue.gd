extends "res://tests/land04/common.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND05_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"990",output.path_join("private-world.json"))
 run.call_deferred()
func canonical_stations(input: Array) -> Array[String]:
 var result: Array[String]=[]
 for row: Dictionary in input:
  var copy:=row.duplicate(true);copy.name=String(copy.name).replace("@","_")
  result.append(JSON.stringify(copy,"",true,true))
 result.sort();return result
func run() -> void:
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("private-world.json")))
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
 var manager:=SaveManager.new()
 if not check(seed_controls.continue_saved(),"fresh-process actual Continue succeeds"):return finish_job("continue")
 quiet();freeze_fixtures()
 check(world_profile=="frontier_v13" and world_seed==77,"Continue selects saved profile/seed")
 check(hash(terrain.map.heights)==int(expected.height_hash) and hash(terrain.map.force_journeys)==int(expected.journey_hash),"exact V13 terrain and force/host relationships reconstruct")
 var restored: Dictionary=JSON.parse_string(JSON.stringify(manager.capture(player),"",true,true))
 for key in ["sim","leylines","contraptions","blocks","broken_blocks","resource_nodes","world_drops"]:
  check(restored.get(key)==saved.get(key),"exact restored "+key)
 check(canonical_stations(restored.stations)==canonical_stations(saved.stations),"station identities/positions/payments exact")
 check(source("blue_home_margin").state().work==1 and source("green_home_margin").state().claim.get("green_resin",0)==16,"partial work and outstanding claim retain distinct owners")
 var ledger:=_sim().contraption_save()
 var source_ledger:=_sim().leyline_save()
 for id: String in expected.host_ids:
  check(_sim().world_effect_active("host_defeated:"+id),"finite host death ownership restores: "+id)
  for pack: Dictionary in mob_packs.packs:
   if pack.get("frontier_host_id","")==id:
    mob_packs._spawn_pack(pack,mob_packs.pack_position(pack));check(pack.members.is_empty(),"Continue cannot respawn finite host: "+id)
 var cell:=Vector3i(expected.dug[0],expected.dug[1],expected.dug[2])
 check(terrain.block_at(cell.x,cell.y,cell.z)==0,"saved picked terrain owner remains excavated")
 var corruptions:=[]
 var bad:=saved.duplicate(true);bad.erase("leylines");corruptions.append(bad)
 bad=saved.duplicate(true);bad.erase("contraptions");corruptions.append(bad)
 bad=saved.duplicate(true);bad.world_seed=78;corruptions.append(bad)
 bad=saved.duplicate(true);bad.world_profile="frontier_v12";corruptions.append(bad)
 bad=saved.duplicate(true)
 var payload: Dictionary=JSON.parse_string(saved.leylines);payload.sources.erase("green_home_margin");bad.leylines=JSON.stringify(payload);corruptions.append(bad)
 bad=saved.duplicate(true);payload=JSON.parse_string(saved.leylines);payload.sources["extra_owner"]={};bad.leylines=JSON.stringify(payload);corruptions.append(bad)
 bad=saved.duplicate(true);payload=JSON.parse_string(saved.leylines);payload.profile="frontier_v12";bad.leylines=JSON.stringify(payload);corruptions.append(bad)
 bad=saved.duplicate(true);payload=JSON.parse_string(saved.contraptions);payload.world_profile="frontier_v12";bad.contraptions=JSON.stringify(payload);corruptions.append(bad)
 for rejected: Dictionary in corruptions:
  check(not manager.apply(player,rejected) and _sim().leyline_save()==source_ledger and _sim().contraption_save()==ledger and _sim().export_json()==saved.sim and world_profile=="frontier_v13","invalid/missing/wrong-world owners reject before live mutation")
 # The single final White foliage correction is cosmetic; reuse the passed
 # controller walk and inspect its actual emitted forms during this Continue.
 journeys=terrain.map.force_journeys
 await journey_picture(journey("white"),"white")
 # One V12 and one LF payload exercise changed restore dispatch only. Earlier
 # generation/campaign/body evidence is reused; no full old-profile play replay.
 for profile in ["frontier_v12","living_frontier_wave3"]:
  var older:=WroughtwildSim.new();older.load_tuning(load("res://scripts/sim.gd").get_tuning_directory());older.set_world_profile(profile)
  var map: Dictionary=older.world_map(77)
  older.contraption_bind_world(profile,77);older.leyline_bind_world(profile,77)
  older.leyline_work("white_home_margin")
  var snapshot:={"schema_version":SaveManager.SCHEMA_VERSION,"world_seed":77,"world_profile":profile,"sim":older.export_json(),"contraptions":older.contraption_save(),"leylines":older.leyline_save(),"player":{"position":[map.spawn_x,map.heights[int(map.spawn_z)*int(map.width)+int(map.spawn_x)]+1,map.spawn_z],"yaw":0,"pitch":0},"blocks":[],"stations":[],"resource_nodes":[],"world_drops":{"version":1,"pickups":[],"bundles":[]}}
  check(manager.apply(player,snapshot),profile+" existing Continue identity works: "+manager.last_error)
  quiet();freeze_fixtures()
  check(world_profile==profile and _sim().contraption_save()==older.contraption_save() and _sim().leyline_save()==older.leyline_save(),profile+" retains exact saved owners without migration")
 finish_job("continue")
