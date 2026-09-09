"""Install F5-only measurement adapter; original native/capture assertions stay intact."""
import sys,re,json
from pathlib import Path
from audit import sha
package=Path(sys.argv[1]).resolve()
records=[]
for colour in ['red','white','blue','green']:
    path=package/colour/'review/review.gd';text=path.read_text(encoding='utf-8-sig')
    before=sha(path)
    method='set_shade(dark)' if colour=='red' else 'shade=dark'
    apply='update_visuals()' if colour=='red' else 'refresh()'
    assert 'var hold_simulation' in text and 'func '+apply[:-2]+'(' in text
    views='["source","buffer","overview"]' if colour=='red' else '["source","post","overview"]'
    body='''func benchmark() -> void:
	hold_simulation=true
	var viewport:=get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport,true)
	var results:Array=[]
	for view_name in VIEWS:
		set_shot(view_name)
		for dark in [false,true]:
			SHADE
			APPLY
			var wall:Array=[];var gpu:Array=[];var cpu:Array=[]
			var previous:=Time.get_ticks_usec()
			for frame in 210:
				await RenderingServer.frame_post_draw
				var now:=Time.get_ticks_usec()
				if frame>=60:
					wall.append((now-previous)/1000.0)
					gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport))
					cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport))
				previous=now
			wall.sort();gpu.sort();cpu.sort()
			results.append({"shot":view_name,"shade":dark,"lod":lod,"frame_p50_ms":wall[75],"frame_p95_ms":wall[142],"frame_worst_ms":wall[-1],"gpu_p50_ms":gpu[75],"gpu_p95_ms":gpu[142],"gpu_worst_ms":gpu[-1],"render_cpu_p50_ms":cpu[75],"render_cpu_p95_ms":cpu[142],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	var result:={"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"resolution":[1600,1000],"msaa":"4x","bloom":false,"warmup_frames":60,"sample_frames":150,"vsync_mode":DisplayServer.window_get_vsync_mode(),"cases":results,"scope":"Settled unchanged ART-04 review with original backdrop; native clocks held. No streaming or low-spec certification."}
	FileAccess.open(evidence_directory+"/performance.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("F5_BENCHMARK_COMPLETE")
	get_tree().quit()
'''
    body=body.replace('VIEWS',views).replace('SHADE',method).replace('APPLY',apply)
    updated=re.sub(r'^func benchmark\(\) -> void:.*?(?=^func |\Z)',lambda m:body+'\n',text,flags=re.M|re.S)
    assert updated!=text and 'F5_BENCHMARK_COMPLETE' in updated
    path.write_text(updated,encoding='utf-8')
    records.append({'colour':colour,'file':str(path),'before_sha256':before,'after_sha256':sha(path),'change':'Benchmark-only frame/worst/primitives telemetry. Capture and native test assertions unchanged.'})
(package/'audit/measurement-adapter.json').write_text(json.dumps(records,indent=2))
