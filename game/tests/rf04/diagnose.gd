extends Node3D
func _ready() -> void:
 var sim: WroughtwildSim=load("res://scripts/sim.gd").shared()
 assert(sim.set_world_profile("frontier_v7"))
 var map: Dictionary=sim.world_map(77)
 var rows: Array=[]
 var report:={"profile":"frontier_v7","seed":77,"heights":[],"faces":[],"height_digest":hash(map.heights),"block_digest":hash(map.blocks)}
 for z in range(506,515):
  var row: Array=[]
  for x in range(566,581):row.append(int(map.heights[z*int(map.width)+x]))
  report.heights.append({"z":z,"x_start":566,"heights":row})
 for z in [496,512]:
  for x in [560,576]:
   var chunk: Dictionary=sim.world_mesh_chunk(77,16,x,z,PackedInt32Array(),true)
   var faces: PackedVector3Array=chunk.faces
   var cells: PackedVector3Array=chunk.source_cells
   var groups: Dictionary={}
   for i in range(0,faces.size(),3):
    var cell: Vector3=cells[i/3]
    if cell.x<566 or cell.x>580 or cell.z<506 or cell.z>514:continue
    var centre:=faces[i]
    if not is_equal_approx(centre.y,cell.y+1.0):continue
    if int(map.heights[int(cell.z)*int(map.width)+int(cell.x)])!=int(cell.y)+1:continue
    if not groups.has(centre):groups[centre]={"cell":cell,"corners":[]}
    for v in [faces[i+1],faces[i+2]]:
     if not groups[centre].corners.has(v):groups[centre].corners.append(v)
   for centre: Vector3 in groups:
    var mean:=Vector3.ZERO
    var corners: Array=[]
    for v: Vector3 in groups[centre].corners:
     mean+=v/float(groups[centre].corners.size())
     corners.append([v.x,v.y,v.z])
    var c: Vector3=groups[centre].cell
    report.faces.append({"cell":[c.x,c.y,c.z],"centre":[centre.x,centre.y,centre.z],"corner_mean":[mean.x,mean.y,mean.z],"centre_error_m":centre.distance_to(mean),"corners":corners})
 var path:=OS.get_environment("WROUGHTWILD_RF04_OUTPUT").path_join("cause-before.json")
 FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 var worst:=0.0
 var nonplanar:=0
 for face in report.faces:
  worst=maxf(worst,face.centre_error_m)
  if face.centre_error_m>.001:nonplanar+=1
 print("RF04_CAUSE top_faces=",report.faces.size()," off_corner_mean=",nonplanar," max_centre_error_m=",worst," height_digest=",report.height_digest," block_digest=",report.block_digest)
 get_tree().quit()
