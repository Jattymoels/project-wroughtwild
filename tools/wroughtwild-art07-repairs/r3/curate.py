"""Copy real engine evidence verbatim and encode clearly labelled native-walk playback."""
import argparse,hashlib,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]

def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
p=argparse.ArgumentParser();p.add_argument('--version',default='v01');p.add_argument('--inspection',default='pass02');p.add_argument('--paid',default='pass02');a=p.parse_args()
out=ROOT/'build/art07-repairs/r3'/a.version;raw=out/'runtime/evidence'
dest=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r3'
selected=[]
def gallery(renderer,mode):
    tag='g1' if mode=='before' else 'r3';kind='g1' if mode=='before' else 'candidate'
    return raw/f'r3-{a.inspection}-{tag}-{renderer}-{kind}-{renderer}'
def home(renderer,mode):
    tag='g1' if mode=='before' else 'r3';kind='g1' if mode=='before' else 'candidate'
    return raw/f'r3-home-{a.paid}-paid-{tag}-{renderer}-{kind}-{renderer}'
for mode in ['before','after']:
    for view in ['wood-end-close','slate-cut-close','metal-joins-eye','roofs-rotations-close','glass-sorting-axis']:
        selected.append((gallery('forward_plus',mode)/(view+'-daylight.png'),view+'-'+mode+'.png'))
    for view in ['paid-exterior-eye','paid-interior-close']:
        for light in ['daylight','dusk']:
            selected.append((home('forward_plus',mode)/(view+'-'+light+'.png'),view+'-'+light+'-'+mode+'.png'))
for view,light in [('octagon-triangles-eye','daylight'),('wood-joins-eye','shade'),('wood-joins-eye','dusk'),('covering-edge-close','daylight')]:
    selected.append((gallery('forward_plus','after')/(view+'-'+light+'.png'),view+'-'+light+'.png'))
for view in ['wood-end-close','slate-cut-close','glass-sorting-axis','roofs-rotations-close']:
    selected.append((gallery('gl_compatibility','after')/(view+'-daylight.png'),view+'-compatibility.png'))
selected.append((gallery('forward_plus','after')/'metric-10cm.png','metric-10cm.png'))
for source,name in selected:
    assert source.is_file(),source
    report=read(source.parent/'report.json');assert report['failures']==0,source
    with Image.open(source) as im:assert im.size==(1440,900),source
walk=home('forward_plus','after');report=read(walk/'report.json');frames=sorted((walk/'walk').glob('*.png'))
assert report['failures']==0 and len(frames)==30 and len(report['motion_positions'])==90
assert not dest.exists(),'Use a fresh evidence directory; do not replace an earlier curated candidate.'
dest.mkdir(parents=True)
entries={}
for source,name in selected:
    shutil.copy2(source,dest/name)
    assert sha(source)==sha(dest/name)
    entries[name]={'source':str(source.resolve()),'sha256':sha(source),'pixels':[1440,900],'transform':'none; exact engine PNG bytes'}
images=[]
for f in frames:
    with Image.open(f) as im:
        image=im.convert('RGB');image.thumbnail((640,400));images.append(image.copy())
images[0].save(dest/'paid-native-walk.gif',save_all=True,append_images=images[1:],duration=100,loop=0,optimize=False)
entries['paid-native-walk.gif']={'sha256':sha(dest/'paid-native-walk.gif'),'sources':[{'path':str(f.resolve()),'sha256':sha(f)} for f in frames],'pixels':[640,400],'frames':len(frames),'playback_ms_per_frame':100,'scope':'Illustrative playback of actual native controller captures, resized and GIF-quantized; no interpolation. Full original PNGs and exact engine tick stamps remain in the sealed evidence. This is not a performance recording.','motion_tick_start':report['motion_tick_start'],'motion_tick_end':report['motion_tick_end'],'motion_physics_frames':report['motion_physics_frames'],'motion_positions':report['motion_positions']}
(dest/'provenance.json').write_text(json.dumps(entries,indent=2)+'\n')
print('R3_CURATED',len(selected),'exact PNGs and',len(frames),'native walk frames')
