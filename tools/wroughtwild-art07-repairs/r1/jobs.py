"""Explicit isolated R1 evidence jobs. Execute stages separately through run.ps1."""
from measure import OUT,GAME,write
ENGINE=OUT/'runtime/engine/Godot_v4.5-stable_win64.exe'
def job(ident,scene,flags=(),renderer=None,state=None):
    args=(['--rendering-method',renderer] if renderer else ['--headless','--fixed-fps','60'])+['--path',str(GAME),'res://r1/'+scene+'.tscn']
    if flags:args+=['--',*flags]
    return {'id':ident,'program':str(ENGINE),'arguments':args,'log':str(OUT/'logs'/(ident+'.log')),'state':str(OUT/'users'/(state or ident))}
native=[]
for mode in ['before','after']:
    flags=['--r1-before'] if mode=='before' else []
    native.append(job('b1-'+mode,'b1_native',flags,state='b1-'+mode))
    if mode=='after':
        for state in ['partial','final']:native.append(job('b1-'+state,'b1_native',['--restore-'+state],state='b1-after'))
for flag in ['', '--restore-partial','--restore-final']:
    native.append(job('c4-'+(flag.removeprefix('--restore-') or 'flow'),'c4_native',[flag] if flag else [],state='c4'))
write(OUT/'native-jobs.json',native)
core=[]
for mode in ['before','after']:
    flags=['--r1-before'] if mode=='before' else []
    core += [job('probe-'+mode,'probe',flags),job('paid-'+mode,'paid',[*flags,'--run-id=r1-'+mode],state='paid-'+mode),job('paid-restart-'+mode,'paid',[*flags,'--restart','--run-id=r1-restart-'+mode],state='paid-'+mode)]
write(OUT/'core-jobs.json',core)
captures=[];bench=[]
for renderer in ['forward_plus','gl_compatibility']:
    for mode in ['before','after']:
        flags=['--r1-before'] if mode=='before' else []
        captures.append(job('views-'+mode+'-'+renderer,'views',flags,renderer))
        bench.append(job('cost-'+mode+'-'+renderer,'views',[*flags,'--benchmark'],renderer))
        bench.append(job('stream-'+mode+'-'+renderer,'route',[*flags,'--benchmark','--run-id=r1-stream-'+mode+'-'+renderer],renderer))
    captures.append(job('studio-'+renderer,'studio',renderer=renderer))
    rendered=job('b1-rendered-'+renderer,'b1_native',renderer=renderer,state='b1-rendered-'+renderer)
    rendered['arguments'][0:0]=['--fixed-fps','60']
    captures.append(rendered)
    captures.append(job('catalogue-'+renderer,'catalogue',renderer=renderer))
captures.append(job('route-motion','route',['--capture','--run-id=r1-route-motion'],'forward_plus'))
write(OUT/'capture-jobs.json',captures);write(OUT/'benchmark-jobs.json',bench)
print('R1_JOBS',len(native),len(core),len(captures),len(bench))
