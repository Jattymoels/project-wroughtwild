"""Verify, collect actual surface evidence and package the isolated ART-06B handoff.

Python -- REVIEW NEW_HANDOFF NEW_EVIDENCE. No source regeneration or image retouch.
"""
import hashlib
import json
import shutil
import struct
import sys
from pathlib import Path
import numpy as np
from PIL import Image

review,package,evidence = (Path(p).resolve() for p in sys.argv[1:])
repo = Path(__file__).resolve().parents[2]
root = repo/'build/roster-art06b'
assert package.is_relative_to(root) and not package.exists() and not evidence.exists()
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
cfg = read(repo/'tools/wroughtwild-roster/surface-study.json')
rows = read(repo/'tools/wroughtwild-roster/roster.json')['assets']
checks = []
def require(ok,message):
    assert ok,message
    checks.append(message)
summary = []
for row in rows:
    asset = row['id']
    source = root/(asset+'-surface-v04')
    audit = read(source/'surface-report.json')
    reopen = read(root/(asset+'-renders-v04')/'reopen.json')
    raw = repo/'build/roster-art06'/f"{asset}-source-{row['version']}"/(asset+'.glb')
    require(sha(raw)==audit['source_sha256'],asset+': immutable raw source')
    require(audit['config_sha256']==sha(repo/'tools/wroughtwild-roster/surface-study.json'),asset+': final recipe hash')
    require(reopen['passed'] and reopen['geometry_sha256']==audit['geometry_sha256'],asset+': packed source reopening')
    require(audit['flipped_faces']==0 and 0<audit['max_displacement_units']<=cfg['recess_units']+1e-6,asset+': bounded safe incision')
    require(audit['triangles']==audit['source_triangles']-len(audit['removed_degenerate_face_indices']),asset+': no hidden detail reduction')
    data=raw.read_bytes();length=struct.unpack_from('<I',data,12)[0]
    gltf=json.loads(data[20:20+length]);binary=data[28+length:]
    pbr=gltf['materials'][0]['pbrMetallicRoughness']
    for filename,role in [('base.png','baseColorTexture'),('orm.png','metallicRoughnessTexture')]:
        im=gltf['images'][gltf['textures'][pbr[role]['index']]['source']]
        view=gltf['bufferViews'][im['bufferView']];offset=view.get('byteOffset',0)
        require((source/filename).read_bytes()==binary[offset:offset+view['byteLength']],asset+': original '+filename+' bytes')
    with Image.open(source/'scar-mask.png') as image:
        mask=np.asarray(image.convert('RGB'),dtype=np.int16)
        require(image.size==(cfg['mask_size'],)*2,asset+': mask dimensions')
        require(bool((mask[:,:,0]<=mask[:,:,1]+1).all()),asset+': every core texel inside damage')
        core=mask[:,:,0]>25
        require(int(core.sum())>20 and int(mask[:,:,2][core].max()-mask[:,:,2][core].min())>50,asset+': visible core and nonconstant travel')
    summary.append({'asset':asset,'animal':row['animal'],'source_sha256':audit['source_sha256'],
                    'surface_glb_sha256':sha(source/(asset+'-surface.glb')),'triangles':audit['triangles'],
                    'removed_degenerate_faces':len(audit['removed_degenerate_face_indices']),
                    'maximum_incision_units':audit['max_displacement_units'],
                    'core_texel_fraction':audit['core_texel_fraction'],'damage_texel_fraction':audit['damage_texel_fraction']})
for filename,renderer in [('compatibility-checks.json','gl_compatibility'),('forward-checks.json','forward_plus')]:
    engine=read(root/filename)
    require(engine['checks']==len(engine['passed'])==59,renderer+': static engine checks')
    require(engine['renderer']==renderer,renderer+': actual renderer')
    require(all(x['lit_changed_samples']>20 and x['travel_changed_samples']>10 for x in engine['pixels']),renderer+': all six rendered light changes')

package.mkdir(parents=True)
evidence.mkdir(parents=True)
shutil.copytree(review,package/'review',ignore=shutil.ignore_patterns('.godot','*.uid','captures'))
for row in rows:
    asset=row['id'];source=root/(asset+'-surface-v04');renders=root/(asset+'-renders-v04')
    destination=package/'sources'/asset;destination.mkdir(parents=True)
    for name in [asset+'-surface.blend','surface-report.json','base.png','orm.png','scar-mask.png']:
        shutil.copy2(source/name,destination/name)
    shutil.copytree(renders,destination/'inspection')
    out=evidence/asset;out.mkdir()
    shutil.copy2(source/'surface-report.json',out/'surface-report.json')
    for p in renders.iterdir():
        if p.suffix in ('.png','.json'): shutil.copy2(p,out/p.name)
    for mode in ['dark','lit']:
        shutil.copy2(review/'captures'/(asset+'-'+mode+'.png'),out/('godot-'+mode+'.png'))
for mode in ['dark','lit']:
    shutil.copy2(review/'captures'/('gallery-'+mode+'.png'),evidence/('gallery-'+mode+'.png'))
for name in ['compatibility-checks.json','forward-checks.json']:
    shutil.copy2(root/name,evidence/name)
shutil.copy2(review/'capture.json',evidence/'capture.json')
frames=[Image.open(p).convert('RGB') for p in sorted((review/'captures').glob('pulse-*.png'))]
require(len(frames)==48,'48 actual four-second pulse frames')
durations=[round((i+1)*1000/12)-round(i*1000/12) for i in range(48)]
frames[0].save(evidence/'pulse.webp',save_all=True,append_images=frames[1:],duration=durations,loop=0,lossless=True,method=4)
# Encoding only: retain the full-size original captures and use one stable GIF palette.
palette=Image.open(evidence/'gallery-lit.png').convert('RGB').quantize(colors=256)
gif=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
gif_delays=[(round((i+1)*100/12)-round(i*100/12))*10 for i in range(48)]
gif[0].save(evidence/'pulse.gif',save_all=True,append_images=gif[1:],duration=gif_delays,loop=0,disposal=1,optimize=True)
for image in frames: image.close()
shutil.copy2(repo/'tools/wroughtwild-roster/launch-review.ps1',package/'Launch scar review.ps1')
shutil.copy2(repo/'tools/wroughtwild-roster/surface-study.json',package/'surface-study.json')
shutil.copy2(repo/'tools/wroughtwild-roster/SURFACES.md',package/'README.md')
manifest=[{'path':str(p.relative_to(package)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(package.rglob('*')) if p.is_file()]
(package/'manifest.json').write_text(json.dumps({'stage':cfg['stage'],'files':manifest,'bytes':sum(x['bytes'] for x in manifest)},indent=2)+'\n',encoding='utf-8')
(evidence/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
(evidence/'verification.json').write_text(json.dumps({'passed':True,'checks':checks,'count':len(checks),'package_files':len(manifest),
    'package_bytes':sum(x['bytes'] for x in manifest),'animation':'48 actual frames, 4 seconds at 12 fps; lossless WebP and indexed GIF encoding only.',
    'scope':'Surface handoff only; rigs, detailed anatomy repair, later eras and game adoption remain open.'},indent=2)+'\n',encoding='utf-8')
print('ROSTER_SURFACE_HANDOFF_VERIFIED',len(checks),len(manifest),flush=True)
