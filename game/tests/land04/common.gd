extends "res://tests/rf05/water.gd"
## LAND-04 focused real-world harness. Arrival/recipe inputs may be staged;
## native payments, scene placement, source controls and controller remain real.
var place_data: Dictionary
var journeys: Array=[]
var host_deaths: Array[String]=[]
var captured_art: Dictionary={}
var bench: StationSite
var forge: StationSite
var journal: Array[String]=[]
func begin(seed_value:=77) -> void:
 output=OS.get_environment("WROUGHTWILD_LAND04_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,str(seed_value),output.path_join("private-world.json"))
 player.class_panel.choose("warden")
func started() -> bool:
 while not seed_controls.finished:await get_tree().process_frame
 if not check(not terrain.map.is_empty(),"ordinary world entry finishes"):return false
 quiet()
 place_data=terrain.map.dry_steppe[0]
 journeys=terrain.map.force_journeys
 check(journeys.size()==4,"three primary force journeys and one Green contrast")
 check(world_profile=="frontier_v12","ordinary fresh New World selects V12")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and (DisplayServer.get_name()=="headless" or DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS)),"verified visible mouse / no-focus capture")
 check(JSON.parse_string(_sim().export_json()).get("campaign_policy","legacy")=="legacy","ordinary campaign retained")
 return true
func face_at(at: Vector3) -> void:
 player.camera.rotation=Vector3.ZERO
 var delta:=at-player.camera.global_position
 player.rotation.y=atan2(-delta.x,-delta.z)
 player.spring_arm.rotation.x=atan2(delta.y,Vector2(delta.x,delta.z).length())
func source(id: String) -> LeylineSource:
 for node in get_tree().get_nodes_in_group("leyline_sources"):
  if is_ancestor_of(node) and node.source_id==id:return node
 return null
func home_for(id: String) -> Dictionary:
 for row: Dictionary in terrain.map.home_sites:
  if row.id==id:return row
 return {}
func stage_inputs(id: String) -> void:
 for item: String in _sim().recipe(id).get("inputs",{}):
  if item in ["red_salt","white_mineral","blue_flake","green_resin"]:continue
  var needed:=int(_sim().recipe(id).inputs[item])-_sim().material_count(item)
  if needed>0:_sim().add_material(item,needed)
func finish_job(name: String,extra: Dictionary={}) -> void:
 player.test_walk=Vector2.ZERO
 quiet()
 extra.checks=checks;extra.failures=failures;extra.distance_m=route_distance;extra.art=captured_art
 FileAccess.open(output.path_join(name+"-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(extra,"\t"))
 print("LAND04_",name.to_upper()," ",checks," checks / ",failures," failures; walked=",route_distance)
 get_tree().quit(0 if failures==0 else 1)

func craft(id: String, batches := 1, station: StationSite = null) -> bool:
 var work := player.work_panel
 if station == null: work.open_hand_crafting()
 else: station.interact(player)
 var catalogue := work.catalogue
 catalogue.select_recipe(id)
 catalogue.quantity = batches
 catalogue._render_detail()
 if not check(not catalogue._action.disabled,"current station can make "+id+": "+catalogue._next.text): return false
 var before: Dictionary = _sim().inventory().duplicate(true)
 catalogue._action.pressed.emit()
 var produced := true
 for output in _sim().recipe(id).get("outputs",{}):
  produced = produced and _sim().material_count(output)==int(before.get(output,0))+int(_sim().recipe(id).outputs[output])*batches
 check(produced,"paid craft produces exact output: "+id)
 journal.append(work.message())
 work.close_panel()
 return produced

func fixture(kind: String) -> ContraptionSite:
 for node in get_tree().get_nodes_in_group("contraptions"):
  if node.kind==kind: return node
 return null

func machine(node: ContraptionSite) -> Dictionary:
 return _sim().contraption_state(node.machine_key)

func freeze_fixtures() -> void:
 for node in get_tree().get_nodes_in_group("contraptions"): node.set_physics_process(false)

func connect_control(from: ContraptionSite, to: ContraptionSite, label: String) -> void:
 await aim_at(from)
 player.interact()
 await press(label)
 await press("Link this "+String(ContraptionSite.LABELS[to.kind]))
 check(machine(from).link==to.machine_key,"ordinary connection control: "+from.kind+" -> "+to.kind)
 player.work_panel.close_panel()

func refresh_stations() -> void:
 for station in get_tree().get_nodes_in_group("crafting_stations"):
  if station.player_built:
   if station.station_id == &"workbench": bench = station
   if station.station_id == &"forge_basic": forge = station

func aim_at(node: Node3D) -> void:
 player.work_panel.close_panel()
 player.placement.set_build_mode_enabled(false)
 terrain.ensure_area(node.global_position,20)
 var height := .6
 if node is ContraptionSite: height = ContraptionSite.bounds_for(node.kind).y*.5
 player.global_position = node.global_position+Vector3(0,1.2,2.3)
 for i in 2: await get_tree().physics_frame
 player.camera.position = Vector3.ZERO
 player.camera.look_at(node.global_position+Vector3.UP*height)
 check(player.aim_probe().get("target")==node,"actual camera reaches "+node.name)

func press(label: String) -> bool:
 # The real button's input activation invokes the same callback as a click.
 await get_tree().process_frame
 for button in player.work_panel.find_children("*","Button",true,false):
  if button.text.nocasecmp_to(label) == 0 and button.is_visible_in_tree() and not button.disabled:
   await reveal_control(button)
   button.pressed.emit()
   await get_tree().process_frame
   return check(true,"player control: "+label)
 return check(false,"available player control: "+label)

func reveal_control(button: Button) -> void:
 var ancestor := button.get_parent()
 while ancestor != null:
  if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
  ancestor = ancestor.get_parent()
 await get_tree().process_frame

func place_paid_kit(id: String, at: Vector3) -> bool:
 player.work_panel.close_panel()
 var build := player.placement
 build.set_build_mode_enabled(true)
 player.build_palette.open_panel()
 player.build_palette.select_entry(StringName(id),"kit")
 player.build_palette.close_panel()
 for attempt in 16:
  var target := terrain.surface_position(floori(at.x)+attempt%4,floori(at.z)+attempt/4)
  terrain.ensure_area(target,20)
  target.y = terrain.rendered_height(target.x,target.z,target.y)
  player.position = target+Vector3(0,2.3,3)
  for i in 2: await get_tree().physics_frame
  player.camera.position = Vector3.ZERO
  player.camera.look_at(target)
  build._update_preview()
  if not build.preview_valid: continue
  var before := _sim().material_count(id)
  var event := InputEventAction.new()
  event.action = "primary_action"
  event.pressed = true
  player._unhandled_input(event)
  build.set_build_mode_enabled(false)
  await get_tree().physics_frame
  return check(_sim().material_count(id)==before-1,"actual camera/click paid placement: "+id)
 build.set_build_mode_enabled(false)
 return check(false,"legal footprint for "+id)

func journey(channel: String, secondary:=false) -> Dictionary:
 for row: Dictionary in journeys:
  if row.channel==channel and bool(row.secondary)==secondary:return row
 return {}

func journey_picture(row: Dictionary, name: String) -> void:
 var at: Vector3=row.reveal
 # Final pictures show the host forms from the ordinary nearer approach. The
 # early production view retains the full reveal; walks still start there.
 if not name.ends_with("early") and row.source_route.size()>14:
  at=row.source_route[row.source_route.size()-14]
 terrain.ensure_area(at,32)
 at.y=terrain.rendered_height(at.x,at.z,at.y)+1.1
 ready_at(at);terrain.set_process(true)
 for i in 30:await tick()
 face_at(row.position+Vector3.UP*1.7)
 check(player.is_on_floor() and not player.swimming,"grounded dry player-height "+name+" view")
 var roles: Dictionary={}
 var emitted_parts:=0
 var emitted_instances:=0
 for chunk: Node3D in terrain.chunks.values():
  for child: Node in chunk.get_children():
   if not child is MultiMeshInstance3D or not child.has_meta("land04_cover") or String(child.get_meta("journey_id",""))!=String(row.id):continue
   var part:=child as MultiMeshInstance3D
   var mm:=part.multimesh
   if not part.is_visible_in_tree() or mm==null or mm.mesh==null or mm.mesh.get_surface_count()==0 or mm.instance_count==0 or mm.visible_instance_count==0:continue
   var role:=String(part.get_meta("role",""))
   var instances:=mm.instance_count if mm.visible_instance_count<0 else mini(mm.instance_count,mm.visible_instance_count)
   roles[role]=int(roles.get(role,0))+instances
   emitted_parts+=1;emitted_instances+=instances
 captured_art[name]={"journey":row.id,"parts":emitted_parts,"instances":emitted_instances,"roles":roles}
 if terrain.force_journeys!=null: captured_art[name]["placement"]=terrain.force_journeys.stats.get(String(row.id),{}).duplicate(true)
 check(emitted_parts>0 and emitted_instances>0,"actual "+name+" view has emitted, nonempty LAND04 host-kit instances")
 print("LAND04_EMITTED_ART ",name," ",captured_art[name])
 player.hud.notify("") # Dismiss the staged arrival's transient class notice.
 await still(name+".png")
 quiet()

func aim_source(node: LeylineSource) -> void:
 # Use the actual dry workplace, never the occupied centre of the source mesh.
 var row: Dictionary={}
 for item: Dictionary in journeys:
  if item.source_id==node.source_id:row=item;break
 if row.is_empty():
  await aim_at(node)
  return
 player.work_panel.close_panel()
 var at: Vector3=row.work_stance
 ready_at(at+Vector3.UP*1.1)
 for i in 12:await tick()
 face_at(node.global_position+Vector3.UP*.6)
 check(player.aim_probe().get("target")==node,"actual camera reaches "+node.source_id+" from safe work stance")
 quiet()
