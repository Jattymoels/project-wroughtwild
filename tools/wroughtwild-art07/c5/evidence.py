"""Validate selected actual render output and encode reviewable motion without retouching."""
import sys,json,hashlib,shutil
from pathlib import Path
import numpy as np
from PIL import Image
root,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
evidence=root/'review-v03/game/c5/evidence';report={'renderers':{}}
def gif(paths,path,duration):
    frames=[]
    for p in paths:
        im=Image.open(p).convert('RGB');im.thumbnail((960,600));frames.append(im)
    frames[0].save(path,save_all=True,append_images=frames[1:],duration=duration,loop=0)
for renderer,short in [('forward_plus','forward'),('gl_compatibility','compatibility')]:
    folder=evidence/renderer;native=evidence/('native-'+renderer)
    frames=sorted(folder.glob('heat-motion-*.png'));assert len(frames)==42
    arrays=[np.asarray(Image.open(p).convert('RGB'),dtype=np.int16) for p in frames]
    delta=max(float(np.abs(a-arrays[0]).mean()) for a in arrays[1:]);assert delta>.005,(renderer,delta)
    paused=[hashlib.sha256((folder/f'paused-{i}.png').read_bytes()).hexdigest() for i in range(3)];assert len(set(paused))==1
    assert json.loads((folder/'capture.json').read_text())['collision_objects']==0
    native_result=json.loads((native/'native-flow.json').read_text());assert native_result['failures']==0
    assert native_result['inventory']=={'iron_vein':8,'copper_vein':8,'tin_vein':6,'ember_iron_vein':6,'silver_vein':6}
    for name in ['day','shade','dusk','iron_vein-material','copper_vein-material','tin_vein-material','silver_vein-material','ember_iron_vein-material','copper_vein-clay','ember_iron_vein-clay','scar-off','lod-2']:
        shutil.copy2(folder/(name+'.png'),out/(short+'-'+name+'.png'))
    for name in ['full','part-worked-hot','part-worked-cracked','last-portions','depleted']:shutil.copy2(native/(name+'.png'),out/(short+'-native-'+name+'.png'))
    gif(frames,out/(short+'-heat.gif'),83)
    gif([native/(name+'.png') for name in ['full','heated','part-worked-hot','part-worked-cracked','last-portions']]+sorted(native.glob('depletion-*.png'))+[native/'depleted.png'],out/(short+'-native-work.gif'),[750]*5+[83]*21+[1000])
    report['renderers'][renderer]={'heat_frame_count':42,'max_mean_pixel_change':delta,'paused_identical':True,'native':native_result,'benchmark':json.loads((folder/'benchmark.json').read_text())}
for name in ['family','copper_vein-worked-material','ember_iron_vein-cracked-clay','silver_vein-full-underside']:
    shutil.copy2(root/'blender-v08'/(name+'.png'),out/('blender-'+name+'.png'))
for name in ['prerequisites.json','audit-v08.json']:shutil.copy2(root/name,out/name)
shutil.copy2(root/'baseline/game/c5/native-envelopes.json',out/'native-envelopes.json')
(out/'verification.json').write_text(json.dumps(report,indent=2)+'\n');print('C5_EVIDENCE_OK')
