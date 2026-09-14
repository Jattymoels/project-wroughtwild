import shutil
from common import *
guard()
shutil.copy2(TOOLS/'mesh_checks.gd',GAME/'r7/mesh_checks.gd')
(GAME/'r7/mesh_checks.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://r7/mesh_checks.gd" id="1"]\n[node name="R7MeshChecks" type="Node"]\nscript=ExtResource("1")\n')
ec=(GAME/'tests/ecology_buildings.gd').read_text().replace('"res://../build/frontier-polish"','("res://../evidence/r7-ecology-before-02" if "--r7-before" in OS.get_cmdline_user_args() else "res://../evidence/r7-ecology-after-02")')
# The historical frontier_v3 test has no CataclysmSites; G1's C6 inspection
# adapter expects that typed container. Retain the original build function and
# insert an empty fixture container only for that absent historical subsystem.
# Native geography, original test profile and every assertion remain unchanged.
world=(GAME/'scripts/sandpit.gd').read_text()
start=world.index('func _build_world(');end=world.index('\nfunc ',start+1)
fixture=world[start:end]
needle='\tCataclysmSites.build(self, terrain)'
assert fixture.count(needle)==1
fixture=fixture.replace(needle,needle+'\n\tif get_node_or_null("CataclysmSites")==null:\n\t\tvar empty_history:=CataclysmSites.new()\n\t\tempty_history.name="CataclysmSites";empty_history.terrain=terrain;add_child(empty_history)')
(GAME/'r7/ecology.gd').write_text(ec+'\n'+fixture)

(GAME/'r7/ecology.tscn').write_text((GAME/'tests/ecology_buildings.tscn').read_text().replace('res://tests/ecology_buildings.gd','res://r7/ecology.gd'))
shutil.copy2(TOOLS/'grounding.gd',GAME/'r7/grounding.gd')
(GAME/'r7/grounding.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://r7/grounding.gd" id="1"]\n[node name="GroundingBootstrap" type="Node"]\nscript=ExtResource("1")\n')
checks=[job('mesh-checks-01','mesh_checks')]
for mode in ['before','after']:
    checks.append(job('ecology-'+mode,'ecology',['--r7-before'] if mode=='before' else []))
for renderer in ['forward_plus','gl_compatibility']:
    j=job('grounding-'+renderer,'grounding',renderer=renderer);checks.append(j)
    j=job('catalogue-'+renderer,None,renderer=renderer);j['arguments'].append('res://r1/catalogue.tscn');checks.append(j)
write(OUT/'regression-jobs-01.json',checks)
old=ROOT/'build/art07-repairs/r7/v01'
for name in ['selected-source-hashes.json','hardware.json']:
    shutil.copy2(old/'evidence'/name,OUT/'evidence'/name)
shutil.copy2(old/'input-verification-r7-01.txt',OUT/'input-verification-r7-01.txt')
shutil.copytree(old/'sources',OUT/'sources')
lineage=read(old/'evidence/unchanged-master-lineage.json')
for row in lineage:
    source=Path(row['source_path']);target=OUT/'sources/b2/editable'/source.name
    assert sha(source)==row['sha256']==sha(target);row['path']=str(target)
write(OUT/'evidence/unchanged-master-lineage.json',lineage)
inputs=read(ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json')
j={'id':'packed-reopen-01','program':inputs['tools']['blender'],'arguments':['--background','--threads','8','--python-exit-code','1','--python',str(TOOLS/'reopen.py'),'--',str(OUT/'sources/b2'),str(OUT/'evidence/packed-reopen.json')],'log':str(OUT/'logs/packed-reopen-01.log'),'state':str(OUT/'users/packed-reopen-01')}
write(OUT/'reopen-jobs-01.json',[j])
# The V1 before runs are fresh actual R1-parent comparisons; retain exact provenance when using them.
viewjobs=read(OUT/'view-jobs-01.json');write(OUT/'candidate-view-jobs-01.json',[j for j in viewjobs if 'after-' in j['id']])
parse=[]
for name in ['views','audit','cover','mesh_checks']:
    j=job('parse-'+name+'-01');j['arguments']+=['--check-only','--script','res://r7/'+name+'.gd'];parse.append(j)
write(OUT/'parse-jobs-01.json',parse)
print('R7 v02 checks prepared')
