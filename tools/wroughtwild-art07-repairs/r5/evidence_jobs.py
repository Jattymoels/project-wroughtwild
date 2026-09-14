"""Explicit sequential evidence specs; fresh logs and task-private user roots."""
import importlib.util,sys,json
from pathlib import Path
s=importlib.util.spec_from_file_location('r5prep',Path(__file__).with_name('prepare.py'));m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
v,label=sys.argv[1:3];base=m.ROOT/'build/art07-repairs/r5'/v;run=base/'runtime';jobs=[]
for renderer in ['forward_plus','gl_compatibility']:
 for mode in ['capture','restore','benchmark','terrain']:
  name=f'{label}-{mode}-{renderer}';state=f'{label}-capture-{renderer}' if mode=='restore' else name
  args=['--rendering-method',renderer,'--path',str(run/'game'),'res://r5/'+('terrain_review' if mode=='terrain' else 'review')+'.tscn','--','--'+mode,'--out='+str(base/'evidence'/name)]
  jobs.append(m.job(v,name,args,state=state))
m.write(base/(label+'-evidence.json'),jobs)
