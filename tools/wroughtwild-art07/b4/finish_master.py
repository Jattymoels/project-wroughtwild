"""Repair glTF's vertex-colour material interpretation in the editable review only."""
import bpy,sys,shutil,json
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from landform import height
kit,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);assert not out.exists();out.mkdir(parents=True)
for n in ['models','layout.json','models.json','lineage.json']:
    shutil.copytree(kit/n,out/n) if (kit/n).is_dir() else shutil.copy2(kit/n,out/n)
bpy.ops.wm.open_mainfile(filepath=str(kit/'b4-composition.blend'))
layout=json.loads((kit/'layout.json').read_text())
for i,row in enumerate(layout):
    for o in bpy.data.collections['REVIEW'].objects:
        if not o.name.startswith(f'Placed {i} '):continue
        plant=row['role'] in ['fern-lush','fern-sparse','grass-meadow','grass-edge','moss','leaf-litter','sapling-shrub']
        if plant:
            for v in o.data.vertices:
                w=o.matrix_world@v.co;v.co.z-=(height(w.x,-w.y)-height(row['x'],row['z']))/row['scale']
        # Standard glTF (x,y,z)->(x,z,-y) preserves the sign of Z->Y rotation.
        o.rotation_euler.z=row['yaw'];bpy.context.view_layer.update()
        if plant:
            for v in o.data.vertices:
                w=o.matrix_world@v.co;v.co.z+=(height(w.x,-w.y)-height(row['x'],row['z']))/row['scale']
seen=set()
for col in ['RUNTIME','REVIEW']:
    for o in bpy.data.collections[col].objects:
        if o.type!='MESH' or 'rock-shelf-altered' not in o.name:continue
        for mat in o.data.materials:
            if mat in seen:continue
            seen.add(mat);ns=mat.node_tree.nodes;ls=mat.node_tree.links;bs=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
            tex=next(n for n in ns if n.type=='TEX_IMAGE' and n.image and n.image.colorspace_settings.name=='sRGB')
            sep=next(n for n in ns if n.type=='SEPARATE_COLOR')
            dark=ns.new('ShaderNodeMixRGB');dark.inputs[2].default_value=(.014,.008,.004,1)
            ls.new(tex.outputs['Color'],dark.inputs[1]);ls.new(sep.outputs['Red'],dark.inputs[0]);ls.new(dark.outputs[0],bs.inputs['Base Color'])
scene=bpy.context.scene;scene.cycles.device='CPU';scene.cycles.samples=24
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'b4-composition.blend'))
scene.render.filepath=str(out/'blender-composition.png');bpy.ops.render.render(write_still=True)
cam=scene.camera;cam.location=Vector((3.6,-5.8,2.2));cam.rotation_euler=(Vector((4.8,0,2.3))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=36
scene.render.filepath=str(out/'blender-scar-lit.png');bpy.ops.render.render(write_still=True)
clay=bpy.data.materials.new('Physical incision clay');clay.diffuse_color=(.36,.38,.4,1);scene.view_layers[0].material_override=clay
scene.render.filepath=str(out/'blender-scar-clay.png');bpy.ops.render.render(write_still=True)
print('B4_EDITABLE_FINISH_OK',len(seen),'materials; exported geometry unchanged')
