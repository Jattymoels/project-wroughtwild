"""Write reviewable process argument arrays. Does not launch a renderer or test."""
import argparse,json
from pathlib import Path
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); ap.add_argument('--models',type=Path,required=True); ap.add_argument('--tag',default=''); a=ap.parse_args()
root=Path(__file__).resolve().parents[3]; build=a.build.resolve(); models=a.models.resolve(); suffix=('-'+a.tag) if a.tag else ''; jobs=build/('jobs'+suffix); jobs.mkdir(exist_ok=True)
godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
blender='C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe'
game=build/'snapshot/game'
def job(name,args,gpu=False,executable=godot,timeout=600):
    data={'executable':executable,'arguments':args,'cwd':str(root),'output':str(build/'logs'/(name+suffix)),'gpu':gpu,'timeout_seconds':timeout,'appdata':str(build/'isolated-appdata')}
    if name in ['d3-check','d3-restart']: data['allow_native_dummy_material_diagnostic']=True
    (jobs/(name+'.json')).write_text(json.dumps(data,indent=2)+'\n')
base=['--path',str(game),'--audio-driver','Dummy']
job('import',base+['--headless','--import'])
job('d3-check',base+['--headless','res://art07_d3/checks.tscn'])
job('d3-restart',base+['--headless','res://art07_d3/checks.tscn','--','--d3-restore'])
for renderer in ['forward_plus','gl_compatibility']:
    for mode in ['capture','benchmark']:
        job(renderer+'-'+mode,base+['--rendering-method',renderer,'--resolution','1440x900','--position','-9999,-9999','res://art07_d3/gallery.tscn','--','--'+mode],True)
job('reopen',['--background','--threads','8','--python-exit-code','1','--python',str(root/'tools/wroughtwild-art07/d3/reopen.py'),'--',str(models),str(build/('blender-reopen'+suffix))],False,blender)
for name in ['run_tests','art_checks']:
    job(name,base+['--headless','--script','res://tests/'+name+'.gd'])
for name in ['integration','material_intensive','build_usability','home_material_joins','home_headroom','home_workshop_review','home_terrain_placement','home_station_placement','home_station_clearance','home_door_persistence','placement_transactions','placement_generated_fixtures','placement_scenery','building_load_boundaries','contraption_intensive','pressure_workshop','save_recovery']:
    job(name,base+['--headless','--fixed-fps','60','res://tests/'+name+'.tscn'])
for name in ['placement_transactions','placement_generated_fixtures']:
    job(name+'-restart',base+['--headless','res://tests/'+name+'.tscn','--','--placement-restore-only'])
print('D3_JOB_SPECS_WRITTEN',jobs)
