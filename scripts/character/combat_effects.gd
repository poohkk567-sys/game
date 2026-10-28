extends Node2D
## Effects are separate from the source character pixels.
@onready var fighter: PhuzashiCharacter = get_parent()

func _draw() -> void:
	var d: float = fighter.facing
	var t: float = fighter.elapsed
	if fighter.state_name == "GUARD":
		draw_arc(Vector2(d * 20, -87), 66, -1.3 if d > 0 else PI - 1.3, 1.3 if d > 0 else PI + 1.3, 24, Color(0.66, 0.45, 1, 0.7), 3, true)
	if fighter.action_timer <= 0.0:
		return
	var p: float = fighter.action_progress()
	var envelope: float = sin(p * PI)
	match fighter.action_name:
		"PUNCH":
			if p > 0.28 and p < 0.7:
				for i in range(3):
					draw_line(Vector2(d * 45, -104 + i * 9), Vector2(d * (95 + envelope * 30), -104 + i * 9), Color(1, 0.91, 0.7, envelope * 0.8), 3, true)
		"KICK":
			if p > 0.3 and p < 0.75:
				var start: float = -1.4 if d > 0 else PI - 1.0
				draw_arc(Vector2(d * 25, -65), 92, start, start + 1.9, 25, Color(0.75, 0.92, 1, envelope * 0.9), 5, true)
		"HIT":
			var center := Vector2(d * 24, -99)
			for i in range(8):
				var ray := Vector2.from_angle(i * TAU / 8)
				draw_line(center + ray * (8 + p * 20), center + ray * (18 + p * 40), Color(1, 0.65, 0.55, 1 - p), 3)
		"SPECIAL":
			if p < 0.48:
				var center := Vector2(d * 49, -88)
				draw_circle(center, 10 + p * 45, Color(0.55, 0.12, 1, envelope * 0.35))
				draw_arc(center, 18 + p * 30, t * 10, t * 10 + PI * 1.6, 24, Color("d486ff"), 4, true)
		"ULTIMATE":
			_draw_ultimate(d, p, t, envelope)

func _draw_ultimate(d: float, p: float, t: float, envelope: float) -> void:
	# Ground seal, rising violet embers, then a stylized energy dragon.
	draw_set_transform(Vector2(0, -2), 0, Vector2(1, 0.26))
	draw_arc(Vector2.ZERO, 72 + envelope * 25, t, t + TAU, 64, Color(0.7, 0.2, 1, envelope), 5, true)
	draw_set_transform(Vector2.ZERO)
	for i in range(22):
		var x: float = sin(i * 8.1) * 65
		var y: float = -fmod(t * 160 + i * 19, 220)
		draw_rect(Rect2(x, y, 3 + i % 3, 8 + i % 7), Color(0.68, 0.14, 1, envelope * 0.8))
	if p < 0.35 or p > 0.94:
		for i in range(3):
			draw_arc(Vector2(0, -75), 60 + i * 15, t * (i + 1), t * (i + 1) + PI * 1.5, 30, Color(0.65, 0.1, 1, envelope * 0.7), 3, true)
		return
	var reach: float = minf(1.0, (p - 0.35) / 0.2) * 530
	var curve := PackedVector2Array()
	for i in range(44):
		var u: float = i / 43.0
		curve.append(Vector2(d * (35 + u * reach), -98 - sin(u * TAU * 1.3 - p * 7) * (25 + u * 35)))
	for layer in range(4):
		var colors: Array[Color] = [Color(0.35,0.01,0.7,0.22), Color(0.5,0.03,1,0.7), Color(0.79,0.25,1,0.9), Color(0.95,0.8,1,1)]
		draw_polyline(curve, colors[layer] * Color(1,1,1,envelope), 60 - layer * 17, true)
	for i in range(3, 40, 3):
		var point: Vector2 = curve[i]
		draw_colored_polygon(PackedVector2Array([point + Vector2(-d * 15, -8), point + Vector2(-d * 4, -35 - i % 11), point + Vector2(d * 10, -8)]), Color(0.7, 0.13, 1, envelope))
	var head: Vector2 = curve[-1]
	var outline := PackedVector2Array([Vector2(-44,-22), Vector2(-25,-39), Vector2(-38,-68), Vector2(1,-39), Vector2(33,-21), Vector2(49,-5), Vector2(20,8), Vector2(42,22), Vector2(5,30), Vector2(-22,18), Vector2(-44,5)])
	for i in range(outline.size()):
		outline[i] = head + Vector2(outline[i].x * d, outline[i].y)
	draw_colored_polygon(outline, Color(0.14,0.02,0.28,envelope))
	var closed: PackedVector2Array = outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color(0.8,0.25,1,envelope), 4, true)
	draw_line(head + Vector2(d * 2,-15), head + Vector2(d * 22,-10), Color("f6dcff"), 5, true)
	for i in range(4):
		var tooth: Vector2 = head + Vector2(d * (8 + i * 6), 8)
		draw_colored_polygon(PackedVector2Array([tooth, tooth + Vector2(d * 4, 0), tooth + Vector2(d * 2, 9)]), Color(0.93,0.73,1,envelope))
