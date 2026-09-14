"""Apply the checked R4 terminal handoff to R8 copies of older additive fixtures."""
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';game=out/'runtime/game';proof=[]
old='get_tree().quit()';new='preload("res://r4/fixture_cleanup.gd").finish.call_deferred(self, 0)'
for renderer in ['forward_plus','gl_compatibility']:
    for ident in ['b1','c4']:
        p=game/'r8/replays'/renderer/('r1-'+ident+'.gd');s=p.read_text(encoding='utf-8-sig');assert s.count(old)==1
        updated=s.replace(old,new);assert updated.replace(new,old)==s
        proof.append({'path':str(p.relative_to(game)),'before_sha256':sha(p),'terminal_only':True,'replacement':new})
        p.write_text(updated,encoding='utf-8',newline='\n')
src=game/'r2/projection_base_b.gd';s=src.read_text(encoding='utf-8-sig');assert s.count(old)==1
s=s.replace('res://b3/evidence','res://../evidence/r8-projection').replace(old,new)
write(game/'r8/projection_base.gd',s)
s=(game/'r2/projection_checks.gd').read_text(encoding='utf-8-sig').replace('res://r2/projection_base_b.gd','res://r8/projection_base.gd')
write(game/'r8/projection_checks.gd',s)
write(game/'r8/projection_checks.tscn',(game/'r2/projection_checks.tscn').read_text(encoding='utf-8-sig').replace('res://r2/projection_checks.gd','res://r8/projection_checks.gd'))
proof.append({'source':'r2/projection_base_b.gd','source_sha256':sha(src),'target':'r8/projection_base.gd','terminal_only':True,'replacement':new,'output_change':'private r8-projection evidence'})
write(out/'r4-inherited-fixture-composition.json',proof)
j=read(out/'jobs-core-01.json')[2];j['id']='projection-equivalence-clean';j['log']=str(out/'logs/projection-equivalence-clean.log');j['state']=str(out/'users/projection-equivalence-clean');j['arguments']=[a.replace('r2/projection_checks.tscn','r8/projection_checks.tscn') for a in j['arguments']]
write(out/'jobs-projection-clean-01.json',[j])
print('R8_CLEANUP_DERIVATIVES',len(proof))
