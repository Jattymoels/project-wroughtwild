import bpy, json, sys
from pathlib import Path
import numpy as np
bpy.ops.wm.open_mainfile(filepath='D:/Wroughtwild/source-art/mob03-crane/input-art06c/shrieker-surface.blend')
result=[]
for obj in bpy.context.scene.objects:
    if obj.type != 'MESH': continue
    p=np.array([obj.matrix_world @ v.co for v in obj.data.vertices])
    result.append({'name':obj.name,'vertices':len(p),'polygons':len(obj.data.polygons),'bounds':[p.min(0).tolist(),p.max(0).tolist()],'matrix':[list(r) for r in obj.matrix_world], 'materials':[m.name for m in obj.data.materials]})
    np.savez_compressed('D:/Wroughtwild/work/mob03-crane/build/mob03/evidence/source-points.npz',points=p)
    for z in np.arange(0,2.1,.1):
        q=p[(p[:,2]>=z)&(p[:,2]<z+.1)]
        if len(q):print('SLICE',round(float(z),2),len(q),np.round(np.percentile(q,[0,25,50,75,100],axis=0),4).tolist())
print(json.dumps(result,indent=2))
Path('D:/Wroughtwild/work/mob03-crane/build/mob03/evidence/source-inspect.json').write_text(json.dumps(result,indent=2))
