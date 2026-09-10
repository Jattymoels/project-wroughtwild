"""Read-only numerical evidence, image comparison and source provenance checks."""
import sys,json,hashlib,struct,io,math
from pathlib import Path
import numpy as np
from PIL import Image
kit,review,depot,out=map(Path,sys.argv[1:])
audit=json.loads((kit.parent/'audit.json').read_text());assert len(audit['exports'])==34
rows=[];unique={}
for file in sorted((kit/'assets').glob('*.glb')):
    data=file.read_bytes();length,kind=struct.unpack_from('<II',data,12);doc=json.loads(data[20:20+length]);start=20+length;binary=data[start+8:]
    for mat in doc.get('materials',[]):assert mat.get('alphaMode','OPAQUE')=='OPAQUE'
    textures=[]
    for im in doc.get('images',[]):
        view=doc['bufferViews'][im['bufferView']];blob=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        digest=hashlib.sha256(blob).hexdigest();image=Image.open(io.BytesIO(blob));image.load();unique[digest]={'size':list(image.size),'encoded_bytes':len(blob),'rgba8_bytes':image.width*image.height*4}
        textures.append(digest)
    rows.append({'file':file.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'textures':textures})
floor=depot/'docs/art/leyline-studies/2026-09-09/grove-art02/forest-floor.png';a=np.asarray(Image.open(floor).convert('RGB'),dtype=float)/255
assert hashlib.sha256(floor.read_bytes()).hexdigest()==hashlib.sha256((review/'forest-floor.png').read_bytes()).hexdigest()
# The mirrored coordinate mapping is tested at all integer tile edges. Exact
# image edge sample equality is independent of the nonseamless source border.
def mirror(p):return np.abs(np.mod(p*.5,1)*2-1)
error=max(float(np.max(np.abs(mirror(np.array([edge-eps]))-mirror(np.array([edge+eps]))))) for edge in range(-8,9) for eps in [1e-6,1e-5])
assert error<1e-12
comparisons=[]
for renderer in ['forward_plus','gl_compatibility']:
    folder=review/'evidence'/renderer
    checks=json.loads((folder/'checks.json').read_text());assert checks['pause'] and checks['one_visible_lod'] and checks['grounded']>checks['physics_samples']-5
    benchmark=json.loads((folder/'benchmark.json').read_text());assert all(c['samples']==300 for c in benchmark['cases'])
    for distance in [7,18]:
        for lod in [1,2]:
            near=np.asarray(Image.open(folder/('lod-'+str(distance)+'-0.png')).convert('RGB'),dtype=float)
            other=np.asarray(Image.open(folder/('lod-'+str(distance)+'-'+str(lod)+'.png')).convert('RGB'),dtype=float)
            delta=np.abs(near-other);comparisons.append({'renderer':renderer,'distance_m':distance,'lod':lod,'mean_abs_rgb_255':float(delta.mean()),'pixels_over_16_fraction':float(np.mean(delta.max(axis=2)>16))})
    frames=sorted(folder.glob('motion-*.png'));assert len(frames)==144
    # The last 24 close-view frames hold the same source clock, proving visible pause.
    paused0=np.asarray(Image.open(frames[-24]));paused1=np.asarray(Image.open(frames[-1]))
    assert np.array_equal(paused0,paused1),'Paused render changed'
    moving0=np.asarray(Image.open(frames[96]));moving1=np.asarray(Image.open(frames[112]))
    assert np.mean(moving0!=moving1)>.0001,'No visible wind evidence'
grove=depot/'build/grove-art02/emberroot-handoff';manifest=json.loads((grove/'manifest.json').read_text())
for name,row in manifest.items():assert hashlib.sha256((grove/name).read_bytes()).hexdigest()==row['sha256']
result={'exports':rows,'unique_embedded_images':unique,'source_floor_sha256':hashlib.sha256(floor.read_bytes()).hexdigest(),'original_edge_difference_mean_255':float((np.abs(a[:,0]-a[:,-1]).mean()+np.abs(a[0]-a[-1]).mean())*.5*255),'mirrored_edge_coordinate_error':error,'rendered_lod_comparisons':comparisons,'grove_manifest_sha256':hashlib.sha256((grove/'manifest.json').read_bytes()).hexdigest(),'grove_files_unchanged':len(manifest),'alpha_blended_surfaces':0,'overdraw_note':'Opaque geometry uses depth testing. Transparent overdraw is zero; opaque/shadow submissions measured separately in benchmark.','pause_pixels_exact_both_renderers':True}
out.write_text(json.dumps(result,indent=2));print('B2_VERIFY_OK',len(rows))
