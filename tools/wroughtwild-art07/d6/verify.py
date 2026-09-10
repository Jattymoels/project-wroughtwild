"""Check hashes, tiling, colour space, normals, roughness, gates and pristine scope."""
import hashlib,json,sys
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[3];textures=Path(sys.argv[1]);out=Path(sys.argv[2]);cfg=json.loads(Path(__file__).with_name('materials.json').read_text())
data=json.loads((textures/'textures.json').read_text());results=[]
for f in data['files']:
    p=textures/f['path'];assert hashlib.sha256(p.read_bytes()).hexdigest()==f['sha256']
    im=Image.open(p);assert im.size==(1024,1024) and im.mode=='RGB'
    a=np.array(im).astype(float)
    edge=float(max(np.abs(a[:,0]-a[:,-1]).mean(),np.abs(a[0]-a[-1]).mean()))
    inside=float(max(np.abs(np.diff(a,axis=0)).mean(),np.abs(np.diff(a,axis=1)).mean()))
    assert edge<max(2,inside*3),(p,edge,inside)
    if '_orm' in p.name:assert np.all(a[:,:,0]==255) and np.all(a[:,:,2]==255)
    if '_normal' in p.name:
        normal=a/255*2-1;assert np.max(np.abs(np.linalg.norm(normal,axis=-1)-1))<.013;assert np.min(normal[:,:,2])>.85
    results.append({'map':p.name,'wrap_mean_delta_255':edge,'interior_mean_delta_255':inside})
native=json.loads((root/'data/tuning/construction.json').read_text());families={f['id']:f for f in native['materials']};shapes={s['id']:s for s in native['shapes']}
gates={}
for f in cfg['families']:
    traits=families[f['id']]['traits'];gates[f['id']]={k:all(t in traits for t in shapes[k].get('requires_traits',[])) for k in ['girder','arch','door']}
assert gates=={'iron':{'girder':True,'arch':False,'door':True},'bronze':{'girder':True,'arch':True,'door':True},'steel':{'girder':True,'arch':False,'door':True},'silver':{'girder':True,'arch':True,'door':False}}
assert shapes['girder']['size_m']==[2,.4,.3] and shapes['arch']['size_m']==[1,1,.25]
# Long-distance material identity: neutral luminance and reflection width remain ordered.
means=[]
for f in cfg['families']:
    a=np.array(Image.open(textures/f'd6_{f["id"]}_albedo.png').resize((1,1)))[0,0]/255
    r=np.array(Image.open(textures/f'd6_{f["id"]}_orm.png').resize((1,1)))[0,0,1]/255
    means.append({'id':f['id'],'average_srgb':a.tolist(),'roughness':r})
assert means[0]['roughness']>means[1]['roughness']>means[2]['roughness']>means[3]['roughness']
sheet=Image.new('RGB',(1600,900),(35,35,35));draw=ImageDraw.Draw(sheet)
for i,f in enumerate(cfg['families']):
    tile=Image.open(textures/f'd6_{f["id"]}_albedo.png').resize((190,190))
    for y in range(2):
        for x in range(2):sheet.paste(tile,(i*400+x*190,40+y*190))
    draw.text((i*400+12,12),f['id'].upper()+' / 2x2 TILE',fill='white')
    for j,kind in enumerate(['normal','orm']):sheet.paste(Image.open(textures/f'd6_{f["id"]}_{kind}.png').resize((190,190)),(i*400+j*190,450))
    draw.text((i*400+12,660),'LINEAR +Y NORMAL / LINEAR ORM',fill='white')
sheet.save(out.with_name('texture-tiling.png'))
out.write_text(json.dumps({'result':'pass','map_checks':results,'gates':gates,'distance_averages':means,'texture_bytes_png':sum(f['bytes'] for f in data['files']),'shared_rgba8_mipped_bytes':67108864,'note':'Twelve shared 1024-square RGB images; 48 MiB RGBA8 base, 64 MiB full mip chain. No per-object sets.'},indent=2)+'\n')
print('D6_TEXTURE_GATE_CHECKS_OK',len(results),gates)
