"""Run F5 physical transactions using the frozen current game; private saves only."""
import sys,subprocess,os,json,time
from pathlib import Path
root=Path(sys.argv[1]).resolve();tag=sys.argv[2]
logs=root/('f5-placement-'+tag);assert not logs.exists();logs.mkdir()
env=os.environ.copy();env['APPDATA']=str(root/'appdata')
records=[]
for name,args in [('import',['--editor','--import','--quit']),('placement',['res://art07f5/check_placements.tscn']),('restart',['res://art07f5/check_placements.tscn','--','--f5-restore'])]:
    command=['C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe','--path',str(root/'game'),'--headless','--audio-driver','Dummy']+args
    start=time.time()
    with (logs/(name+'.log')).open('w',encoding='utf-8') as f:
        result=subprocess.run(command,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
    text=(logs/(name+'.log')).read_text(encoding='utf-8')
    records.append({'name':name,'command':command,'seconds':time.time()-start,'exit_code':result.returncode})
    (logs/'commands.json').write_text(json.dumps(records,indent=2))
    print('F5_PLACEMENT',name,result.returncode,flush=True)
    assert result.returncode==0 and not any(x in text for x in ['ERROR:','FAIL:','FAIL ']),str(logs/(name+'.log'))
