"""R8 fixture-only additions and rerun routing; gameplay assertions stay intact."""
import json,shutil
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';game=out/'runtime/game'
def job(ident,scene,renderer,flags=(),state=None):
    return {'id':ident,'program':str(out/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':['--rendering-method',renderer,'--fixed-fps','60','--path',str(game),'res://'+scene,'--','--r8-no-mouse-capture',*flags],'log':str(out/'logs'/(ident+'.log')),'state':str(out/'users'/(state or ident))}
proof=[];jobs=[]
for renderer in ['forward_plus','gl_compatibility']:
    for ident in ['e2','e3','f1']:
        src=game/ident/'review.gd';original=src.read_text(encoding='utf-8-sig');prefix='res://../evidence/r8-extra/'+renderer+'/'+ident+'/'
        s=original.replace('res://../evidence/',prefix)
        assert s.replace(prefix,'res://../evidence/')==original
        if ident=='f1':
            s=s.replace('res://f1/evidence',prefix.rstrip('/'))
            assert s.replace(prefix.rstrip('/'),'res://f1/evidence')==original
        target='r8/extra/'+renderer+'/'+ident
        write(game/(target+'.gd'),s)
        write(game/(target+'.tscn'),(game/ident/'review.tscn').read_text(encoding='utf-8-sig').replace('res://'+ident+'/review.gd','res://'+target+'.gd'))
        proof.append({'source':str(src),'source_sha256':sha(src),'target':target+'.gd','output_prefix':prefix,'inverse_exact':True})
        cases=[('flow',['--check'] if ident=='e2' else []),('restart',['--restore'] if ident!='f1' else ['--restart'])]
        if ident=='f1':cases.append(('depleted',['--restart-depleted']))
        for mode,flags in cases:jobs.append(job('extra-'+ident+'-'+mode+'-'+renderer,target+'.tscn',renderer,flags,'extra-'+ident+'-'+renderer))
    checkpoints=out/'evidence/extra-c5'/renderer/'checkpoints';checkpoints.mkdir(parents=True,exist_ok=False)
    for mode,flags in [('flow',[]),('partial',['--restore-partial']),('final',['--restore-final'])]:
        target=checkpoints.parent/mode;target.mkdir()
        jobs.append(job('extra-c5-'+mode+'-'+renderer,'r6/c5_native_review.tscn',renderer,flags+['--output='+str(target),'--checkpoint-dir='+str(checkpoints)],'extra-c5-'+renderer))
write(out/'jobs-extra-01.json',jobs);write(out/'extra-fixture-preservation.json',proof)
# Preserve selected source metadata. The original R6 reopen report is otherwise exact.
src=ROOT/'tools/wroughtwild-art07-repairs/r6/reopen.py';s=src.read_text(encoding='utf-8-sig');s=s.replace('import sys', 'import sys\nsys.dont_write_bytecode=True');s=s.replace('sys.path.insert(0, str(Path(__file__).resolve().parent))','sys.path.insert(0, '+repr(str(src.parent))+')')
s=s.replace("Path(master).with_name('selected-master.json')","Path(destination).with_name('r6-selected-master.json')")
write(out/'r6_reopen.py',s)
reopens=read(out/'jobs-reopen-01.json')
for j in reopens:
    if j['id']=='reopen-r6':j['arguments'][j['arguments'].index('--python')+1]=str(out/'r6_reopen.py')
write(out/'jobs-reopen-02.json',reopens)
# A separate rendered check observes 120 actual process frames with the player present.
s='''extends "res://g1/play.gd"
func _ready():
    super._ready()
    for frame in 120:
        await get_tree().process_frame
        assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
        assert(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
    print("R8_COMFORT verified 120 rendered player frames; cursor visible; window no-focus")
    get_tree().quit()
'''
write(game/'r8/comfort_live.gd',s)
write(game/'r8/comfort_live.tscn',(game/'g1/play.tscn').read_text(encoding='utf-8-sig').replace('res://g1/play.gd','res://r8/comfort_live.gd'))
write(out/'jobs-comfort-live-01.json',[job('comfort-live-'+r,'r8/comfort_live.tscn',r) for r in ['forward_plus','gl_compatibility']])
# Remove an unused inspection flag that no source implements.
visual=read(out/'jobs-visual-01.json')
for j in visual:j['arguments']=[a for a in j['arguments'] if a!='--r6-before']
write(out/'jobs-visual-02.json',visual)
print('R8_EXTRA_JOBS',len(jobs))
