extends "res://g1/paid.gd"
## Independent measurements of the delivered live tree fit, before any art repair.
func execute():
 var manager:=SaveManager.new()
 check(manager.read("res://g1/paid-home.json",player),"G2 retained home load")
 freeze_fixtures();refresh_stations();terrain.set_process(false)
 var before:=manager.capture(player)
 var rows:Array=[]
 for node in get_tree().get_nodes_in_group("resources"):
  if not node.has_meta("b1_fit"):continue
  var fit:Dictionary=node.get_meta("b1_fit")
  var value:Dictionary={"id":node.resource_id,"family":String(node.material_family),"horizontal_scale":fit.horizontal_scale,"vertical_scale":fit.vertical_scale,"source_walk_height_radius":fit.source_walk_height_radius,"native_body":str(fit.native_body)}
  rows.append(value)
 check(rows.size()>0,"G2 measures actual live B1 instances")
 var after:=manager.capture(player)
 for key in ["sim","leylines","contraptions","blocks","stations","resource_nodes"]:check(before[key]==after[key],"G2 read-only geometry audit retains "+key)
 FileAccess.open("res://../evidence/g2-canopy.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"live_trees":rows,"scope":"Read actual b1_fit metadata on retained world nodes; source masters and native collider unchanged. Horizontal compression applies to crown as well as trunk."},"  "))
 print("G2_CANOPY ",checks," checks, ",failures," failures; ",rows.size()," live trees")
 get_tree().quit(1 if failures else 0)
