"""Verify and package ART-06C. Python -- REVIEW NEW_HANDOFF NEW_EVIDENCE."""
import hashlib
import json
import shutil
import struct
import sys
from pathlib import Path
import numpy as np
from PIL import Image

review,package,evidence=(Path(p).resolve() for p in sys.argv[1:])
repo=Path(__file__).resolve().parents[2];recipe=Path(__file__).parent
root=repo/'build/roster-art06c'
assert package.is_relative_to(root) and not package.exists() and not evidence.exists()
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
config=read(recipe/'lifeline-study.json');rows=read(recipe/'roster.json')['assets']
checks=[];summary=[]
def require(ok,message):
    assert ok,message
    checks.append(message)

for row in rows:
    asset=row['id'];source=root/(asset+'-surface-v02');renders=root/(asset+'-renders-v02')
    report=read(source/'surface-report.json');reopen=read(renders/'reopen.json')
    raw=repo/'build/roster-art06'/f"{asset}-source-{row['version']}"/(asset+'.glb')
    require(sha(raw)==report['source_sha256'],asset+': immutable raw source')
    require(report['config_sha256']==sha(recipe/'lifeline-study.json'),asset+': selected controls')
    require(reopen['passed'] and reopen['geometry_sha256']==report['geometry_sha256'],asset+': exact packed source reopened')
    require(report['flipped_faces']==0 and report['depth_audit']['zero_or_reversed_faces']==0,asset+': no collapsed or reversed incision triangles')
    require(report['max_displacement_units']<=config['recess_units']+1e-6,asset+': bounded incision')
    require(report['depth_audit']['median_depth']>=config['minimum_median_depth_units'],asset+': measured median physical depth')
    require(all(x['median']>=config['minimum_route_depth_units'] and x['count']>=2 for x in report['depth_audit']['routes']),asset+': every exposed route has measured depth')
    if asset=='cinder_archer':
        face=report['face_repair']
        require(face['removed_vertices']>0 and face['repaired_uv_faces']>0,asset+': coarse whiskers and face UVs repaired')
        require(len(face['attachments'])==12 and all(not a['emissive'] for a in face['attachments']),asset+': two small eyes and ten fine whiskers')
        require(report['triangles']==face['after_triangles'],asset+': exact repaired host count')
    else:
        require(report['triangles']==report['source_triangles']-len(report['removed_degenerate_face_indices']),asset+': no unreported source detail reduction')
    data=raw.read_bytes();length=struct.unpack_from('<I',data,12)[0]
    doc=json.loads(data[20:20+length]);binary=data[28+length:]
    pbr=doc['materials'][0]['pbrMetallicRoughness']
    for filename,role in [('base.png','baseColorTexture'),('orm.png','metallicRoughnessTexture')]:
        im=doc['images'][doc['textures'][pbr[role]['index']]['source']]
        view=doc['bufferViews'][im['bufferView']];offset=view.get('byteOffset',0)
        original=source/(('source-' if asset=='cinder_archer' else '')+filename)
        require(original.read_bytes()==binary[offset:offset+view['byteLength']],asset+': retained original '+filename+' bytes')
        if asset=='cinder_archer':
            # PNG rows run top-to-bottom; the original occupies the top 2048 rows.
            a=np.array(Image.open(original).convert('RGBA'));b=np.array(Image.open(source/filename).convert('RGBA'))
            require(np.array_equal(a,b[:a.shape[0]]),asset+': original '+filename+' pixels retained in expanded atlas')
    with Image.open(source/'scar-mask.png') as im:
        mask=np.array(im.convert('RGB'),np.int16)
        require(list(im.size)==report.get('mask_dimensions',[config['mask_size']]*2),asset+': exact scar dimensions')
        require(bool((mask[:,:,0]<=mask[:,:,1]+1).all()),asset+': core contained in dark channel')
        lit=mask[:,:,0]>25
        require(lit.sum()>100 and np.ptp(mask[:,:,2][lit])>50,asset+': connected travel signal')
    previous=read(repo/'build/roster-art06b'/(asset+'-surface-v04')/'surface-report.json')
    require(report['core_texel_fraction']>previous['core_texel_fraction']*3,asset+': substantially broader visible core')
    summary.append(dict(asset=asset,animal=row['animal'],source_sha256=report['source_sha256'],
                        host_triangles=report['triangles'],median_depth_units=report['depth_audit']['median_depth'],
                        minimum_route_median=min(x['median'] for x in report['depth_audit']['routes']),
                        previous_maximum_depth=previous['max_displacement_units'],
                        core_texel_fraction=report['core_texel_fraction']))
for name,renderer in [('compatibility-checks.json','gl_compatibility'),('forward-checks.json','forward_plus')]:
    engine=read(root/name)
    require(engine['checks']==len(engine['passed'])==84,renderer+': 59 retained surface checks plus 25 face attachment checks')
    require(engine['renderer']==renderer,renderer+': actual renderer')
    require(all(x['lit_changed_samples']>20 and x['travel_changed_samples']>10 for x in engine['pixels']),renderer+': all six actual light/travel changes')

package.mkdir(parents=True);evidence.mkdir(parents=True)
shutil.copytree(review,package/'review',ignore=shutil.ignore_patterns('.godot','*.uid','captures'))
for row in rows:
    asset=row['id'];source=root/(asset+'-surface-v02');renders=root/(asset+'-renders-v02')
    destination=package/'sources'/asset;destination.mkdir(parents=True)
    for p in source.iterdir():
        if p.suffix in ('.blend','.json','.png'): shutil.copy2(p,destination/p.name)
    shutil.copytree(renders,destination/'inspection')
    out=evidence/asset;out.mkdir()
    shutil.copy2(source/'surface-report.json',out/'surface-report.json')
    for p in renders.iterdir():
        if p.suffix in ('.png','.json'): shutil.copy2(p,out/p.name)
    for mode in ['dark','lit']: shutil.copy2(review/'captures'/(asset+'-'+mode+'.png'),out/('godot-'+mode+'.png'))
for mode in ['dark','lit']: shutil.copy2(review/'captures'/('gallery-'+mode+'.png'),evidence/('gallery-'+mode+'.png'))
for name in ['compatibility-checks.json','forward-checks.json']: shutil.copy2(root/name,evidence/name)
shutil.copy2(root/'art06b-regression.json',evidence/'art06b-regression.json')
for angle in [270,315]:
    shutil.copy2(root/'face-before'/('face-az'+str(angle)+'.png'),evidence/('porcupine-before-az'+str(angle)+'.png'))
shutil.copy2(review/'capture.json',evidence/'capture.json')
frames=[Image.open(p).convert('RGB') for p in sorted((review/'captures').glob('pulse-*.png'))]
require(len(frames)==48,'48 actual four-second pulse frames')
duration=[round((i+1)*1000/12)-round(i*1000/12) for i in range(48)]
frames[0].save(evidence/'pulse.webp',save_all=True,append_images=frames[1:],duration=duration,loop=0,lossless=True,method=4)
palette=Image.open(evidence/'gallery-lit.png').convert('RGB').quantize(colors=256)
gif=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
delays=[(round((i+1)*100/12)-round(i*100/12))*10 for i in range(48)]
gif[0].save(evidence/'pulse.gif',save_all=True,append_images=gif[1:],duration=delays,loop=0,disposal=1,optimize=True)
for frame in frames: frame.close()
shutil.copy2(recipe/'launch-review.ps1',package/'Launch lifeline review.ps1')
shutil.copy2(recipe/'lifeline-study.json',package/'lifeline-study.json')
shutil.copy2(recipe/'LIFELINES.md',package/'README.md')
manifest=[dict(path=str(p.relative_to(package)).replace('\\','/'),bytes=p.stat().st_size,sha256=sha(p)) for p in sorted(package.rglob('*')) if p.is_file()]
(package/'manifest.json').write_text(json.dumps(dict(stage=config['stage'],files=manifest),indent=2)+'\n')
(evidence/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
(evidence/'verification.json').write_text(json.dumps(dict(passed=True,count=len(checks),checks=checks,package_files=len(manifest),
    scope='Dense unrigged art sources; physical depth and rendered ambient pulse. No game adoption or performance certification.'),indent=2)+'\n')
print('ROSTER_LIFELINE_HANDOFF_VERIFIED',len(checks),len(manifest),flush=True)
