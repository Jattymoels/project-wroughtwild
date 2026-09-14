"""Native input traversal: timing only, fresh private process, no image capture."""
import argparse
from measure import BUILD, write, replace


def install(version):
    base=BUILD/version;game=base/'runtime/game'
    paid=(game/'g1/paid.gd').read_text()
    method=paid[paid.index('func walk_route():'):paid.index('func _home(')]
    method=replace(method,'\tInput.action_press("move_forward")','\tr2_tick=Time.get_ticks_usec();r2_recording=true\n\tInput.action_press("move_forward")')
    method=replace(method,'\tInput.action_release("move_forward")','\tr2_recording=false\n\tInput.action_release("move_forward")')
    source='''extends "res://g1/walk_review.gd"
var r2_recording:=false
var r2_tick:=0
var r2_frames:Array[float]=[]
func r2_frame():
	var now:=Time.get_ticks_usec()
	if r2_recording:r2_frames.append(float(now-r2_tick)/1000.0)
	r2_tick=now
func execute():
	get_window().size=Vector2i(1440,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	check(not "--capture" in OS.get_cmdline_user_args(),"R2 traversal timing contains no captures")
	check(SaveManager.new().read("res://g1/paid-home.json",player),"traversal starts at unchanged actual paid checkpoint")
	freeze_fixtures();refresh_stations()
	get_tree().process_frame.connect(r2_frame)
	await walk_route()
	var sorted:=r2_frames.duplicate();sorted.sort()
	check(sorted.size()>300,"R2 traversal records real process intervals")
	FileAccess.open(output+"/traversal.json",FileAccess.WRITE).store_string(JSON.stringify({"frames_ms":r2_frames,"frame_count":sorted.size(),"median_ms":sorted[sorted.size()/2],"p95_ms":sorted[int(sorted.size()*.95)],"worst_ms":sorted[-1],"walk":report.walk,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"gpu":RenderingServer.get_video_adapter_name(),"gpu_api":RenderingServer.get_video_adapter_api_version(),"viewport":str(get_window().size),"msaa":get_viewport().msaa_3d,"vsync":DisplayServer.window_get_vsync_mode(),"scope":"Uncaptured actual G1 input/controller route. Process wall intervals during traversal; distinct from settled-camera benchmarks and import/setup."},"  "))
	complete()
'''+method
    write(game/'r2/traversal.gd',source)
    write(game/'r2/traversal.tscn',(game/'g1/walk_review.tscn').read_text().replace('res://g1/walk_review.gd','res://r2/traversal.gd'))
    jobs=[]
    for renderer in ['forward_plus','gl_compatibility']:
        for mode in (['baseline','art'] if version=='v01' else ['art']):
            ident='traversal-'+mode+'-'+renderer
            args=['--rendering-method',renderer,'--path',str(game),'res://r2/traversal.tscn','--','--benchmark','--run-id='+ident]
            if mode=='baseline':args.append('--baseline')
            jobs.append({'id':ident,'program':str(base/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':args,'log':str(base/'logs'/(ident+'.log')),'state':str(base/'users'/ident)})
    write(base/'traversal-jobs.json',jobs)
    print('R2_TRAVERSAL_INSTALLED',version,len(jobs))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();install(a.version)
