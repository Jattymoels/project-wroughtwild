"""Cook the approved local handoffs into one isolated game; no source is modified."""
import argparse, hashlib, io, json, struct
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('game',type=Path);a=p.parse_args()
out=a.game/'art05/assets';out.mkdir(parents=True,exist_ok=True)
tex=out/'textures';tex.mkdir(exist_ok=True)
inputs={};textures={};models={}
def sha(b):return hashlib.sha256(b).hexdigest()
def texture(data):
    im=Image.open(io.BytesIO(data));im.load()
    if im.mode not in ('RGB','RGBA'): im=im.convert('RGBA' if 'A' in im.getbands() else 'RGB')
    # Keep source pixels at <=2k. Four-kilopixel handoff maps are resampled once.
    im.thumbnail((2048,2048),Image.Resampling.LANCZOS)
    key=sha(im.mode.encode()+str(im.size).encode()+im.tobytes())[:24]+'.png'
    f=tex/key
    if not f.exists():im.save(f)
    textures[key]={'size':list(im.size),'bytes':f.stat().st_size}
    return 'textures/'+key
def copy_texture(source):
    inputs[str(source.relative_to(ROOT))]=sha(source.read_bytes())
    return texture(source.read_bytes())
def glb(name,source):
    data=source.read_bytes();inputs[str(source.relative_to(ROOT))]=sha(data)
    length=struct.unpack_from('<I',data,12)[0]
    doc=json.loads(data[20:20+length]);binary=data[28+length:]
    removed=set()
    for image in doc.get('images',[]):
        idx=image.pop('bufferView',None)
        if idx is not None:
            view=doc['bufferViews'][idx];raw=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']];removed.add(idx)
        else:raw=(source.parent/image['uri']).read_bytes()
        image['uri']=texture(raw);image.pop('mimeType',None)
    # Drop embedded image buffers; preserve exact mesh, skin and animation bytes.
    views=[];chunks=[];mapping={};offset=0
    for i,v in enumerate(doc.get('bufferViews',[])):
        if i in removed:continue
        b=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
        pad=(-offset)%4;chunks.append(b'\0'*pad);offset+=pad
        v=dict(v,byteOffset=offset);mapping[i]=len(views);views.append(v);chunks.append(b);offset+=len(b)
    for accessor in doc.get('accessors',[]):
        if 'bufferView' in accessor:accessor['bufferView']=mapping[accessor['bufferView']]
        for kind in ('indices','values'):
            if kind in accessor.get('sparse',{}):
                v=accessor['sparse'][kind];v['bufferView']=mapping[v['bufferView']]
    doc['bufferViews']=views;doc['buffers']=[{'byteLength':offset}]
    binary=b''.join(chunks);binary+=b'\0'*((-len(binary))%4)
    js=json.dumps(doc,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
    result=struct.pack('<III',0x46546c67,2,28+len(js)+len(binary))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(binary),0x004e4942)+binary
    (out/(name+'.glb')).write_bytes(result)
    (out/(name+'.glb.import')).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[params]\nmeshes/generate_lods=false\nanimation/fps=100\n',encoding='utf-8')
    models[name]={'source':str(source.relative_to(ROOT)),'bytes':len(result),'triangles':sum(doc['accessors'][p['indices']]['count']//3 for m in doc.get('meshes',[]) for p in m['primitives']),'animations':[x.get('name') for x in doc.get('animations',[])]}
boar=ROOT/'build/boar-art01/boar-handoff/review'
grove=ROOT/'build/grove-art02/emberroot-handoff/review'
red=ROOT/'build/workshop-art04/red-handoff/review'
for name in ('boar-mid','boar-far'):glb(name,boar/(name+'.glb'))
for name in ('quiet-tree','altered-tree','canopy-far','fractured-rock'):glb(name,grove/(name+'.glb'))
for name in ('red-source-mid','red-source-far','red-buffer-mid','red-fragment-1','red-fragment-2','red-fragment-3'):glb(name,red/(name+'.glb'))
bindings={}
for family,folder,names in [('boar',boar,{'base':'base.png','orm':'orm.png','normal':'normal.png','scar':'scar-mask.png'}),('boar-far',boar,{'base':'far-base.png','orm':'far-orm.png','normal':'far-normal.png','scar':'far-scar.png'}),('red',red,{k:'red-'+k+'.png' for k in ('base','orm','normal','scar')}),('tree',grove,{k:'tree-'+k+'.png' for k in ('base','orm','normal','scar')}),('rock',grove,{k:'rock-'+k+'.png' for k in ('base','orm','scar')})]:
    bindings[family]={k:copy_texture(folder/v) for k,v in names.items()}
for i in range(1,4):bindings['fragment-'+str(i)]={k:copy_texture(red/f'fragment-{i}-{k}.png') for k in ('base','orm','normal','scar')}
appearance={}
for name,source in [('boar',boar/'boar-study.json'),('grove',grove/'grove.json'),('red',red/'red.json')]:
    inputs[str(source.relative_to(ROOT))]=sha(source.read_bytes());appearance[name]=json.loads(source.read_text(encoding='utf-8-sig'))
report={'appearance':appearance,'inputs':inputs,'models':models,'bindings':bindings,'textures':textures,'texture_bytes':sum(t['bytes'] for t in textures.values()),'note':'Geometry, skin weights and animation accessors preserved byte-for-byte. Shared external PNGs, maximum 2048 pixels. Raw handoffs untouched.'}
(out/'asset-index.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ART05_COOK_OK',len(models),len(textures),report['texture_bytes'])
