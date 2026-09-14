extends "res://r1/paid.gd"
## Replay the retained input/controller route; timing and image runs are separate.
var r1_measuring:=false
var r1_wall:Array[float]=[]
var r1_previous:=0
func _process(_delta:float):
	if r1_measuring:
		var now:=Time.get_ticks_usec()
		r1_wall.append(float(now-r1_previous)/1000.0);r1_previous=now
func execute():
	get_window().size=Vector2i(1440,900);get_viewport().msaa_3d=Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	check(SaveManager.new().read("res://g1/paid-home.json",player),"route starts from actual retained paid home")
	freeze_fixtures();refresh_stations()
	report["device"]={"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(get_viewport().size),"msaa":"4x","vsync":"off","timing_separate_from_capture":not "--capture" in OS.get_cmdline_user_args()}
	r1_previous=Time.get_ticks_usec();r1_measuring="--benchmark" in OS.get_cmdline_user_args()
	await walk_route()
	r1_measuring=false
	if not r1_wall.is_empty():
		r1_wall.sort()
		report["streaming_frames"]={"samples":r1_wall.size(),"p50_ms":r1_wall[r1_wall.size()/2],"p95_ms":r1_wall[int(r1_wall.size()*.95)],"worst_ms":r1_wall[-1],"scope":"Wall frames during original controller route including source streaming. No image capture or model generation in this process."}
	complete()
