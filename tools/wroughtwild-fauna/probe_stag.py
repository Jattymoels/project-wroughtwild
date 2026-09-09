"""Blender: map an inspected render pixel to the original surface and normal."""
import bpy,json,sys
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
repo=Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.wm.open_mainfile(filepath=str(repo/'build/fauna-art03/stag-inspect-v01/stag-source.blend'))
obj=bpy.data.objects['Vaultcrown - host']
bvh=BVHTree.FromPolygons([obj.matrix_world@v.co for v in obj.data.vertices],[tuple(f.vertices) for f in obj.data.polygons])
views={'face':((-3,5,3),(0,.5,2.0),1.3)}
args=sys.argv[sys.argv.index('--')+1:]
for i in range(0,len(args),3):
    name,x,y=args[i:i+3];at,target,scale=views[name];at=Vector(at)
    rotation=(Vector(target)-at).to_track_quat('-Z','Y')
    origin=at+rotation@Vector(((float(x)/1280-.5)*scale,(.5-float(y)/1100)*scale*1100/1280,0))
    hit,normal,index,_=bvh.ray_cast(origin,rotation@Vector((0,0,-1)),20)
    print(json.dumps({'view':name,'pixel':[x,y],'hit':list(hit) if hit else None,'normal':list(normal) if normal else None,'face':index}))
