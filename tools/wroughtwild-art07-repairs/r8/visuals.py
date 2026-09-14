"""Validate matched native state/cameras and encode labelled actual-frame previews."""
import json
from pathlib import Path
from PIL import Image
from inspect_inputs import ROOT,read,sha
from compose import write
build=ROOT/'build/art07-repairs/r8';out=build/'v01';doc=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r8';pairs=[]
for renderer in ['forward_plus','gl_compatibility']:
    after=out/'runtime/evidence'/('views-art-'+renderer+'-r8-full-kit')
    before=build/'v02/runtime/evidence'/('views-art-'+renderer+'-original-full-kit-'+renderer)
    a=read(before/'report.json');b=read(after/'report.json')
    assert a['failures']==b['failures']==0 and a['views']==b['views']
    for key in ['viewport','msaa','vsync','engine','cpu','gpu','gpu_api']:assert a[key]==b[key],(renderer,key)
    assert len(a['camera_audits'])==len(b['camera_audits'])
    for x,y in zip(a['camera_audits'],b['camera_audits']):
        assert (x['view'],x['lighting'])==(y['view'],y['lighting'])
        native=lambda v:[{k:r[k] for k in ['id','position','stock','work']} for r in v['inventory']['resources']]
        assert native(x)==native(y),(renderer,x['view'],'native resource states differ')
        name=x['view']+'-'+x['lighting']+'.png';images=[]
        for folder in [before,after]:
            p=folder/name
            with Image.open(p) as im:assert im.size==(1440,900) and im.format=='PNG'
            images.append({'path':str(p),'sha256':sha(p),'dimensions':[1440,900]})
        pairs.append({'renderer':renderer,'view':x['view'],'lighting':x['lighting'],'images':images,'native_resource_states_equal':True,'resources':len(native(x)),'before_geometry':x['inventory']['geometry'],'after_geometry':y['inventory']['geometry'],'scope':'Matched camera and exact native pose/stock/work. Repaired visual geometry intentionally differs; raw per-part geometry and pose digests remain in each report.'})
assert len(pairs)==60,len(pairs)
write(out/'evidence/matched-visuals.json',{'pairs':pairs,'imagegen_used':False,'scope':'Actual Godot viewport captures, original and combined candidates freshly run separately.'})
previews=[]
def gif(name,paths,duration):
    assert paths;target=doc/name;assert not target.exists();frames=[]
    for p in paths:
        with Image.open(p) as im:
            im=im.convert('RGB');im.thumbnail((800,500),Image.Resampling.LANCZOS);frames.append(im.convert('P',palette=Image.Palette.ADAPTIVE,colors=128))
    frames[0].save(target,save_all=True,append_images=frames[1:],duration=duration,loop=0,optimize=False)
    with Image.open(target) as im:count=im.n_frames;size=im.size
    previews.append({'path':str(target),'sha256':sha(target),'encoded_frames':count,'input_frames':len(paths),'dimensions':size,'frame_duration_ms':duration,'sources':[{'path':str(p),'sha256':sha(p)} for p in paths],'scope':'Actual native engine frames, resized/quantized for an illustrative looping preview. Playback timing is not a real-time performance measurement.'})
gif('f4-native-work.gif',sorted((out/'runtime/evidence/r8-f4/forward_plus/flow/forward_plus').glob('motion-*.png')),100)
walk=out/'runtime/evidence/paid-art-forward_plus-r8-walk-forward_plus/walk'
gif('controller-route.gif',sorted(walk.glob('*.png')),80)
write(doc/'image-provenance.json',{'matched_pairs':pairs,'previews':previews})
print('R8_MATCHED_IMAGES',len(pairs),'R8_MOTION_PREVIEWS',len(previews))
