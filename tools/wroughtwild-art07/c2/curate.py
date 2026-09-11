"""Copy selected real renders unchanged and summarize independent measured results."""
import sys,json,shutil,hashlib
from pathlib import Path
root,out=[Path(p).resolve() for p in sys.argv[1:]];out.mkdir(parents=True,exist_ok=True)
def copy(src,name):shutil.copy2(src,out/name)
for name in ['slate-v0-full-material','slate-v0-worked-material','shellstone-v0-full-back','shellstone-v1-full-back','shellstone-v0-worked-back','upland-tussock-v0-lod0-material']:
 copy(root/'blender-v05'/(name+'.png'),'blender-'+name+'.png')
for renderer in ['forward_plus','gl_compatibility']:
 for name in ['day','shade','dusk','slate-layers','shellstone-fossils','work-states','approach','scar-off','scar-on','lod-0','lod-1','lod-2','far']:
  copy(root/'review-v04/evidence'/renderer/(name+'.png'),renderer+'-'+name+'.png')
 for name in ['wind','pulse','orbit','native-depletion']:
  copy(root/'media-v03'/(renderer+'-'+name+'.webp'),renderer+'-'+name+'.webp')
 for p in (root/'native-v04/game/c2/evidence'/renderer).glob('*.png'):
  if not p.stem.startswith(('walk-','deplete-')):copy(p,renderer+'-'+p.name)
 for name in ['checks.json','benchmark.json']:copy(root/'review-v04/evidence'/renderer/name,renderer+'-'+name)
 for p in (root/'native-v04/game/c2/evidence'/renderer).glob('*.json'):copy(p,renderer+'-'+p.name)
for name in ['audit-v05.json','prerequisites.json','check-summary.json']:copy(root/name,name)
copy(root/'media-v03/motion-verification.json','motion-verification.json')
audit=json.loads((root/'audit-v05.json').read_text());rows={r['file']:r for r in audit['exports']}
summary={'models':len(rows),'images_packed':len(audit['packed_images']),'degenerate_triangles':sum(r['degenerates'] for r in rows.values()),'representative':{},'open_edge_limitations':{r['file']:r['open_edges_after_weld'] for r in rows.values() if r['open_edges_after_weld'] and not r['file'].startswith('upland')}}
for family in ['slate-v0-full','slate-v0-worked','slate-v0-last','slate-v0-recovered','shellstone-v0-full','shellstone-v0-worked','shellstone-v0-last','shellstone-v0-recovered','upland-tussock-v0']:
 summary['representative'][family]=[{'triangles':rows[family+'-lod%d.glb'%i]['triangles'],'surfaces':rows[family+'-lod%d.glb'%i]['surfaces']} for i in range(3)]
cook=json.loads((root/'review-v04/cook.json').read_text());summary['textures']={k:v for k,v in cook.items() if k!='models'}
(out/'measurements.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:v for k,v in summary.items() if k not in ['textures','open_edge_limitations']},indent=2))
