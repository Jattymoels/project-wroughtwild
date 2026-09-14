"""Read-only comparison of original objects/maps retained inside changed masters,
plus actual exported scar-to-quiet-host separation. Run under the repair runner.
"""
import bpy,json,sys,hashlib,array,statistics
from pathlib import Path
from mathutils.bvhtree import BVHTree
root=Path(sys.argv[sys.argv.index('--')+1]);report={'preserved_originals':[],'scar_sections':[]}
def digest_mesh(o):
    h=hashlib.sha256();buf=array.array('f',[0.0])*(len(o.data.vertices)*3);o.data.vertices.foreach_get('co',buf);h.update(buf.tobytes())
    for p in o.data.polygons:h.update(array.array('I',p.vertices).tobytes())
    for layer in o.data.uv_layers:
        buf=array.array('f',[0.0])*(len(layer.data)*2);layer.data.foreach_get('uv',buf);h.update(buf.tobytes())
    return h.hexdigest()
for kind in ['broadleaf','pine']:
    bpy.ops.wm.open_mainfile(filepath=str(root/'sources/b1/models'/kind/(kind+'-master.blend')))
    objects={o.name:digest_mesh(o) for o in bpy.data.objects if o.type=='MESH'}
    images={im.name:hashlib.sha256(im.packed_file.data).hexdigest() for im in bpy.data.images if im.packed_file}
    bpy.ops.wm.open_mainfile(filepath=str(root/('reopen-packed' if '--repacked' in sys.argv else 'reopen')/(kind+'-master.blend')))
    assert all(n in bpy.data.objects and digest_mesh(bpy.data.objects[n])==s for n,s in objects.items())
    print("R1_ORIGINAL_IMAGE_DIFF",json.dumps([{ "name":n,"expected":s,"present":n in bpy.data.images,"actual":hashlib.sha256(bpy.data.images[n].packed_file.data).hexdigest() if n in bpy.data.images and bpy.data.images[n].packed_file else None} for n,s in images.items()],indent=2),flush=True)
    assert all(n in bpy.data.images and bpy.data.images[n].packed_file and hashlib.sha256(bpy.data.images[n].packed_file.data).hexdigest()==s for n,s in images.items())
    report['preserved_originals'].append({'kind':kind,'original_meshes':objects,'original_packed_images':images,'exact_source_geometry_uv_and_packed_bytes_retained':True})
for lod in range(3):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(root/'models/broadleaf'/('broadleaf-a-lod%d.glb'%lod)))
    quiet=next(o for o in bpy.context.scene.objects if o.type=='MESH' and 'foliage' not in o.name and 'branchlets' not in o.name)
    tree=BVHTree.FromPolygons([quiet.matrix_world@v.co for v in quiet.data.vertices],[tuple(p.vertices) for p in quiet.data.polygons])
    existing=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(root/'models/broadleaf'/('broadleaf-altered-lod%d.glb'%lod)))
    scar=next(o for o in bpy.data.objects if o not in existing and o.type=='MESH' and 'foliage' not in o.name and 'branchlets' not in o.name)
    uv=scar.data.uv_layers[1];ids={l.vertex_index for l in scar.data.loops if uv.data[l.index].uv.x>.1 and uv.data[l.index].uv.y>.25}
    assert ids
    for section in ['lower','upper']:
        distances=[]
        for i in ids:
            p=scar.matrix_world@scar.data.vertices[i].co
            if (p.z-.65<=2.6)!=(section=='lower'):continue
            distances.append(tree.find_nearest(p)[3])
        assert distances
        distances.sort();report['scar_sections'].append({'lod':lod,'section':section,'samples':len(distances),'min_m':min(distances),'median_m':statistics.median(distances),'max_m':max(distances),'scope':'Nearest-surface separation of actual altered export core vertices from its quiet sibling export. Independent decimation prevents treating this as exact signed incision depth.'})
(root/'evidence/source-and-scar-audit.json').write_text(json.dumps(report,indent=2));print('R1_SOURCE_PRESERVED_AND_SCAR_MEASURED',len(report['preserved_originals']),len(report['scar_sections']))
