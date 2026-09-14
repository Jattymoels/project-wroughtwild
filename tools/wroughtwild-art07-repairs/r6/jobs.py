"""Write fresh guarded job specifications. Existing output groups are immutable."""
import argparse
import json
import shutil
from pathlib import Path
from stage import ROOT, TOOLS, OUT, GAME, sha, write

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('group', choices=['surface','c5','probe','benchmark','reopen'])
    parser.add_argument('version')
    parser.add_argument('--parent', default='')
    args = parser.parse_args()
    run = OUT / 'runs' / (args.group+'-'+args.version)
    assert not run.exists(), run
    run.mkdir(parents=True)
    jobs = []
    engine = OUT / 'runtime/engine/Godot_v4.5-stable_win64.exe'
    def job(ident, arguments, program=engine):
        output = run / ident
        output.mkdir()
        jobs.append({'id':ident, 'program':str(program), 'arguments':arguments,
                     'log':str(run/'logs'/f'{ident}.log'), 'state':str(run/'users'/ident)})
        return output
    renderers = ['forward_plus','gl_compatibility']
    if args.group == 'surface':
        job('import-r6', ['--headless','--editor','--path',str(GAME),'--import'])
        for renderer in renderers:
            ident = 'surface-'+renderer
            job(ident, ['--rendering-method',renderer,'--path',str(GAME),'res://r6/review.tscn','--','--output='+str(run/ident)])
            restart = ident+'-restart'
            job(restart, ['--rendering-method',renderer,'--path',str(GAME),'res://r6/review.tscn','--','--output='+str(run/restart),'--restart-dir='+str(run/ident)])
    elif args.group == 'c5':
        native = (ROOT/'tools/wroughtwild-art07/c5/native_review.gd').read_text(encoding='utf-8-sig')
        native = native.replace('DirAccess.make_dir_recursive_absolute(output)', '''
\tfor arg in OS.get_cmdline_user_args():
\t\tif arg.begins_with("--output="): output=arg.trim_prefix("--output=")
\tDirAccess.make_dir_recursive_absolute(output)''',1)
        native = native.replace('"user://c5-partial.json"', 'checkpoint_path("partial")').replace('"user://c5-final.json"','checkpoint_path("final")')
        native += '''
func checkpoint_path(kind:String)->String:
\tfor arg in OS.get_cmdline_user_args():
\t\tif arg.begins_with("--checkpoint-dir="):return arg.trim_prefix("--checkpoint-dir=")+"/c5-"+kind+".json"
\tassert(false,"explicit private checkpoint directory required");return ""
'''
        # Preserve every original assertion and work operation. Only add close/player captures.
        marker = 'func finish(mode:String)->void:'
        extra = '''\tif name in ["full","part-worked-cracked","depleted"]:
\t\tvar saved_camera:Transform3D=camera.transform
\t\tfor index in IDS.size():
\t\t\tvar at:=Vector3((index-2)*3.1,.2,0)
\t\t\tfor view in ["player","close"]:
\t\t\t\tcamera.position=at+Vector3(1.4,1.45,2.0) if view=="player" else at+Vector3(.8,.65,1.1)
\t\t\t\tcamera.look_at(at)
\t\t\t\tcaption.text="ART-07R6 | retained C5 fallback | "+IDS[index]+" | "+name+" | "+view
\t\t\t\tawait RenderingServer.frame_post_draw
\t\t\t\tcheck(get_viewport().get_texture().get_image().save_png(output+"/"+IDS[index]+"-"+name+"-"+view+".png")==OK,"R6 fallback detail screenshot")
\t\tcamera.transform=saved_camera
'''
        native = native.replace(marker,extra+marker)
        write(GAME/'r6/c5_native_review.gd', native)
        write(GAME/'r6/c5_native_review.tscn', (GAME/'c5/native_review.tscn').read_text(encoding='utf-8-sig').replace('res://c5/native_review.gd','res://r6/c5_native_review.gd'))
        # Prove original assertion expressions remain textually identical and in order.
        original_checks = [line.strip() for line in (ROOT/'tools/wroughtwild-art07/c5/native_review.gd').read_text(encoding='utf-8-sig').splitlines() if 'check(' in line]
        transformed_checks = [line.strip() for line in native.splitlines() if 'check(' in line and 'R6 fallback detail' not in line]
        normalized = '\n'.join(transformed_checks).replace('checkpoint_path("partial")','"user://c5-partial.json"').replace('checkpoint_path("final")','"user://c5-final.json"')
        assert normalized == '\n'.join(original_checks)
        write(run/'assertion-preservation.json',json.dumps({'assertion_lines':len(original_checks),'unchanged':True,'changes':'output/checkpoint paths and additive captures only'},indent=2))
        for renderer in renderers:
            flow = 'c5-'+renderer
            for mode in ['flow','partial','final']:
                ident=flow+'-'+mode
                argv=['--rendering-method',renderer,'--path',str(GAME),'res://r6/c5_native_review.tscn','--','--output='+str(run/ident),'--checkpoint-dir='+str(run/(flow+'-flow'))]
                if mode!='flow':argv+=['--restore-'+mode]
                job(ident,argv)
    elif args.group == 'probe':
        probe = (GAME/'g1/probe.gd').read_text(encoding='utf-8-sig')
        probe = probe.replace('func execute():', 'func execute():\n\t# Read-only evidence must not consume the owner\'s live mouse movement.\n\tplayer.set_process_unhandled_input(false)')
        probe = probe.replace('var after:=manager.capture(player)', 'var after:=manager.capture(player)\n\tcheck(before.player==after.player,"R6 capture frames retain exact paid player pose")')
        probe = probe.replace('FileAccess.open(path,FileAccess.WRITE)', '''
\tfor arg in OS.get_cmdline_user_args():
\t\tif arg.begins_with("--output="):path=arg.trim_prefix("--output=")+"/probe.json"
\tFileAccess.open(path,FileAccess.WRITE)''')
        write(GAME/'r6/probe.gd',probe)
        write(GAME/'r6/probe.tscn',(GAME/'g1/probe.tscn').read_text(encoding='utf-8-sig').replace('res://g1/probe.gd','res://r6/probe.gd'))
        for renderer in renderers:
            for mode in ['baseline','art']:
                ident=mode+'-'+renderer
                argv=['--rendering-method',renderer,'--path',str(GAME),'res://r6/probe.tscn','--','--output='+str(run/ident)]
                if mode=='baseline':argv+=['--baseline']
                job(ident,argv)
    elif args.group == 'benchmark':
        for renderer in renderers:
            for mode in ['baseline','art']:
                ident=mode+'-'+renderer
                argv=['--rendering-method',renderer,'--path',str(GAME),'res://r6/review.tscn','--','--benchmark','--output='+str(run/ident)]
                if mode=='baseline':argv+=['--baseline']
                job(ident,argv)
    elif args.group == 'reopen':
        inputs=json.loads((ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json').read_text(encoding='utf-8-sig'))
        master=Path(inputs['source_packages']['c5']['path'])/'models/c5-master.blend'
        local=OUT/'sources/c5-master.blend'
        local.parent.mkdir(exist_ok=True)
        if not local.exists():shutil.copy2(master,local)
        assert sha(master)==sha(local)
        write(run/'master-lineage.json',json.dumps({'source':str(master),'copy':str(local),'sha256':sha(local),'changed':False},indent=2))
        changed=OUT/'sources'/('r6-surface-master-'+args.version+'.blend')
        job('pack',['--background','--threads','8','--python-exit-code','1','--python',str(TOOLS/'pack_master.py'),'--',str(local),str(OUT/'projection-v01/c5-surface-fields.png'),str(TOOLS/'surface.json'),str(changed)],Path(inputs['tools']['blender']))
        job('reopen',['--background','--threads','8','--python-exit-code','1','--python',str(TOOLS/'reopen.py'),'--',str(changed),str(run/'reopen/report.json')],Path(inputs['tools']['blender']))
    spec=run/'jobs.json'
    write(spec,json.dumps(jobs,indent=2))
    print(spec)

if __name__ == '__main__':main()
