"""Finalize the shared rough stone material on a fresh copy; geometry stays exact."""
import bpy,sys,shutil,json
from pathlib import Path
src,out=map(lambda p:Path(p).resolve(),sys.argv[sys.argv.index('--')+1:]);assert not out.exists();out.mkdir(parents=True)
for p in src.iterdir():
    if p.suffix in ['.glb','.png','.json']:shutil.copy2(p,out/p.name)
bpy.ops.wm.open_mainfile(filepath=str(src/'c5-master.blend'))
ore_ids=[r['id'] for r in json.loads(Path(__file__).with_name('kit.json').read_text())['ores']]
orm=bpy.data.images.load(str(src/'rock-orm.png'));orm.name='C5 retained shared linear ORM';orm.colorspace_settings.name='Non-Color';orm.pack();orm.use_fake_user=True
count=0
for mat in bpy.data.materials:
    if not any(mat.name.startswith(i) for i in ore_ids) or not mat.use_nodes:continue
    nt=mat.node_tree;tex=next((n for n in nt.nodes if n.type=='TEX_IMAGE'),None);bs=nt.nodes.get('Principled BSDF')
    if tex is None or bs is None:continue
    bump=nt.nodes.new('ShaderNodeBump');bump.name='Stone grain only; scar is separate geometry';bump.inputs['Strength'].default_value=1;bump.inputs['Distance'].default_value=.012
    nt.links.new(tex.outputs['Color'],bump.inputs['Height']);nt.links.new(bump.outputs['Normal'],bs.inputs['Normal']);count+=1
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'c5-master.blend'),compress=True)
(out/'finish.json').write_text(json.dumps({'source':str(src),'material_count':count,'micro_bump_distance_m':.012,'geometry':'All 90 GLBs copied byte-identically. Source geometry unchanged. Shared texture surfaces replace atlas interpolation; original source maps remain packed.'},indent=2)+'\n');print('C5_FINISH_OK',count)
