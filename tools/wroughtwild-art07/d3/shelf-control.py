"""Blender negative control: 10-micrometre ray retries must still reject V01 slit."""
import bpy,sys,json,hashlib
from pathlib import Path
from mathutils.bvhtree import BVHTree
from mathutils import Vector
old,new,out=map(Path,sys.argv[sys.argv.index('--')+1:]); assert not out.exists()
rows=[]
for path in [old,new]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    obj=next(o for o in bpy.context.scene.objects if o.type=='MESH')
    bvh=BVHTree.FromObject(obj,bpy.context.evaluated_depsgraph_get())
    hits=[]
    for x,y in [(.00001,.06125),(-.00001,.06125),(0,.06126),(0,.06124)]:
        # Godot (x,y,-1) -> Blender (x,1,y), toward Godot +Z / Blender -Y.
        loc,normal,index,distance=bvh.ray_cast(Vector((x,1,y)),Vector((0,-1,0)),2)
        hits.append(loc is not None)
    rows.append({'file':str(path.resolve()),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'neighbour_hits':hits})
assert rows[0]['neighbour_hits']==[False]*4,rows
assert rows[1]['neighbour_hits']==[True]*4,rows
out.write_text(json.dumps({'ray_retry_radius_m':.00001,'rejected_4mm_shelf_slit_still_fails':True,'selected_closed_rim_passes':True,'rows':rows},indent=2)+'\n')
print('D3_SHELF_NEGATIVE_CONTROL_OK original slit fails all four rays; selected rim passes all four')
