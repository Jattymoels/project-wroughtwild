"""Validate native motion records; assemble actual frames, without interpolation."""
import hashlib,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3];BUILD=ROOT/'build/art07/f2'
e=BUILD/'game01/game/f2/evidence';gallery=ROOT/'docs/art/leyline-studies/2026-09-09/art07/f2'
report={'native_base':'4b5d89b376765fbf4d46049aa099e0bb154a82da','motion':{},'files':[]}
for renderer in ['forward_plus','gl_compatibility']:
    data=json.loads((e/(renderer+'-motion.json')).read_text())
    assert len(data)==108
    assert all(d['native']['cargo']=={'wood':20} and d['native']['energy']==0 for d in data)
    assert data[-1]['native']['completed_trips']==1 and data[-1]['native']['at_landing']
    anchor=data[23]
    assert all(d['blocked'] and d['native']==anchor['native'] and d['basket']==anchor['basket'] and d['drum']==anchor['drum'] for d in data[24:48])
    assert not data[48]['blocked'] and data[48]['native']['progress']>anchor['native']['progress']
    frames=sorted((e/(renderer+'-motion')).glob('*.png'));assert len(frames)==108
    images=[Image.open(p).convert('RGB') for p in frames]
    assert all(im.size==(1440,900) for im in images)
    path=gallery/(renderer+'-paid-trip.webp')
    images[0].save(path,save_all=True,append_images=images[1:],duration=42,loop=0,quality=88,method=4)
    for im in images:im.close()
    report['motion'][renderer]={'frames':108,'sample_hz':24,'playback_frame_ms':42,'blocked_frames':[24,47],'blocked_progress':anchor['native']['progress'],'one_arrival':True,'native_cargo_conserved':20,'identical_blocked_basket_and_drum_poses':True,'frames_sha256':[hashlib.sha256(p.read_bytes()).hexdigest() for p in frames]}
    report['motion'][renderer]['blocked_distinct_pngs']=len(set(report['motion'][renderer]['frames_sha256'][24:48]))
    assert report['motion'][renderer]['blocked_distinct_pngs']==1, 'Paused rendered frames must stay identical'
    detail=json.loads((e/(renderer+'-detail-motion.json')).read_text())
    assert detail==data, 'Close view must replay exactly the same paid native sequence'
    detail_frames=sorted((e/(renderer+'-detail-motion')).glob('*.png'));assert len(detail_frames)==108
    detail_images=[Image.open(p).convert('RGB') for p in detail_frames]
    detail_images[0].save(gallery/(renderer+'-drum-detail.webp'),save_all=True,append_images=detail_images[1:],duration=42,loop=0,quality=88,method=4)
    for im in detail_images:im.close()
    report['motion'][renderer]['detail_native_matches_route']=True
    for name in ['winch','source','source-emission-off','recovered','landing','arrived','blocked','shade']:
        shutil.copy2(e/(renderer+'-'+name+'.png'),gallery/(renderer+'-'+name+'.png'))
    shutil.copy2(e/(renderer+'-motion.json'),gallery/(renderer+'-motion.json'))
    benchmark=e/(renderer+'-benchmark.json')
    if benchmark.exists():shutil.copy2(benchmark,gallery/benchmark.name)
for src,dst in [(BUILD/'v03/devices/Winch-three-quarter.png','blender-winch.png'),(BUILD/'v03/devices/Landing-three-quarter.png','blender-landing.png'),(BUILD/'v03/source/Thrumroot_near-three-quarter.png','blender-source.png'),(BUILD/'v03/source/scar-off.png','blender-source-emission-off.png')]:shutil.copy2(src,gallery/dst)
for p in sorted(gallery.iterdir()):
    if p.is_file() and p.name!='evidence.json':report['files'].append({'path':p.name,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(gallery/'evidence.json').write_text(json.dumps(report,indent=2)+'\n')
print('F2_EVIDENCE_OK', {k:{a:b for a,b in v.items() if a!='frames_sha256'} for k,v in report['motion'].items()})
