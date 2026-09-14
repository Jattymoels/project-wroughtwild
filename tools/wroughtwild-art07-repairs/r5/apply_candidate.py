"""Apply only the eight exported lower-body candidates to the verified runtime."""
import json,shutil,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BASE=ROOT/'build/art07-repairs/r5/v02';RUN=BASE/'runtime';MODEL=BASE/'models'
def sha(p):return hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
prep=json.loads((BASE/'prepared.json').read_text());geom=json.loads((RUN/'game/e3/geometry.json').read_text());new=json.loads((MODEL/'geometry.json').read_text());changes=[]
for p in sorted((MODEL/'runtime').glob('chest_*_body.glb')):
 rel='game/assets/authored/e3/'+p.name;dest=RUN/rel;before=sha(dest);assert before==prep['original_files'][rel]['sha256'];shutil.copy2(p,dest)
 changes.append({'path':rel,'before_sha256':before,'after_sha256':sha(dest),'functions_or_settings':'Authored lower cabinet vertex fit, four inset same-family feet and their metric UVs','purpose':'Cabinet raised clear of full/fine slab surfaces, with four inset feet reaching nominal ground; fixed rim/hinge/lid','overlaps':['R2 may change imported texture storage; reconcile asset replacement against that parent rather than copying the whole runtime.']})
 geom[p.stem]=new[p.stem]
for p in sorted((MODEL/'runtime').glob('chest_*_lid.glb')):assert sha(p)==sha(RUN/'game/assets/authored/e3'/p.name)
rel='game/e3/geometry.json';dest=RUN/rel;before=sha(dest);dest.write_text(json.dumps(geom,indent=2)+'\n')
changes.append({'path':rel,'before_sha256':before,'after_sha256':sha(dest),'functions_or_settings':'Eight chest body measured bounds; body triangle counts include four source-derived feet; lid/fuel rows retain their values','purpose':'Record changed exported source measurements','overlaps':[]})
(BASE/'changes.json').write_text(json.dumps({'runtime_base':prep['runtime_base'],'parent_candidates':[],'status':'visual_candidate_pending_measurements','files':changes},indent=2)+'\n')
print('R5_APPLIED',len(changes),'files; 8 exact original lids retained')
