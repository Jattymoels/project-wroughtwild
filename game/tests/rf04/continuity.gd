extends Node3D
## One four-chunk patch. The inherited RF03 generator/cost evidence is reused.
var checks:=0
var failures:=0
var terrain: Terrain
var sim: WroughtwildSim
var original: Dictionary={}
var source: Dictionary={}
var output: String
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  printerr("FAIL RF04: ",label)
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF04_OUTPUT")
 sim=load("res://scripts/sim.gd").shared()
 check(sim.set_world_profile("frontier_v7"),"explicit V7 profile")
 terrain=Terrain.new()
 add_child(terrain)
 terrain._sim=sim
 terrain._seed=77
 terrain._world_profile="frontier_v7"
 terrain.map=sim.world_map(77)
 terrain._blocks=terrain.map.blocks.duplicate()
 terrain.block_rules=sim.block_rules()
 terrain.faceted_surface=true
 terrain.frontier_look=preload("res://art/wildland_look.tres")
 # No habitat expansion is needed in this geometry-only fixture.
 terrain._habitat_refresh_queued=true
 run.call_deferred()
func cell_faces(data: Dictionary) -> Dictionary:
 var result: Dictionary={}
 var faces: PackedVector3Array=data.faces
 for i in data.source_cells.size():
  var cell: Vector3=data.source_cells[i]
  if not result.has(cell):result[cell]=PackedVector3Array()
  var row: PackedVector3Array=result[cell]
  row.append_array(faces.slice(i*3,i*3+3))
  result[cell]=row
 return result
func current_patch() -> Dictionary:
 var result: Dictionary={}
 for z in [496,512]:
  for x in [560,576]:
   var d: Dictionary=sim.world_mesh_chunk(77,16,x,z,terrain.broken_packed(),true)
   result.merge(cell_faces(d))
 return result
func ray(at: Vector3) -> Dictionary:
 var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*3,at-Vector3.UP*3)
 return get_world_3d().direct_space_state.intersect_ray(query)
func run() -> void:
 var before: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("cause-before.json")))
 check(hash(terrain.map.heights)==int(before.height_digest),"native V7 heights identical to inherited DLL")
 check(hash(terrain.map.blocks)==int(before.block_digest),"native V7 block geography identical to inherited DLL")
 for z in [496,512]:
  for x in [560,576]:
   var d: Dictionary=sim.world_mesh_chunk(77,16,x,z,PackedInt32Array(),true)
   original[Vector2i(x,z)]=d.faces
   source.merge(cell_faces(d))
   check(d.source_cells.size()*3==d.faces.size(),"each collision triangle retains source cell")
   terrain._build_chunk(d,1.0)
   var chunk: Node3D=terrain.chunks["%d_%d"%[x,z]]
   var shape: ConcavePolygonShape3D=chunk.get_node("ChunkBody").get_child(0).shape
   check(shape.get_faces()==d.faces,"published collider uses the exact mesher faces")
   var rendered:=0
   for node in chunk.get_children():
    if node is MeshInstance3D:
     var vertices: PackedVector3Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
     check(vertices in d.surfaces.values(),"published mesh uses exact same face vertices")
     rendered+=vertices.size()
   check(rendered==d.faces.size(),"complete rendered and collision triangle coverage")
 var max_error:=0.0
 var matched:=0
 for face: Dictionary in before.faces:
  var c: Array=face.cell
  var cell:=Vector3(c[0],c[1],c[2])
  var mean:=Vector3.ZERO
  for v: Array in face.corners:mean+=Vector3(v[0],v[1],v[2])/float(face.corners.size())
  var vertices: PackedVector3Array=source[cell]
  var nearest:=INF
  for i in range(0,vertices.size(),3):nearest=minf(nearest,vertices[i].distance_to(mean))
  max_error=maxf(max_error,nearest)
  if nearest<.0001:matched+=1
 check(matched==before.faces.size(),"all 135 measured top centres follow their unchanged corners")
 check(source==cell_faces(sim.world_mesh_chunk(77,32,560,496,PackedInt32Array(),true)),"four chunks exactly match contiguous patch, including shared borders")
 var cell:=Vector3i(575,terrain.height_at(575,511)-1,511)
 var at:=Vector3(cell)+Vector3(.5,1,.5)
 for i in 3:await get_tree().physics_frame
 var hit:=ray(at)
 check(not hit.is_empty(),"changed slope has actual collision")
 if not hit.is_empty():
  check(terrain.block_from_surface_hit(hit)==cell,"actual triangle hit maps to the correct top source cell")
  check(absf(terrain.rendered_height(at.x,at.z,at.y)-hit.position.y)<.0001,"ground sampler agrees with actual collider")
 check(terrain._touched_chunk_origins(cell.x,cell.z).size()==4,"corner dig invalidates four bounded chunks")
 check(terrain.break_block(cell.x,cell.y,cell.z)!="","ordinary source-cell dig succeeds")
 check(terrain.block_at(cell.x,cell.y,cell.z)==0,"dug source cell is air")
 for i in 3:await get_tree().physics_frame
 var dug_hit:=ray(at)
 check(not dug_hit.is_empty() and dug_hit.position.y<hit.position.y-.1,"dig opens real lower collision instead of a cosmetic hole")
 if not dug_hit.is_empty():
  var selected:=terrain.block_from_surface_hit(dug_hit)
  check(selected!=cell and terrain.block_at(selected.x,selected.y,selected.z)!=0,"hole hit maps to next solid source cell")
  check(absf(terrain.rendered_height(at.x,at.z,dug_hit.position.y)-dug_hit.position.y)<.0001,"sampler follows dug collision")
 check(current_patch()==cell_faces(sim.world_mesh_chunk(77,32,560,496,terrain.broken_packed(),true)),"dig refresh remains identical across the four chunk borders")
 terrain.apply_broken_blocks([])
 for i in 3:await get_tree().physics_frame
 for origin: Vector2i in original:
  var chunk: Node3D=terrain.chunks["%d_%d"%[origin.x,origin.y]]
  var shape: ConcavePolygonShape3D=chunk.get_node("ChunkBody").get_child(0).shape
  check(shape.get_faces()==original[origin],"restoration returns exact corrected collision")
 check(terrain.block_from_surface_hit(ray(at))==cell,"restored top maps back to original source cell")
 var report:={"checks":checks,"failures":failures,"profile":"frontier_v7","seed":77,"top_faces":matched,"max_centre_error_m":max_error,"height_digest":hash(terrain.map.heights),"block_digest":hash(terrain.map.blocks),"dug":[cell.x,cell.y,cell.z],"scope":"One adjacent-cell patch, four chunk joins, actual ray/sampler/source-cell dig and restoration; same native geography as RF03."}
 FileAccess.open(output.path_join("continuity-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF04_CONTINUITY ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
