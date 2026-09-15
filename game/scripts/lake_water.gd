class_name LakeWater
extends RefCounted
## Immutable generated bounds + current solid terrain. Never a flooded column.
static func column(map: Dictionary, x: float, z: float) -> Dictionary:
 for lake: Dictionary in map.get("lakes",[]):
  var ix := floori(x)-int(lake.min_x)
  var iz := floori(z)-int(lake.min_z)
  if ix<0 or iz<0 or ix>=int(lake.width) or iz>=int(lake.height): continue
  var bed := float(lake.beds[iz*int(lake.width)+ix])
  if bed<float(lake.surface_y): return {"surface":float(lake.surface_y),"bed":bed,"depth":float(lake.surface_y)-bed,"id":lake.id}
 return {}

static func contact(terrain: Terrain, at: Vector3) -> Dictionary:
 if not is_instance_valid(terrain): return {}
 var p := terrain.to_local(at)
 var wet := column(terrain.map,p.x,p.z)
 if wet.is_empty() or p.y<float(wet.bed)-0.01 or p.y>float(wet.surface)+0.08: return {}
 if terrain.block_at(floori(p.x),floori(p.y),floori(p.z))!=0: return {}
 # A solid cap (including a raised bank) cuts contact off from the surface.
 for y in range(floori(p.y)+1,ceili(float(wet.surface))):
  if terrain.block_at(floori(p.x),y,floori(p.z))!=0:return {}
 wet.surface=float(wet.surface)+terrain.global_position.y
 wet.bed=float(wet.bed)+terrain.global_position.y
 return wet

static func terrain_for(node: Node) -> Terrain:
 var player: Node = node.get_tree().get_first_node_in_group("player")
 if player==null:return null
 return player.world_root().get_node_or_null("Terrain") as Terrain

## Keep a fallen item locally reachable without touching its age or contents.
static func landing(node: Node3D) -> float:
 var ground := terrain_for(node)
 if ground==null:return NAN
 var wet := contact(ground,node.global_position)
 if wet.is_empty():return NAN
 # Do not lift a drop through a paid slab/wall. The water query handles native
 # solids; this short ray adds the existing physical building bodies.
 var ray := PhysicsRayQueryParameters3D.create(node.global_position+Vector3.UP*.03,Vector3(node.global_position.x,float(wet.surface)+.12,node.global_position.z),1)
 if node is CollisionObject3D:ray.exclude=[node.get_rid()]
 if not node.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():return NAN
 return float(wet.surface)+.06

static func build_chunk(terrain: Terrain, chunk: Node3D, data: Dictionary) -> void:
 if terrain.map.get("lakes",[]).is_empty():return
 var st := SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var count := 0
 for z in range(int(data.z),mini(int(data.z)+Terrain.CHUNK_CELLS,int(terrain.map.height))):
  for x in range(int(data.x),mini(int(data.x)+Terrain.CHUNK_CELLS,int(terrain.map.width))):
   var wet := contact(terrain,terrain.to_global(Vector3(x+.5,float(column(terrain.map,x+.5,z+.5).get("surface",-100)),z+.5)))
   if wet.is_empty():continue
   var y := float(wet.surface)-terrain.global_position.y
   var depth := clampf(float(wet.depth)/4.0,0,1)
   for uv: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
    st.set_normal(Vector3.UP)
    st.set_color(Color(depth,0,0,1))
    st.add_vertex(Vector3(x+uv.x,y,z+uv.y))
   count+=1
 if count==0:return
 var water := MeshInstance3D.new()
 water.name="LakeWater"
 water.mesh=st.commit()
 var material := ShaderMaterial.new()
 material.shader=preload("res://art/lake_water.gdshader")
 water.material_override=material
 water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 chunk.add_child(water)
