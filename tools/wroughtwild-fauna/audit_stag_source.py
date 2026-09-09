"""Blender: reopen the handoff and check actual skin deformation, floor clearance and planted soles.

-- FINAL_BLEND RIG_REPORT OUTPUT_JSON
"""
import json,sys
from pathlib import Path
import bpy
import numpy as np

blend,rig_report,output=[Path(p).resolve() for p in sys.argv[sys.argv.index('--')+1:]]
bpy.ops.wm.open_mainfile(filepath=str(blend))
rig=json.loads(rig_report.read_text())
arm=bpy.data.objects['Vaultcrown - study rig']
mesh=bpy.data.objects['Vaultcrown - near candidate']
mesh.hide_set(False);arm.hide_set(False)
lods={name:bpy.data.objects[object_name] for name,object_name in [('mid','Vaultcrown - mid candidate'),('far','Vaultcrown - far candidate')]}
for obj in lods.values():obj.hide_set(False)
points=np.array([v.co for v in mesh.data.vertices])
soles={}
for foot in rig['feet']:
    group=mesh.vertex_groups[foot['name']+'_hoof'].index
    indices=[v.index for v in mesh.data.vertices if v.co.z<=foot['sole']+.003 and any(g.group==group and g.weight>.999 for g in v.groups)]
    assert indices,foot['name']
    soles[foot['name']]=indices
for track in arm.animation_data.nla_tracks:track.mute=True
crown=np.array([v.index for v in mesh.data.vertices if v.co.z>1.96 or (abs(v.co.x)>.45 and v.co.z>1.70)],dtype=int)
assert len(crown)>100
edges=np.array([e.vertices[:] for e in mesh.data.edges],dtype=int)
rest_lengths=np.linalg.norm(points[edges[:,1]]-points[edges[:,0]],axis=1)
head_rest=arm.data.bones['head'].matrix_local.copy()
records=[]
for clip,duration in rig['clips_seconds'].items():
    track=arm.animation_data.nla_tracks[clip]
    arm.animation_data.action=track.strips[0].action
    arm.animation_data.action_slot=track.strips[0].action_slot
    samples=round(duration*100)+1 if clip=='release' else 9
    for sample in range(samples):
        frame=duration*100*sample/(samples-1)
        bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame))
        evaluated=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
        coordinates=np.array([v.co for v in evaluated.data.vertices])
        assert np.isfinite(coordinates).all()
        assert coordinates[:,2].min()>=-.001,(clip,sample,'body below floor',float(coordinates[:,2].min()))
        floors={name:float(coordinates[indices,2].min()) for name,indices in soles.items()}
        for name,value in floors.items():
            assert value>=-.001,(clip,sample,name,'below floor',value)
            assert value<=(.093 if clip=='walk' else .003),(clip,sample,name,'hovering',value)
        lod_minima={}
        for label,obj in lods.items():
            evaluated_lod=obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
            data=np.array([v.co for v in evaluated_lod.data.vertices])
            assert np.isfinite(data).all()
            lod_minima[label]=float(data[:,2].min())
            assert lod_minima[label]>=-.001,(label,clip,sample,'LOD below floor',lod_minima[label])
        for obj in [o for o in bpy.context.scene.objects if o.name.startswith('Vaultcrown - fitted')]:
            evaluated_part=obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
            part=np.array([evaluated_part.matrix_world@v.co for v in evaluated_part.data.vertices])
            assert np.isfinite(part).all() and part[:,2].min()>=-.001,(clip,'face below floor',obj.name)
        # Every upper crown vertex must stay rigid in the skull's frame.
        delta=arm.pose.bones['head'].matrix@head_rest.inverted()
        expected=np.array([delta@mesh.data.vertices[int(i)].co for i in crown])
        crown_error=float(np.linalg.norm(coordinates[crown]-expected,axis=1).max())
        assert crown_error<1e-4,('Crown stretched',clip,sample,crown_error)
        lengths=np.linalg.norm(coordinates[edges[:,1]]-coordinates[edges[:,0]],axis=1)
        extension=float(np.max(lengths-rest_lengths))
        assert extension<.08,('Visible stretched mesh edge',clip,sample,extension)
        records.append({'max_edge_extension_metres':extension,'crown_rigid_error_metres':crown_error,'crown_lowest_metres':float(coordinates[crown,2].min()),'clip':clip,'seconds':frame/100,'lowest_surface_metres':float(coordinates[:,2].min()),'lod_lowest_surface_metres':lod_minima,'hoof_sole_y_metres':floors})
arm.animation_data.action=None
images=[{'name':image.name,'size':list(image.size),'packed':bool(image.packed_file or len(image.packed_files))} for image in bpy.data.images if image.has_data]
assert all(im['packed'] for im in images)
output.write_text(json.dumps({'blender':bpy.app.version_string,'reopened':str(blend),'bone_count':len(arm.data.bones),'images':images,'deformed_near_mesh_samples':records,'limitations':'Sole checks cover the fitted near mesh on a flat study floor. They are not terrain IK, actual travel, collision or native combat tests.'},indent=2)+'\n')
print('FAUNA_SOURCE_AUDIT_OK',flush=True)
