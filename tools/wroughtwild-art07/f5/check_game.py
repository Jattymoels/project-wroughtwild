"""Run current frozen game regressions in a private snapshot and APPDATA.
The game, tests and rules are archived from the same recorded revision. No source edits.
"""
import argparse,subprocess,shutil,json,os,time,zipfile
from pathlib import Path
from audit import DEPOT,sha
BASE='56ce6bbe343012205690cf669491372958b80662'
GODOT='C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe'
def main():
    p=argparse.ArgumentParser();p.add_argument('native',type=Path);p.add_argument('output',type=Path);p.add_argument('--resume',action='store_true');a=p.parse_args()
    root=a.output.resolve();assert a.resume or not root.exists();root.mkdir(parents=True,exist_ok=a.resume)
    archive=root/'current.zip'
    if not a.resume:subprocess.run(['git','-C',str(DEPOT),'archive','--format=zip','--output='+str(archive),BASE,'game','data','sim','tests'],check=True)
    if not a.resume:
        with zipfile.ZipFile(archive) as z:z.extractall(root)
    dll=a.native.resolve()/'bin/libwroughtwild_sim.windows.x86_64.dll';shutil.copy2(dll,root/'game/bin')
    env=os.environ.copy();env['APPDATA']=str(root/'appdata')
    logs=root/'logs';logs.mkdir(exist_ok=a.resume);records=json.loads((logs/'commands.json').read_text()) if a.resume else []
    (root/'build/codex-aesthetic').mkdir(parents=True,exist_ok=True)
    def run(name,args):
        if any(r['name']==name and r['exit_code']==0 for r in records):return
        if (logs/(name+'.log')).exists():name+='-retry02'
        start=time.time();command=[GODOT,'--path',str(root/'game'),'--headless','--audio-driver','Dummy']+args
        with (logs/(name+'.log')).open('w',encoding='utf-8') as f:
            cp=subprocess.run(command,stdout=f,stderr=subprocess.STDOUT,env=env,timeout=480,creationflags=subprocess.CREATE_NO_WINDOW)
        text=(logs/(name+'.log')).read_text(encoding='utf-8')
        record={'name':name,'command':command,'exit_code':cp.returncode,'seconds':time.time()-start}
        records.append(record);(logs/'commands.json').write_text(json.dumps(records,indent=2))
        print(name,cp.returncode,round(record['seconds'],2),flush=True)
        assert cp.returncode==0 and not any(x in text for x in ['SCRIPT ERROR:','ERROR:','FAIL:','FAIL ']),name+' failed: '+str(logs/(name+'.log'))
    run('import',['--editor','--import','--quit'])
    # Current assertions exercise native source/machine contracts and full physical construction.
    run('support-repair',['res://tests/leyline_support_repair.tscn'])
    run('support-repair-restart',['res://tests/leyline_support_repair.tscn','--','--repair-restore'])
    run('paid-wave1',['res://tests/living_frontier_flow.tscn'])
    userdata=root/'appdata/Godot/app_userdata/Wroughtwild'
    (root/'build/lf2').mkdir(parents=True,exist_ok=True)
    shutil.copy2(userdata/'lf1-flow.json',root/'build/lf2/wave1.json')
    for scene,flag in [('living_frontier_wave2_flow','lf2-restore'),('living_frontier_green_flow','green-restore'),('living_frontier_heat_flow','heat-restore')]:
        run(scene,['res://tests/'+scene+'.tscn'])
        run(scene+'-restart',['res://tests/'+scene+'.tscn','--','--'+flag])
    for scene in ['crafting_catalogue','contraption_intensive','pressure_workshop','placement_transactions','home_station_placement','loose_drop_save','save_recovery','weathered_save','wide_frontier_pacing']:
        run(scene,['res://tests/'+scene+'.tscn'])
    (root/'receipt.json').write_text(json.dumps({'base':BASE,'dll_sha256':sha(dll),'runs':records,'failures':[]},indent=2))
if __name__=='__main__':main()
