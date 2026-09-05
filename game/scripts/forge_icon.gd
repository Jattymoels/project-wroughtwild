class_name ForgeIcon
extends Control
## Small, code-owned catalogue silhouettes; no live viewport per card.
var item_id := ""
var material_id := "iron"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var scale := minf(size.x, size.y) / 100.0
	draw_set_transform(size * 0.5, -0.18, Vector2.ONE * scale)
	var metal := Color("a7aaa0")
	var timber := Color("9d7850")
	var pale := Color("d3bf92")
	if material_id in ["wood", "hide"]: metal = timber
	if "bow" in item_id:
		var curve := PackedVector2Array()
		for i in 25:
			var t := float(i) / 24.0
			curve.append(Vector2(sin(t * PI) * 25 - 12, t * 70 - 35))
		draw_polyline(curve, timber, 5, true)
		draw_line(Vector2(-12, -35), Vector2(-12, 35), pale, 1.5, true)
		draw_line(Vector2(-27, 0), Vector2(31, 0), metal, 2, true)
		draw_colored_polygon(PackedVector2Array([Vector2(35, 0), Vector2(24, -5), Vector2(24, 5)]), metal)
	elif "catalyst" in item_id or item_id in ["vanguard", "marrow", "quicksilver"] or "quicksilver" in item_id or "marrow" in item_id or "vanguard" in item_id:
		var tint := Color("bf835b") if "ember" in item_id else Color("8faeae") if "frost" in item_id else Color("b9ab88")
		draw_colored_polygon(PackedVector2Array([Vector2(0,-32),Vector2(24,-9),Vector2(17,23),Vector2(0,34),Vector2(-21,14),Vector2(-23,-12)]),tint.darkened(0.25))
		draw_colored_polygon(PackedVector2Array([Vector2(0,-32),Vector2(7,2),Vector2(-21,14),Vector2(-23,-12)]),tint)
		draw_line(Vector2(7,2),Vector2(17,23),pale,1.5,true)
	elif "ingot" in item_id or "fitting" in item_id:
		draw_colored_polygon(PackedVector2Array([Vector2(-33,-11),Vector2(18,-19),Vector2(35,-8),Vector2(-16,3)]),metal)
		draw_colored_polygon(PackedVector2Array([Vector2(-33,-11),Vector2(-16,3),Vector2(-16,21),Vector2(-37,6)]),metal.darkened(0.35))
		draw_colored_polygon(PackedVector2Array([Vector2(-16,3),Vector2(35,-8),Vector2(39,9),Vector2(-16,21)]),metal.darkened(0.18))
	elif "armour" in item_id or "vest" in item_id or "mail" in item_id:
		draw_colored_polygon(PackedVector2Array([Vector2(-10,-26),Vector2(-29,-18),Vector2(-35,1),Vector2(-20,7),Vector2(-18,29),Vector2(18,29),Vector2(20,7),Vector2(35,1),Vector2(29,-18),Vector2(10,-26),Vector2(6,-15),Vector2(-6,-15)]),metal)
		draw_line(Vector2(0,-12),Vector2(0,27),metal.darkened(0.4),2,true)
		draw_line(Vector2(-18,15),Vector2(18,15),timber.darkened(0.35),5,true)
	elif "shield" in item_id:
		draw_colored_polygon(PackedVector2Array([Vector2(-27,-28),Vector2(27,-28),Vector2(24,10),Vector2(0,34),Vector2(-24,10)]),metal)
		draw_circle(Vector2.ZERO,9,metal.darkened(0.3))
	elif "kit" in item_id or "frame" in item_id:
		draw_rect(Rect2(-32,-20,64,39),timber.darkened(0.25))
		for x in [-25,0,25]: draw_line(Vector2(x,-24),Vector2(x,23),pale,4,true)
		draw_line(Vector2(-35,-23),Vector2(35,-23),timber,6,true)
	else:
		draw_line(Vector2(-14,33),Vector2(8,-25),timber,7,true)
		draw_line(Vector2(-9,18),Vector2(-4,5),pale.darkened(0.25),9,true)
		if "mace" in item_id or "cudgel" in item_id:
			draw_colored_polygon(PackedVector2Array([Vector2(-7,-28),Vector2(10,-36),Vector2(25,-23),Vector2(19,-5),Vector2(0,-10)]),metal)
		else:
			draw_circle(Vector2(8,-26),12,metal)
			draw_arc(Vector2(8,-26),16,0.2,4.2,18,pale,2,true)
