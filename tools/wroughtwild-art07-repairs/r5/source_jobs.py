import importlib.util,json,sys
from pathlib import Path
p=Path(__file__).with_name('prepare.py');spec=importlib.util.spec_from_file_location('r5prep',p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
version=sys.argv[1] if len(sys.argv)>1 else 'v02'
assert version.startswith('v') and version[1:].isdigit()
root=m.ROOT;base=root/'build/art07-repairs/r5'/version;source=root/'build/art07-repairs/r5/v01/original-source/source/e3_home.blend';script=root/'tools/wroughtwild-art07-repairs/r5/blender_fit.py'
m.write(base/'blender-fit.json',[m.job(version,'blender-fit',['--background','--threads','8','--python-exit-code','1','--python',str(script),'--','fit',str(source),str(base/'models')],True)])
m.write(base/'blender-reopen.json',[m.job(version,'blender-reopen',['--background','--threads','8','--python-exit-code','1','--python',str(script),'--','reopen',str(base/'models/r5_chest.blend'),str(base/'reopen')],True)])
