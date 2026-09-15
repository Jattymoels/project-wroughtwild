extends "res://tests/rf03/build.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF03_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 inspect.call_deferred()
func inspect() -> void:
 assert(seed_controls.continue_saved())
 quiet()
 var at:=Vector3(568.64258,29.30372,511.40784)
 terrain.ensure_area(at,24)
 terrain.resource_stream.focus(at,true)
 await get_tree().physics_frame
 player.position=at
 player.rotation.y=-PI/2
 player.velocity=Vector3.ZERO
 player.set_physics_process(true)
 for i in 10:await get_tree().physics_frame
 player.test_walk=Vector2(0,-1)
 for i in 40:await get_tree().physics_frame
 player.test_walk=Vector2.ZERO
 var hit:=KinematicCollision3D.new()
 if player.test_move(player.global_transform,Vector3.RIGHT*.5,hit):
  var c=hit.get_collider()
  print("RF03_OBSTACLE ",c," parent=",c.get_parent()," at=",hit.get_position()," normal=",hit.get_normal()," collider_position=",c.global_position)
  for owner in [c,c.get_parent()]:
   if owner is ResourceNode:print("RF03_RESOURCE ",owner.resource_id," ",owner.position)
 print("RF03_STOP ",player.position)
 for z in range(508,516):
  var row:=[]
  for x in range(565,574):row.append(terrain.height_at(x,z))
  print("HEIGHT z=",z," ",row)
 get_tree().quit()
