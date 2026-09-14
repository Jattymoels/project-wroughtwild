extends RefCounted
## Diagnostic-only timers; never retain loaded resources or alter their state.
static var spans:Dictionary={}
static func record(label:String, started:int)->void:
	var elapsed:=Time.get_ticks_usec()-started
	if not spans.has(label):spans[label]={"calls":0,"usec":0,"max_usec":0}
	spans[label].calls+=1;spans[label].usec+=elapsed;spans[label].max_usec=maxi(spans[label].max_usec,elapsed)
static func resource(path:String)->Resource:
	var started:=Time.get_ticks_usec()
	var result:=load(path)
	record("load:"+path,started)
	return result
