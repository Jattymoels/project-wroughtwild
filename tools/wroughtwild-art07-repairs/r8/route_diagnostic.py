"""Read-only movement diagnostics: preserve every original route assertion."""
from pathlib import Path
import json
from inspect_inputs import ROOT,read
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';game=out/'runtime/game'
source=(game/'r8/paid.gd').read_text(encoding='utf-8-sig');start=source.index('func walk_route():');end=source.index('\nfunc ',start+1);method=source[start:end]
needle='\t\t\tif frame%20==0:positions.append([previous.x,previous.y,previous.z])'
assert method.count(needle)==1
method=method.replace(needle,needle+'''
\t\t\tif frame%20==0:
\t\t\t\tvar hits:Array=[]
\t\t\t\tfor h in player.get_slide_collision_count():
\t\t\t\t\tvar hit:=player.get_slide_collision(h)
\t\t\t\t\tvar collider:=hit.get_collider()
\t\t\t\t\thits.append({"path":str(collider.get_path()),"class":collider.get_class(),"normal":str(hit.get_normal()),"point":str(hit.get_position())})
\t\t\t\ttrace.append({"waypoint":i,"frame":frame,"at":str(player.position),"target":str(target),"forward":Input.is_action_pressed("move_forward"),"input":str(Input.get_vector("move_left","move_right","move_forward","move_back")),"velocity":str(player.velocity),"rooted":player.combat.rooted(),"help":player.hud.help_visible(),"palette":player.build_palette.is_open(),"hits":hits})
''')
s='''extends "res://r8/paid.gd"
var trace:Array=[]
func execute():
    var file:String
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--r8-checkpoint="):file=arg.trim_prefix("--r8-checkpoint=")
    assert(not file.is_empty())
    var manager:=SaveManager.new()
    check(manager.read(file,player),"diagnostic reads actual paid checkpoint")
    freeze_fixtures();refresh_stations();terrain.set_process(false)
    await walk_route()
    FileAccess.open(output+"/route-diagnostic.json",FileAccess.WRITE).store_string(JSON.stringify({"trace":trace,"walk":report.walk,"checks":checks,"failures":failures},"  "))
    complete()
'''+method
write(game/'r8/route_diagnostic.gd',s.expandtabs(4))
write(game/'r8/route_diagnostic.tscn',(game/'r8/paid.tscn').read_text(encoding='utf-8-sig').replace('res://r8/paid.gd','res://r8/route_diagnostic.gd'))
jobs=[]
for mode in ['art','baseline']:
 ident='route-diagnostic-'+mode+'-01';jobs.append({'id':ident,'program':str(out/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':['--rendering-method','forward_plus','--fixed-fps','60','--path',str(game),'res://r8/route_diagnostic.tscn','--','--r8-no-mouse-capture','--run-id='+ident,'--r8-checkpoint='+str(out/'users/paid-art-forward_plus/ART07G1/g1-paid.json')]+(['--baseline'] if mode=='baseline' else []),'log':str(out/'logs'/(ident+'.log')),'state':str(out/'users'/ident)})
write(out/'jobs-route-diagnostic-01.json',jobs)
