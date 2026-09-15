extends "res://tests/rf04/continuity.gd"
## Bounded follow-up of the exact stopped walk; terrain and nearby native props.
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF04_OUTPUT")
 sim=load("res://scripts/sim.gd").shared()
 assert(sim.set_world_profile("frontier_v7"))
 terrain=Terrain.new()
 terrain.name="Terrain"
 add_child(terrain)
 terrain._sim=sim
 terrain._seed=77
 terrain._world_profile="frontier_v7"
 terrain.map=sim.world_map(77)
 terrain._blocks=terrain.map.blocks.duplicate()
 terrain.block_rules=sim.block_rules()
 terrain.faceted_surface=true
 terrain.frontier_look=preload("res://art/wildland_look.tres")
 terrain._habitat_refresh_queued=true
 inspect.call_deferred()
func inspect() -> void:
 for z in [496,512]:
  for x in [544,560]:terrain._build_chunk(sim.world_mesh_chunk(77,16,x,z,PackedInt32Array(),true),1.0)
 var player: WroughtwildPlayer=preload("res://scenes/player.tscn").instantiate()
 add_child(player)
 player.class_panel.choose("warden")
 player.set_physics_process(false)
 player._terrain=terrain
 var stopped:=Vector3(557.74396,27.12235,511.91037)
 player.position=stopped
 for i in 3:await get_tree().physics_frame
 var hit:=KinematicCollision3D.new()
 if player.test_move(player.global_transform,Vector3.RIGHT*.5,hit):
  print("RF04_CONTACT collider=",hit.get_collider()," at=",hit.get_position()," normal=",hit.get_normal())
 else:print("RF04_CONTACT no terrain obstruction at stopped pose")
 for node: Dictionary in terrain.map.nodes:
  if Vector2(float(node.x)-stopped.x,float(node.z)-stopped.z).length()<4:print("RF04_NEARBY_NATIVE_NODE ",JSON.stringify(node))
 for z in range(509,514):
  var row:=[]
  for x in range(555,561):row.append(terrain.height_at(x,z))
  print("RF04_HEIGHT z=",z," ",row)
 player.position=stopped
 player.velocity=Vector3.ZERO
 player.rotation.y=-PI/2
 player.set_physics_process(true)
 for i in 20:await get_tree().physics_frame
 player.test_walk=Vector2(0,-1)
 for i in 90:
  var offset: Vector3=(Vector3(582.5,0,511.5)-player.position)*Vector3(1,0,1)
  player.rotation.y=lerp_angle(player.rotation.y,atan2(-offset.x,-offset.z),.18)
  await get_tree().physics_frame
 player.test_walk=Vector2.ZERO
 check(player.position.x>562.0,"ordinary steered movement clears the reproduced corner catch")
 check(player.is_on_floor(),"movement retains real ground support beyond the contact")
 var report:={"checks":checks,"failures":failures,"start":[stopped.x,stopped.y,stopped.z],"end":[player.position.x,player.position.y,player.position.z],"frames":90,"scope":"Only the concrete diagonal corner catch observed during the first RF04 walk; no controller change."}
 FileAccess.open(output.path_join("contact-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF04_STOPPED_CONTACT_WALK ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
