extends "res://tests/land04/use.gd"
## Corrects the one observed White route failure while preserving the completed
## paid-use checkpoint and its 183/184 result. No source work is replayed here.
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND04_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("route-world.json"))
 player.class_panel.choose("warden")
 run.call_deferred()

func physical_journeys(value: Array) -> Array:
 # Normalize Vector3/PackedVector3Array and number representations exactly as
 # generation-checks.json was written, then exclude route metadata only.
 var result: Array=JSON.parse_string(JSON.stringify(value))
 for row: Dictionary in result:
  row.erase("approach");row.erase("source_route");row.erase("host_route")
 return result

func run() -> void:
 var checkpoint_path:=output.path_join("private-world.json")
 var expected_path:=output.path_join("expected.json")
 var checkpoint_before:=FileAccess.get_file_as_bytes(checkpoint_path)
 var expected_before:=FileAccess.get_file_as_bytes(expected_path)
 if not check(not checkpoint_before.is_empty() and not expected_before.is_empty(),"completed paid-use checkpoint and expectation already exist"):return finish_job("corrected_route")
 var expected: Dictionary=JSON.parse_string(expected_before.get_string_from_utf8())
 var evidence: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("generation-checks.json")))
 var baseline: Dictionary={}
 for record: Dictionary in evidence.records:
  if int(record.seed)==77:baseline=record;break
 if not check(not baseline.is_empty(),"retained original seed77 generation evidence exists"):return finish_job("corrected_route")
 if not await started():return finish_job("corrected_route")
 check(hash(terrain.map.heights)==int(baseline.height_hash) and hash(terrain.map.blocks)==int(baseline.blocks_hash) and hash(terrain.map.heights)==int(expected.height_hash),"route-only correction keeps exact original V12 heights and every terrain block")
 check(physical_journeys(journeys)==physical_journeys(baseline.journeys),"every original source/host/reveal/kit anchor and physical journey field is unchanged; only three route fields may differ")
 var host_ids:=[]
 for host: Dictionary in terrain.map.frontier_hosts:host_ids.append(host.id)
 check(host_ids==baseline.finite_host_ids,"all original finite host owners retain their IDs and ordering")
 var source_nodes: Array[LeylineSource]=[]
 for id in ["red_home_margin","white_home_margin","blue_home_margin","green_home_margin"]:
  var node:=source(id)
  if node!=null:source_nodes.append(node)
 check(source_nodes.size()==4,"four real source collision bodies remain separate owners")
 var capsule: CapsuleShape3D=(player.get_node("CollisionShape3D") as CollisionShape3D).shape
 var checked_segments:=0
 for row: Dictionary in journeys:
  if row.secondary:continue
  var route: PackedVector3Array=row.source_route
  var clear:=route.size()>1
  check(clear and route[0]==row.reveal and route[-1]==row.work_stance,row.channel+" local route still starts at its original reveal and ends at its safe stance")
  for node: LeylineSource in source_nodes:
   var half: Vector3=LeylineSource.LOOK.bounds*.5+Vector3(capsule.radius,0,capsule.radius)
   var footprint:=AABB(Vector3(node.global_position.x-half.x,-1,node.global_position.z-half.z),Vector3(half.x*2,2,half.z*2))
   for i in range(1,route.size()):
    var a:=Vector3(route[i-1].x,0,route[i-1].z)
    var b:=Vector3(route[i].x,0,route[i].z)
    checked_segments+=1
    if footprint.intersects_segment(a,b)!=null:
     clear=false
     print("LAND04_ROUTE_COLLISION ",row.channel," segment=",i," source=",node.source_id," from=",a," to=",b)
     break
  check(clear,row.channel+" complete local approach clears all four source collision footprints including real capsule radius")
 if failures>0:return finish_job("corrected_route",{"segments_checked":checked_segments,"checkpoint_updated":false})
 # Final presentation uses the corrected source reservations and final host
 # kit; only the previously blocked White controller route is replayed.
 for channel in ["blue","white","green"]:
  await journey_picture(journey(channel),channel+"-final")
 await journey_picture(journey("green",true),"green-steppe-final")
 await walk_journey(journey("white"))
 check(FileAccess.get_file_as_bytes(checkpoint_path)==checkpoint_before,"corrected White controller check leaves the completed paid-use checkpoint byte-for-byte unchanged")
 check(FileAccess.get_file_as_bytes(expected_path)==expected_before,"all prior expected paid/save evidence remains untouched before validated route-hash refresh")
 if failures>0:return finish_job("corrected_route",{"segments_checked":checked_segments,"checkpoint_updated":false})
 var backup_path:=output.path_join("expected-before-routefix.json")
 if FileAccess.file_exists(backup_path):
  if not check(FileAccess.get_file_as_bytes(backup_path)==expected_before,"existing original expectation backup is the exact pre-correction input"):return finish_job("corrected_route")
 else:
  var backup:=FileAccess.open(backup_path,FileAccess.WRITE)
  if not check(backup!=null,"original expectation backup is writable"):return finish_job("corrected_route")
  backup.store_buffer(expected_before);backup.close()
 check(FileAccess.get_file_as_bytes(backup_path)==expected_before,"original full expectation bytes preserved as expected-before-routefix.json")
 if failures>0:return finish_job("corrected_route")
 var before_hash:=int(expected.journey_hash)
 var revised:=expected.duplicate(true)
 revised.journey_hash=hash(journeys)
 var comparison:=revised.duplicate(true);comparison.journey_hash=expected.journey_hash
 if not check(comparison==expected,"only the expected journey hash is changed after physical identity and White route pass"):return finish_job("corrected_route")
 var file:=FileAccess.open(expected_path,FileAccess.WRITE)
 if not check(file!=null,"validated route expectation is writable"):return finish_job("corrected_route")
 file.store_string(JSON.stringify(revised,"\t"));file.close()
 # Godot parses every JSON number as float; revised.journey_hash is an int
 # returned by hash(). Compare equal JSON representations on both sides.
 check(JSON.parse_string(FileAccess.get_file_as_string(expected_path))==JSON.parse_string(JSON.stringify(revised)) and FileAccess.get_file_as_bytes(checkpoint_path)==checkpoint_before,"refreshed full route hash saved; paid-use checkpoint remains exact")
 finish_job("corrected_route",{"segments_checked":checked_segments,"checkpoint_updated":false,"expected_journey_hash_updated":true,"prior_journey_hash":before_hash,"final_journey_hash":hash(journeys),"checkpoint_sha256":FileAccess.get_sha256(checkpoint_path),"reason":"Only route metadata changed to avoid the solid source footprint. Exact terrain and all non-route journey fields passed against retained original seed77 evidence; corrected White controller route passed. Existing paid source/host/device/build/edit evidence and original 183/184 run are reused unchanged."})