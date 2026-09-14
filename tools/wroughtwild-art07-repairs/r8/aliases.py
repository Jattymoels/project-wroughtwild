"""R8 derivative of R2 exact image aliases, applied to the final repaired assets.
Only images[].uri changes; every other glTF property and GLB BIN remains exact.
"""
import argparse,collections,hashlib,json,os,re,struct
from pathlib import Path
from urllib.parse import quote,unquote
from inspect_inputs import ROOT,sha,read
from compose import write

def digest(b):return hashlib.sha256(b).hexdigest()
def params(p):
    if not p.exists():return None
    s=p.read_text(encoding='utf-8-sig');assert '[params]' in s
    return s.split('[params]',1)[1].strip().replace('\r\n','\n')
def chunks(b):
    assert b[:4]==b'glTF' and struct.unpack_from('<II',b,4)==(2,len(b))
    out=[];at=12
    while at<len(b):
        n,k=struct.unpack_from('<II',b,at);at+=8;out.append((k,b[at:at+n]));at+=n
    assert at==len(b);return out
def encode_glb(c,d):
    b=json.dumps(d,separators=(',',':'),ensure_ascii=False).encode();b+=b' '*(-len(b)%4)
    out=b''.join(struct.pack('<II',len(v),k)+v for k,v in [(c[0][0],b),*c[1:]])
    return b'glTF'+struct.pack('<II',2,len(out)+12)+out

def main(version,tag):
    out=ROOT/'build/art07-repairs/r8'/version;runtime=out/'runtime';game=runtime/'game';groups=collections.defaultdict(list)
    eligible={'b1','b2','b3','b4','c1','c2','c3','c4','c5','c6','d4','d5','d6','e1','e2','e3','f1','f2','f3','f4','f5','g1','art07_d1','art07_d2','art07_d3','r1','r3','r5','r6','r7'}
    files=[p for p in sorted(game.rglob('*')) if p.is_file() and '.godot' not in p.parts and (p.relative_to(game).parts[0] in eligible or p.relative_to(game).as_posix().startswith('assets/authored/'))]
    skipped=[]
    for p in files:
        if p.suffix!='.png':continue
        par=params(Path(str(p)+'.import'))
        if par is None:skipped.append(p.relative_to(game).as_posix());continue
        groups[(sha(p),digest(par.encode()))].append('res://'+p.relative_to(game).as_posix())
    aliases={};proof=[]
    for (h,ih),names in groups.items():
        canonical=min(names,key=lambda n:(len(n),n))
        for name in names:
            if name==canonical:continue
            aliases[name]=canonical;proof.append({'from':name,'to':canonical,'png_sha256':h,'import_parameters_sha256':ih})
    (game/'r2/texture-aliases.json').write_text(json.dumps(aliases,indent=2),encoding='utf-8',newline='\n')
    rebinding=[]
    for p in files:
        if p.suffix not in ['.glb','.gltf']:continue
        before=p.read_bytes();c=chunks(before) if p.suffix=='.glb' else None
        original=json.loads(c[0][1] if c else before);d=json.loads(json.dumps(original));bindings=[]
        for i,img in enumerate(d.get('images',[])):
            old=None
            if 'uri' in img and not img['uri'].startswith('data:'):old=(p.parent/unquote(img['uri'])).resolve()
            elif c and 'bufferView' in img:
                candidate=p.with_name(p.stem+'_'+img.get('name','Image_'+str(i))+'.png')
                if candidate.is_file():
                    view=d['bufferViews'][img['bufferView']];assert view.get('buffer',0)==0
                    binary=next(v for k,v in c if k==0x004e4942);raw=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
                    if digest(raw)==sha(candidate):old=candidate.resolve()
            if old is None or not old.is_relative_to(game.resolve()):continue
            resource='res://'+old.relative_to(game).as_posix()
            if resource not in aliases:continue
            target=game/aliases[resource][6:]
            img.pop('bufferView',None);img.pop('mimeType',None)
            img['uri']=quote(os.path.relpath(target,p.parent).replace('\\','/'),safe='/._-')
            bindings.append({'image':i,'from':resource,'to':aliases[resource]})
        if not bindings:continue
        assert {k:v for k,v in original.items() if k!='images'}=={k:v for k,v in d.items() if k!='images'}
        after=encode_glb(c,d) if c else json.dumps(d,separators=(',',':'),ensure_ascii=False).encode()
        if c:assert chunks(after)[1:]==c[1:]
        p.write_bytes(after)
        rebinding.append({'path':'game/'+p.relative_to(game).as_posix(),'before_sha256':digest(before),'after_sha256':digest(after),'bindings':bindings,'non_image_json_equal':True,'non_json_chunks_sha256':[digest(v) for k,v in c[1:]] if c else []})
    write(out/('aliases-'+tag+'.json'),{'aliases':proof,'skipped_without_import_parameters':skipped,'image_references':rebinding,'scope':'Final repaired geometry first; identical PNG bytes and complete import parameters only. No geometry, UV, animations, materials or BIN changes.'})
    print('R8_ALIASES',len(aliases),'scenes',len(rebinding),'awaiting import parameters',len(skipped),flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',default='v01');p.add_argument('--tag',required=True);a=p.parse_args();main(a.version,a.tag)
