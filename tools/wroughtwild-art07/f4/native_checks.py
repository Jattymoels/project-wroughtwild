"""Compile unchanged current native checks; no shell interpolation or shared builds."""
import os, subprocess, json, sys, time
from pathlib import Path
root=Path(__file__).resolve().parents[3];out=Path(sys.argv[1]).resolve()
assert out.is_relative_to(root/'build/art07/f4');out.mkdir(parents=True,exist_ok=False)
cc=Path('C:/Users/Matty/AppData/Local/Microsoft/WinGet/Packages/BrechtSanders.WinLibs.POSIX.UCRT_Microsoft.Winget.Source_8wekyb3d8bbwe/mingw64/bin/g++.exe')
env=dict(os.environ);env['PATH']=str(cc.parent)+';'+env['PATH'];records=[]
suites=[('world',['tests/sim/test_world_intensive.cpp','sim/src/worldgen.cpp','sim/src/worldgen_profiles.cpp','sim/src/tuning.cpp','sim/src/json.cpp','sim/src/lattice.cpp']),('core',['tests/sim/test_main.cpp']+[p.relative_to(root).as_posix() for p in sorted((root/'sim/src').glob('*.cpp'))]),('contraptions',['tests/sim/test_contraptions.cpp','sim/src/contraptions.cpp','sim/src/json.cpp'])]
if '--contraptions-only' in sys.argv:suites=[suites[-1]]
for name,sources in suites:
    args=[str(cc),'-std=c++17','-Wall','-Wextra','-Werror','-O1','-I'+str(root/'sim/include')]+[str(root/s) for s in sources]+['-o',str(out/(name+'.exe'))]
    for stage,command in [('compile',args),('test',[str(out/(name+'.exe')),str(root/'data/tuning')])]:
        start=time.time()
        with (out/(name+'-'+stage+'.log')).open('w') as f:result=subprocess.run(command,stdout=f,stderr=subprocess.STDOUT,env=env)
        records.append({'name':name,'stage':stage,'args':command,'exit_code':result.returncode,'seconds':time.time()-start})
        (out/'commands.json').write_text(json.dumps(records,indent=2))
        assert result.returncode==0,(name,stage)
    print((out/(name+'-test.log')).read_text()[-400:])
