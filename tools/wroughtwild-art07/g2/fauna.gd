extends Node3D
## G2 inspection only: instantiate the 16 existing runtime IDs; no new meshes/rigs.
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func _ready()->void:
 get_window().size=Vector2i(1600,1200)
 var world:=WorldEnvironment.new();var environment:=Environment.new();world.environment=environment
 environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("343d3a")
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("cbd8d2");environment.ambient_light_energy=.6
 add_child(world)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,-30,0);light.light_energy=1.1;add_child(light)
 var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=19;camera.position=Vector3(0,18,-23);add_child(camera);camera.look_at(Vector3(0,0,0));camera.current=true
 var sim:WroughtwildSim=load("res://scripts/sim.gd").shared()
 var before:=sim.export_json()
 var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("res://g2/fauna.json"))
 var output:="res://../evidence/g2-fauna-"+RenderingServer.get_current_rendering_method()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 var rows:Array=[]
 for i in entries.size():
  var entry:Dictionary=entries[i]
  var pos:=Vector3((i%4-1.5)*4.6,0,(floori(float(i)/4.0)-1.5)*4.6)
  var actor:=Enemy.spawn(self,StringName(entry.id),pos);actor.set_physics_process(false)
  var motion:=actor._mesh.get_node("Motion") as CreatureMotion;motion.set_physics_process(false)
  var body:=actor.get_node("CollisionShape3D") as CollisionShape3D
  var shape:=body.shape;var transform:=actor.transform;var life:=actor.life;var cooldown:=actor._attack_cooldown
  actor._label.hide()
  var authored:String=actor._mesh.get_meta("authored_actor_id","")
  var expected:String=String(sim.enemy(entry.id).get("visual_id",""))
  if expected.is_empty():expected=String(entry.id)
  check(authored==expected,"retained exact authored identity "+entry.id)
  check(actor._mesh.mesh!=null and motion.rig.get_bone_count()>0,"existing runtime mesh/rig loads "+entry.id)
  for step in 12:motion.sample(1.0/60.0,.01)
  check(actor.transform==transform and body.shape==shape and actor.life==life and actor._attack_cooldown==cooldown,"presentation retains body/combat "+entry.id)
  var definition:Dictionary=RecoveredActorArt.definitions()[authored]
  var actual:String=String(definition.get("animal","older "+String(definition.role)+" form"))
  var label:=Label3D.new();label.text=String(entry.id)+"\nselected: "+String(entry.ancestry)+"\nretained: "+actual;label.font_size=32;label.pixel_size=.007;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=pos+Vector3(0,2.2,0);label.no_depth_test=true;add_child(label)
  rows.append({"id":entry.id,"selected_ancestry":entry.ancestry,"authored_id":authored,"retained_animal":definition.get("animal",""),"rig_version":definition.get("rig_version",1),"bones":motion.rig.get_bone_count(),"native_shape":str(shape),"shape_unchanged":body.shape==shape})
 check(sim.export_json()==before,"all inspection actors preserve native inventory/work state")
 check(rows.size()==16,"exactly all 16 assigned IDs")
 var layer:=CanvasLayer.new();add_child(layer);var heading:=Label.new();heading.position=Vector2(22,18);heading.add_theme_font_size_override("font_size",24);heading.text="G2 / RETAINED RUNTIME ACTORS / "+RenderingServer.get_current_rendering_method()+"\nStatic inspection; ART-06C adoption and new rigs remain unfinished";layer.add_child(heading)
 for frame in 8:await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output+"/lineup.png")
 FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"actors":rows,"scope":"Existing runtime models/rigs instantiated unchanged. Static inspection with presentation samples; no new gameplay actor, rigging or normal-world adoption."},"  "))
 print("G2_FAUNA ",checks," checks, ",failures," failures")
 get_tree().quit(1 if failures else 0)
