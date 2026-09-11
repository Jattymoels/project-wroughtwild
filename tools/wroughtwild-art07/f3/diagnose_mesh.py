"""Read-only topology/material diagnostic for the retained rejected candidate."""
import bpy,bmesh,sys,json
from pathlib import Path
src,out=map(Path,sys.argv[sys.argv.index('--')+1:]);out=out.resolve();out.mkdir(parents=True,exist_ok=False)
bpy.ops.wm.open_mainfile(filepath=str(src.resolve()/'f3_master.blend'))
report={}
for name in ['Finished_pullstone','Finished_ventlung']:
 o=bpy.data.objects[name];bm=bmesh.new();bm.from_mesh(o.data)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
 def counts():return {'boundary':sum(e.is_boundary for e in bm.edges),'wire':sum(e.is_wire for e in bm.edges),'overfull':sum(len(e.link_faces)>2 for e in bm.edges),'faces':len(bm.faces)}
 stages={'initial':counts()}
 bmesh.ops.dissolve_degenerate(bm,dist=1e-5,edges=list(bm.edges));stages['dissolve']=counts()
 edges=[e for e in bm.edges if e.is_boundary];r=bmesh.ops.holes_fill(bm,edges=edges,sides=0);stages['filled_faces']=len(r['faces']);stages['fill']=counts()
 report[name]=stages;bm.free()
for m in bpy.data.materials:
 if m.name.startswith('f3_wood'):
  for n in m.node_tree.nodes:
   if n.type=='NORMAL_MAP':n.inputs['Strength'].default_value=0
s=bpy.context.scene;s.render.resolution_percentage=70;s.cycles.samples=12;s.render.filepath=str(out/'without-timber-normal.png');bpy.ops.render.render(write_still=True)
(out/'diagnostic.json').write_text(json.dumps(report,indent=2))
print('F3_DIAGNOSTIC',report)
