"""Install R7 presentation-only delta after verified R1 consumption."""
import shutil
from common import *
guard()
base=read(OUT/'evidence/parent-runtime-hashes.json')
changes=[]
def edit(name,old,new,purpose,functions):
    path=GAME/name
    source=Path(read(ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json')['runtime_source']['path'])/('game/'+name)
    data=source.read_bytes();assert sha(source)==base['game/'+name],name
    s=data.decode();eol='\r\n' if '\r\n' in s else '\n';old=old.replace('\n',eol);new=new.replace('\n',eol)
    assert s.count(old)==1,(name,old,s.count(old));s=s.replace(old,new)
    # Final reconstruction recipe accepts only a fresh verified parent.
    assert path.read_bytes()==data,name
    path.write_text(s,encoding='utf-8',newline='')
    changes.append({'path':'game/'+name,'before_sha256':sha_bytes(data),'after_sha256':sha(path),'functions':functions,'purpose':purpose})
def sha_bytes(data):return hashlib.sha256(data).hexdigest()
for name in ['cover.gd','settings.json','surface.gdshader']:
    assert not (GAME/'r7'/name).exists() or sha(GAME/'r7'/name)==sha(TOOLS/name),name
    shutil.copy2(TOOLS/name,GAME/'r7'/name)
edit('g1/environment.gd','static func cover_mesh(entry: Dictionary) -> ArrayMesh:\n','static func cover_mesh(entry: Dictionary) -> ArrayMesh:\n\tif R7Cover.enabled(): return R7Cover.ground(entry)\n','Compose B2 plant groups at the retained small cover roots. Existing unmapped kinds retain their original fallback.',['G1Environment.cover_mesh'])
# A second edit is explicitly based on our own immediately preceding delta.
path=GAME/'g1/environment.gd';s=path.read_text();old='\tclock+=delta';assert s.count(old)==1;s=s.replace(old,old+'\n\tif R7Cover.enabled(): R7Cover.tick(clock)');path.write_text(s,newline='');changes[-1]['after_sha256']=sha(path);changes[-1]['functions'].append('G1Environment._process')
edit('art/habitat_look.gd','\tif authored != null:\n\t\treturn authored','\tif authored != null:\n\t\treturn R7Cover.habitat(kind,variant,authored)','Choose two local shrub/fern compositions using existing variant identities after anchor selection. All density/support settings remain unchanged.',['HabitatLook.mesh_for'])
edit('scripts/ground_cover.gd','\t\tinstance.material_override = _shared_material() if frontier_look == null else frontier_look.cover_material()','\t\tinstance.material_override = null if multimesh.mesh.has_meta("r7_composition") else (_shared_material() if frontier_look == null else frontier_look.cover_material())','Allow the composed mesh surface materials to retain source texture and rooted motion. Fallback and scree materials keep their existing path.',['GroundCover.build_for_chunk material binding'])
edit('scripts/strange_sites.gd','static func _batch(parent: Node3D, terrain: Terrain, kind: String, transforms: Array) -> void:\n\tvar mesh:=_mesh_for(kind)','static func _batch(parent: Node3D, terrain: Terrain, kind: String, transforms: Array) -> void:\n\tvar mesh:=R7Cover.regional(kind,_mesh_for(kind))','Compose only regional shrub/fern submissions AFTER all original anchor/support/reservation choices. Original mesh lookup used by placement remains intact.',['StrangeSites._batch'])
path=GAME/'scripts/strange_sites.gd';s=path.read_bytes().decode();old='\t\tinstance.material_override=_material(kind)';assert s.count(old)==1;s=s.replace(old,'\t\tinstance.material_override=null if mesh.has_meta("r7_composition") else _material(kind)');path.write_text(s,newline='');changes[-1]['after_sha256']=sha(path)
write(OUT/'evidence/r7-overlay-application.json',changes)
# Fresh import and smoke specifications retain the generated argument arrays.
jobs=read(OUT/'import-smoke.json')
for j in jobs:
    j['id']='r7-'+j['id'];j['log']=str(OUT/'logs'/(j['id']+'-01.log'));j['state']=str(OUT/'users'/(j['id']+'-01'))
write(OUT/'r7-import-smoke-01.json',jobs)
probe=job('source-probe-03','source_probe',['--r7-before'])
write(OUT/'source-probe-jobs-03.json',[probe])
print('R7_INSTALLED',len(changes),'baseline-relative runtime hooks')
