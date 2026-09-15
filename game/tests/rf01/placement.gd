extends Sandpit
const RF = preload("res://rf01/cover.gd")
var checks := 0
var failures := 0
var output: String
var samples: Array[Dictionary] = []
var fixture_origins := [Vector2i(384,432),Vector2i(400,432),Vector2i(416,432)]

func check(ok: bool, label: String) -> bool:
 checks += 1
 if not ok:
  failures += 1
  printerr("FAIL RF01: ",label)
 return ok

func _ready() -> void:
 output = OS.get_environment("WROUGHTWILD_RF01_OUTPUT")
 set_physics_process(false)
 seed_controls = SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 player.class_panel.choose("warden")
 _run.call_deferred()

func quiet() -> void:
 for node in [self,player,player.placement,player.combat,mob_packs]:
  node.set_physics_process(false)
 mob_packs.set_process(false)
 terrain.set_process(false)
 for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)

func snapshot() -> Dictionary:
 var result := {}
 for origin: Vector2i in fixture_origins:
  var key := "%d_%d"%[origin.x,origin.y]
  var chunk: Node3D = terrain.chunks.get(key)
  if chunk==null: continue
  for part in chunk.get_children():
   if part.has_meta("rf01_cover"):
    result[key+"/"+String(part.name)] = [part.get_meta("world_transforms").duplicate(),part.get_meta("display_transforms").duplicate(),part.get_meta("hidden_by_building").duplicate()]
 return result

func poses() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for origin: Vector2i in fixture_origins:
  var chunk: Node3D = terrain.chunks.get("%d_%d"%[origin.x,origin.y])
  if chunk==null: continue
  for part in chunk.get_children():
   if not part.has_meta("rf01_cover"): continue
   for pose: Transform3D in part.get_meta("world_transforms"):
    result.append({"pose":pose,"part":part,"chunk":chunk})
 return result

func hidden_count() -> int:
 var count := 0
 for row: Array in snapshot().values():
  for hidden in row[2]:
   if hidden: count += 1
 return count

func place(shape: StringName, at: Vector3i, turn := 0, kit := false) -> bool:
 var build := player.placement
 build.set_build_mode_enabled(true)
 if kit: build._select_kit(shape)
 else: build.select_shape(shape)
 build.selected_material_family = &"wood"
 build.preview_rotation_step = turn
 build.preview_element = {"kind":"volume" if kit else "face","axis":0 if kit else 1,"cell":at*2}
 build.preview_visible = true
 var made := build.try_place_block()
 if not made: printerr("RF01 placement reason: ",build.preview_reason)
 build.set_build_mode_enabled(false)
 return made

func _gather() -> void:
 # Acquisition is harness-paced; native finite work and pickup payment are real.
 for attempt in 100:
  if _sim().material_count("wood")>=32: break
  var nearest := ""
  var distance := INF
  for id in terrain.resource_stream.records:
   var r: Dictionary = terrain.resource_stream.records[id]
   if r.family!="wood" or int(r.remaining_units)<=0 or int(r.get("era",1))>1: continue
   var p: Array = r.position
   var d := Vector3(p[0],p[1],p[2]).distance_squared_to(player.spawn_position)
   if d<distance: distance=d; nearest=id
  if nearest.is_empty(): break
  var node: ResourceNode = terrain.resource_stream.materialise(nearest)
  player.position = node.position+Vector3(0,1.1,1.4)
  var result := node.work(_sim())
  if result.has("refusal"):
   printerr("RF01 acquisition refusal: ",result)
   terrain.resource_stream.capture()
   continue
  player._apply_work(node,result)
  for pickup in get_tree().get_nodes_in_group("pickups"):
   if pickup.is_queued_for_deletion(): continue
   player.position = pickup.global_position-Vector3(0,.6,0)
   for tick in 12:
    if pickup.is_queued_for_deletion(): break
    player.position = pickup.global_position-Vector3(0,.6,0)
    pickup._physics_process(1.0/60.0)
  await get_tree().process_frame
  terrain.resource_stream.capture()
 terrain.resource_stream.capture()
 print("RF01 gathered wood: ",_sim().material_count("wood"))
 check(_sim().material_count("wood")>=32,"generated wood work and ordinary pickups fund the paid fixture")

func _flat_clear_target(rows: Array[Dictionary], gap: float, avoid := Vector3.INF) -> Vector3i:
 var build := player.placement
 build.select_shape(&"floor_slab")
 for row in rows:
  var at: Vector3 = row.pose.origin
  if avoid.is_finite() and at.distance_to(avoid)<gap: continue
  var x := floori(at.x)
  var z := floori(at.z)
  var y := terrain.height_at(x,z)
  var valid := true
  for dx in range(-1,2):
   for dz in range(-1,2):
    if terrain.height_at(x+dx,z+dz)!=y: valid=false
    var e := {"kind":"face","axis":1,"cell":Vector3i(x+dx,y,z+dz)*2}
    if not build.element_refusal(e).is_empty(): valid=false
  if valid: return Vector3i(x,y,z)
 return Vector3i(-1,-1,-1)

func _run() -> void:
 while not seed_controls.finished: await get_tree().process_frame
 quiet()
 check(world_seed==77 and terrain.reclaimed_cover!=null,"ordinary chosen-seed New World installs RF01")
 for origin: Vector2i in fixture_origins: terrain.ensure_area(Vector3(origin.x+8,32,origin.y+8),16)
 await get_tree().physics_frame
 quiet()
 check(RF.eligible("frontier_v6","meadow","grass") and RF.eligible("living_frontier_wave1","forest","forest_floor") and RF.eligible("living_frontier_wave3","forest","grass"),"actual V6/LF geography identities select new dressing")
 check(not RF.eligible("frontier_v5","meadow","grass") and not RF.eligible("frontier_v6","fen","grass") and not RF.eligible("frontier_v6","forest","bedrock"),"excluded legacy/biome/rock selections retain old path")
 var initial := snapshot()
 var rows := poses()
 check(not rows.is_empty(),"production cover exists in the small boundary fixture")
 if rows.is_empty(): return finish()
 var fingerprint := hash(terrain.map.heights)
 if not OS.get_cmdline_user_args().has("--rf01-use-only"):
  # Independent collision rays at one ordinary plant root, plus a real slope.
  var slope: Dictionary = rows[0]
  for row in rows:
   if absf(row.pose.basis.x.y)+absf(row.pose.basis.z.y)>0.001:
    slope=row
    break
  var at: Vector3 = slope.pose.origin
  var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*.25))
  check(not hit.is_empty() and absf(hit.position.y-at.y-RF.SETTINGS.root_embed_m)<.004,"root plane matches actual collision support")
  check(absf(slope.pose.basis.x.y)+absf(slope.pose.basis.z.y)>0.001,"fixture includes supported sloping ground")
  for origin: Vector2i in fixture_origins: terrain._rebuild_chunk(origin.x,origin.y)
  await get_tree().process_frame
  quiet()
  check(snapshot()==initial,"unchanged chunks rebuild exact seeded transforms and visibility")
  # Reverse retirement/recreation exercises the boundary without relying on
  # whether the neighbour happened to be published first.
  for origin: Vector2i in fixture_origins: terrain._release_chunk(origin)
  for i in range(fixture_origins.size()-1,-1,-1):
   terrain._rebuild_chunk(fixture_origins[i].x,fixture_origins[i].y)
  await get_tree().process_frame
  quiet()
  check(snapshot()==initial,"reverse chunk arrival restores identical dressing")
  rows=poses()
  rows.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
   return absf(fmod(a.pose.origin.x,16.0)-15.5)<absf(fmod(b.pose.origin.x,16.0)-15.5))
  var root: Vector3=rows[0].pose.origin
  var dug := Vector3i(floori(root.x),terrain.height_at(floori(root.x),floori(root.z))-1,floori(root.z))
  check(dug.x%16==15,"real excavation fixture touches a chunk boundary")
  check(terrain.break_block(dug.x,dug.y,dug.z)!="","ordinary excavation removes actual native surface support")
  await get_tree().process_frame
  quiet()
  var lingering := false
  for row in poses():
   var p: Vector3 = row.pose.origin
   if floori(p.x)==dug.x and floori(p.z)==dug.z: lingering=true
  check(not lingering and terrain.block_at(dug.x,dug.y,dug.z)==0,"excavation cannot leave a grass lid or project onto a cave floor")
  # A synthetic ledge isolates missing-footprint support from the real dig.
  var faces := PackedVector3Array([Vector3(0,2,0),Vector3(1,2,0),Vector3(0,2,1),Vector3(1,2,0),Vector3(1,2,1),Vector3(0,2,1)])
  var sampler := SurfaceSampler.new(faces)
  check(terrain.reclaimed_cover.supported_pose(sampler,Vector3(.5,2,.5),Basis.IDENTITY,.4,1.0)!=null,"complete support admits the entire test footprint")
  check(terrain.reclaimed_cover.supported_pose(sampler,Vector3(.9,2,.5),Basis.IDENTITY,.4,1.0)==null,"a root-only ledge match cannot admit overhanging leaves")
  check(terrain.reclaimed_cover.supported_pose(sampler,Vector3(.5,8,.5),Basis.IDENTITY,.4,1.0)==null,"cover never searches down to a cave floor")
  terrain.apply_broken_blocks([])
  await get_tree().process_frame
  quiet()
  check(snapshot()==initial and hash(terrain.map.heights)==fingerprint,"restored excavation reproduces dressing and retains native heights")
 await _gather()
 quiet()
 player.position=player.spawn_position
 rows=poses()
 var target := _flat_clear_target(rows,0)
 check(target.x>=0,"existing flat covered ground fits a paid octagonal floor")
 if target.x<0: return finish()
 var wood := _sim().material_count("wood")
 var blocks: Array[PlacedBlock] = []
 for dx in range(-1,2):
  for dz in range(-1,2):
   var corner := absi(dx)==1 and absi(dz)==1
   var shape: StringName = &"codex_corner_floor" if corner else &"floor_slab"
   var turn := 0 if dx<0 and dz<0 else 1 if dx<0 else 2 if dz>0 else 3
   var before: int = _sim().structure_piece_count()
   check(place(shape,target+Vector3i(dx,0,dz),turn),"paid octagonal floor component")
   if _sim().structure_piece_count()>before:
    for node in get_children():
     if node is PlacedBlock and not blocks.has(node): blocks.append(node)
 await get_tree().process_frame
 quiet()
 check(_sim().material_count("wood")==wood-9 and blocks.size()==9,"octagonal floor consumes exactly nine wood")
 check(hidden_count()>0,"paid octagonal footprint hides overlapping moving cover")
 var oct_hidden := hidden_count()
 # Existing UI performs an ordinary affordable hand craft.
 player.work_panel.open_hand_crafting()
 var catalogue = player.work_panel.catalogue
 catalogue.select_recipe("workbench_kit")
 catalogue.quantity=1
 catalogue._render_detail()
 check(not catalogue._action.disabled,"hand crafting offers the funded bench kit")
 catalogue._action.pressed.emit()
 player.work_panel.close_panel()
 check(_sim().material_count("workbench_kit")==1,"ordinary craft produces one paid kit")
 var station_target := _flat_clear_target(rows,5,Vector3(target))
 check(station_target.x>=0,"nearby covered ground fits the station work area")
 if station_target.x<0: return finish()
 check(place(&"workbench_kit",station_target,1,true),"ordinary station placement consumes the kit")
 await get_tree().process_frame
 quiet()
 var station: StationSite
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built: station=node
 check(station!=null and _sim().material_count("workbench_kit")==0,"station has one paid physical owner")
 check(hidden_count()>oct_hidden,"station body and work margin clear RF cover")
 if station!=null:
  station.interact(player)
  check(player.work_panel.is_open(),"station remains usable")
  player.work_panel.close_panel()
 var local := snapshot()
 StrangeSites.refresh_buildings(self,terrain)
 check(snapshot()==local,"local placement suppression matches complete existing refresh")
 player.position=Vector3(station_target.x+2.5,station_target.y+1.0,station_target.z+2.5)
 player.velocity=Vector3.ZERO
 var manager := SaveManager.new()
 check(manager.write(output.path_join("private-world.json"),player),"save ordinary paid ownership and finite harvest state")
 var expected := {"fixture_origins":fixture_origins,"target":[target.x,target.y,target.z],"station_target":[station_target.x,station_target.y,station_target.z],"hidden":hidden_count(),"cover_digest":hash(snapshot()),"height_digest":fingerprint}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 for block in blocks:
  _sim().refund_removal(block.shape_id,block.material_family)
  check(player.placement.remove_piece(block),"ordinary removal restores the floor footprint")
 await get_tree().process_frame
 quiet()
 check(hidden_count()<int(expected.hidden),"removal restores supported cover beside the retained station")
 var after_remove := snapshot()
 StrangeSites.refresh_buildings(self,terrain)
 check(snapshot()==after_remove,"removal local refresh matches complete refresh")
 check(hash(terrain.map.heights)==fingerprint,"all cover/build work preserves native terrain")
 finish()

func finish() -> void:
 var report := {"checks":checks,"failures":failures,"use_only":OS.get_cmdline_user_args().has("--rf01-use-only"),"scope":"One native slope/boundary fixture, real excavation, paid octagonal floor/station, normal new-world creation and finite gathering. Acquisition/placement are harness-paced."}
 FileAccess.open(output.path_join("placement-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF01_PLACEMENT ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)