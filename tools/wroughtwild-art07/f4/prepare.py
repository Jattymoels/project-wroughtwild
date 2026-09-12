"""Install F4 art and published E2 forge in a frozen current game copy only."""
import json,shutil,subprocess,sys,zipfile
from pathlib import Path
from inputs import ROOT,DEPOT,BASE,PACKAGES
out,assets,native=map(lambda p:Path(p).resolve(),sys.argv[1:4]);assert out.is_relative_to(ROOT/'build/art07/f4');out.mkdir(parents=True,exist_ok=False)
subprocess.run(['git','-C',str(ROOT),'archive','--format=zip','--output='+str(out/'base.zip'),BASE,'game','data'],check=True)
with zipfile.ZipFile(out/'base.zip') as z:z.extractall(out)
game=out/'game';local=game/'f4';local.mkdir();e2=DEPOT/PACKAGES['e2'][0]
shutil.copytree(e2/'review/game/e2',game/'e2',ignore=shutil.ignore_patterns('*.import','*.uid'))
shutil.copytree(e2/'runtime',game/'assets/authored/e2')
shutil.copytree(assets/'runtime',local/'assets');shutil.copytree(assets/'textures',local/'textures')
for name in ['geometry.json','textures.json']:shutil.copy2(assets/'source'/name,local/name)
for p in Path(__file__).parent.iterdir():
 if p.suffix in ['.gd','.gdshader'] or p.name=='appearance.json':shutil.copy2(p,local/p.name)
shutil.copy2(native/'bin/libwroughtwild_sim.windows.x86_64.dll',game/'bin/libwroughtwild_sim.windows.x86_64.dll')
def patch(rel,old,new):
 p=game/rel;s=p.read_text();assert s.count(old)==1,(rel,old);p.write_text(s.replace(old,new))
patch('project.godot','[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="F4Native"')
patch('art/station_look.gd','func mesh_for(id: StringName) -> ArrayMesh:\n','func mesh_for(id: StringName) -> ArrayMesh:\n\tif id in [&"forge_basic", &"forge_improved"]: return E2ForgeArt.mesh_for(id)\n')
patch('scripts/station_site.gd','\t\t_mesh.position = Vector3.ZERO\n','\t\t_mesh.position = Vector3.ZERO\n\t\tif station_id == &"forge_basic": E2ForgeArt.mount(self)\n')
patch('scripts/strange_resource_art.gd','static func fixture_visual(kind: String) -> Node3D:\n','static func fixture_visual(kind: String) -> Node3D:\n\tif kind == "pressure_feeder": return F4Art.visual("feeder")\n')
patch('scripts/contraption_site.gd','\tvar changed:=int(record.get("completed_cycles",0))!=_last_cycles','\tF4Art.refresh_feeder(self,record,active,paused,progress)\n\tvar changed:=int(record.get("completed_cycles",0))!=_last_cycles')
p=game/'scripts/pressure_pocket.gd';s=p.read_text();start=s.index('\tvar hearth:=');end=s.index('\trefresh_visual()',start);s=s[:start]+'\tF4Art.mount_pocket(self)\n'+s[end:];s=s.replace('*LOOK.pocket_membrane_scale','');s=s.replace('\tif _finish!=null:FINISH.set_state(_finish,fraction,0,_highlighted)','\tF4Art.refresh_pocket(self,fraction)');p.write_text(s)
(local/'review.tscn').write_text((game/'tests/pressure_workshop.tscn').read_text().replace('res://tests/pressure_workshop.gd','res://f4/review.gd'))
(out/'provenance.json').write_text(json.dumps({'base':BASE,'native':json.loads((native/'provenance.json').read_text(encoding='utf-8-sig')),'presentation_patches':['station_look.gd','station_site.gd','strange_resource_art.gd','contraption_site.gd','pressure_pocket.gd'],'normal_game_adoption':False},indent=2));print('F4_REVIEW_PREPARED',out)
