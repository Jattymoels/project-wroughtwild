"""Select the reviewed folded silhouette; retain the rejected aggressive LOD."""
import bpy,json,sys,shutil,hashlib
from pathlib import Path
src,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);assert not out.exists();shutil.copytree(src,out)
bpy.ops.wm.open_mainfile(filepath=str(src/'f3_master.blend'))
far=bpy.data.objects['ventlung_far'];mid=bpy.data.objects['ventlung_middle']
rejected=far.copy();rejected.data=far.data.copy();rejected.name='Rejected_ventlung_far_3750';bpy.context.scene.collection.objects.link(rejected);rejected.hide_render=True;rejected.hide_set(True)
far.data=mid.data.copy();far.data.name='Ventlung_far_selected_folded_silhouette'
# Runtime mid GLB and its packed editable mesh are already validated. A copy is
# an explicit conservative fallback, not a claim of additional simplification.
shutil.copy2(src/'ventlung_middle.glb',out/'ventlung_far.glb')
report=json.loads((out/'asset-audit.json').read_text());report['sources']['ventlung']['rejected_far']=report['sources']['ventlung']['lods']['far'];report['sources']['ventlung']['lods']['far']=dict(report['sources']['ventlung']['lods']['middle'],name='ventlung_far')
report['sources']['ventlung']['far_selection']='8500-triangle middle geometry reused at far distance after the 3750-triangle collapse lost folded silhouette. No further distance budget is claimed.'
(out/'asset-audit.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'f3_master.blend'))
(out/'selection.json').write_text(json.dumps({'from':str(src),'reason':report['sources']['ventlung']['far_selection'],'rejected_glb_sha256':hashlib.sha256((src/'ventlung_far.glb').read_bytes()).hexdigest(),'selected_glb_sha256':hashlib.sha256((out/'ventlung_far.glb').read_bytes()).hexdigest(),'unchanged':'All other exported meshes and rendered near/assembly images are byte-identical.'},indent=2)+'\n')
print('F3_FAR_SELECTED',out)
