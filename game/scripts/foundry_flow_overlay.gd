class_name FoundryFlowOverlay
extends Control
var paths: Array = []

func _draw() -> void:
	var drawn := {}
	for points in paths:
		for i in points.size() - 1:
			var start: Vector2 = points[i]
			var end: Vector2 = points[i + 1]
			var key := str(start) + str(end)
			if drawn.has(key): continue
			drawn[key] = true
			var direction := start.direction_to(end)
			# Keep arrows in the cell gaps so long resolved names remain legible.
			var edge := maxf(0.0, (start.distance_to(end) - 12.0) * .5)
			var a := start + direction * edge
			var b := end - direction * edge
			var colour := Color("b9d1bc")
			draw_line(a, b, Color(0.06, 0.08, 0.07, 0.9), 5, true)
			draw_line(a, b, colour, 2, true)
			draw_line(b, b - direction.rotated(0.5) * 7, colour, 2, true)
			draw_line(b, b - direction.rotated(-0.5) * 7, colour, 2, true)
