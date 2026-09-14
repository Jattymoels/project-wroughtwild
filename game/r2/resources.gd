extends RefCounted
## R2 exact texture aliases; materials retain their original samplers and state.
static var aliases:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://r2/texture-aliases.json"))
static func resource(path:String)->Resource:
	return load(String(aliases.get(path,path)))
