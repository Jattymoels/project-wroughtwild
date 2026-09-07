extends "res://tests/environment_ambience.gd"
## Same actual listener and map surface contract against baseline and current.
## Accelerated elapsed-time dispatch measures coverage, not speaker output.
func _run() -> void:
	_small_map()
	var report := []
	var native_before := sim.export_json()
	for context in ["meadow","vegetation","exposed_stone","shelter"]:
		player.position.x=3 if context=="vegetation" else (7 if context=="exposed_stone" else 1)
		player.combat.sheltered=context=="shelter"
		ambience.reset_context()
		var sounding := 0.0
		var longest := 0.0
		var quiet := 0.0
		var max_voices := 0
		for tick in 1800:
			ambience._process(0.1)
			var active := 0
			for voice in ambience._voices:
				if voice.playing and voice.volume_linear>0.0: active+=1
			max_voices=maxi(max_voices,active)
			if active>0: sounding+=0.1; quiet=0.0
			else: quiet+=0.1; longest=maxf(longest,quiet)
		check(longest>=12.0,context+" has meaningful quiet gaps")
		check(sounding<=36.0,context+" ambience occupies at most20percent of three minutes")
		report.append({"context":context,"seconds":180,"sounding_seconds":sounding,"longest_quiet_seconds":longest,"max_voices":max_voices})
	check(sim.export_json()==native_before,"three-minute contexts do not alter native state")
	var file := FileAccess.open("res://ambient-quiet-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("AMBIENT_QUIET_REVIEW ",JSON.stringify(report))
	print("AMBIENT_QUIET %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
