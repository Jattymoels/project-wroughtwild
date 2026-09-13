extends "res://g1/paid.gd"
## Fresh process, same paid world. Only the native controller moves during walk.
func execute():
	get_window().size=Vector2i(1440,900)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	check(SaveManager.new().read("res://g1/paid-home.json",player),"motion starts from the actual paid home")
	freeze_fixtures();refresh_stations()
	await walk_route()
	complete()
