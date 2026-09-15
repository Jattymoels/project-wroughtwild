"""Copy only checked MOB-01 runtime dependencies, preserving all three atlas bytes."""
import json,hashlib,shutil,sys
from pathlib import Path
repo=Path(__file__).resolve().parents[2]
version=Path(sys.argv[1]);source=version.parent/'input-art06c';out=repo/'game/assets/authored/porcupine'
report=json.loads((version/'rig-report.json').read_text())
for name in ['base.png','orm.png','scar-mask.png']:
 shutil.copy2(source/name,out/name)
shutil.copy2(version/'porcupine.glb',out/'porcupine.glb')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
manifest={'asset':'cinder_archer','animal':'porcupine','source':'ART-06C selected input; MOB-01 '+version.name,'editable_master':str(version/'porcupine-rigged.blend'),'source_selection':report['source_selection'],'runtime_host_triangles':report['runtime_host_triangles'],'attachment_triangles':report['attachment_triangles'],'bone_count':len(report['bones']),'clips_seconds':report['clips_seconds'],'maps':{'base':'base.png','orm':'orm.png','scar':'scar-mask.png'},'scar':{'colour':[1,.19,.025],'damage_tint':[.16,.14,.12],'peak_emission':2.4,'minimum_light':.32,'period_seconds':4,'crest_width':.2},'files':{p.name:sha(p) for p in out.iterdir() if p.suffix in ['.png','.glb']},'simplification':'One Blender collapse-decimated 150k host; original UV atlas and full face attachments. No manual retopology, normal map or distance LOD.'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(repo/'tools/wroughtwild-porcupine/rig-report.json').write_text(json.dumps(report,indent=2)+'\n')
for name in ['porcupine.glb','base.png','orm.png','scar-mask.png']:
 file='res://assets/authored/porcupine/'+name
 suffix='.scn' if name.endswith('.glb') else '.ctex'
 cache='res://.godot/imported/'+name+'-'+hashlib.md5(file.encode()).hexdigest()+suffix
 template=repo/('game/assets/authored/fauna/wolf.glb.import' if suffix=='.scn' else 'game/assets/authored/fauna/wolf-base.png.import')
 s=template.read_text()
 import re
 s=re.sub(r'^uid=.*\n','',s,flags=re.M)
 s=re.sub(r'res://\.godot/imported/[^\"]+',cache,s)
 s=re.sub(r'source_file="[^"]+"',f'source_file="{file}"',s)
 if suffix=='.scn':s=s.replace('animation/fps=100','animation/fps=60')
 (out/(name+'.import')).write_text(s)
p=repo/'game/assets/authored/mobs/manifest.json';d=json.loads(p.read_text());d['assets']['cinder_archer']['porcupine']['stride_m']=.95;d['assets']['cinder_archer']['porcupine']['purpose']['stride_m']='Travel per pre-family walk cycle; balances readable short steps against existing chase speed. Fast travel can slide, with no locomotion-rule change.';p.write_text(json.dumps(d,indent=2)+'\n')
print('MOB01_COOK_OK',manifest['runtime_host_triangles']+manifest['attachment_triangles'])
