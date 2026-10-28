extends Node2D
## Full 16-frame sprite VFX, drawn separately from the approved fighter artwork.
const PULSE: Texture2D = preload("res://assets/effects/dark_pulse_vfx.png")
const DRAGON: Texture2D = preload("res://assets/effects/violet_dragon_vfx.png")
@onready var fighter: PhuzashiCharacter = get_parent()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _cell(sheet: Texture2D, index: int, center: Vector2, dimensions: Vector2, opacity: float = 1.0) -> void:
	var col: int = index % 4
	var row: int = floori(float(index) / 4.0)
	var size: Vector2 = sheet.get_size()
	var upper := Vector2(floorf(float(col) * size.x / 4.0), floorf(float(row) * size.y / 4.0))
	var lower := Vector2(floorf(float(col + 1) * size.x / 4.0), floorf(float(row + 1) * size.y / 4.0))
	var region := Rect2(upper, lower - upper)
	draw_texture_rect_region(sheet, Rect2(center - dimensions * 0.5, dimensions), region, Color(1, 1, 1, clampf(opacity, 0.0, 1.0)), false, true)

func _draw() -> void:
	if not is_instance_valid(fighter):
		return
	var d: float = float(fighter.facing)
	var t: float = fighter.elapsed
	if fighter.state_name == "GUARD":
		draw_arc(Vector2(d * 20, -87), 66, -1.3 if d > 0 else PI - 1.3, 1.3 if d > 0 else PI + 1.3, 24, Color(0.66, 0.45, 1, 0.7), 3, false)
	if fighter.action_timer <= 0.0:
		return
	var p: float = clampf(fighter.action_progress(), 0.0, 1.0)
	var envelope: float = sin(p * PI)
	match fighter.action_name:
		"PUNCH":
			if p > 0.28 and p < 0.7:
				for i in range(3):
					draw_line(Vector2(d * 45, -104 + i * 9), Vector2(d * (95 + envelope * 30), -104 + i * 9), Color(1, 0.91, 0.7, envelope * 0.8), 3, false)
		"KICK":
			if p > 0.3 and p < 0.75:
				var start: float = -1.4 if d > 0 else PI - 1.0
				draw_arc(Vector2(d * 25, -65), 92, start, start + 1.9, 25, Color(0.75, 0.92, 1, envelope * 0.9), 5, false)
		"HIT":
			var center := Vector2(d * 24, -99)
			for i in range(8):
				var ray := Vector2.from_angle(float(i) * TAU / 8.0)
				draw_line(center + ray * (8 + p * 20), center + ray * (18 + p * 40), Color(1, 0.65, 0.55, 1 - p), 3, false)
		"SPECIAL":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(d, 1))
			_special(p, t)
			draw_set_transform(Vector2.ZERO)
		"ULTIMATE":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(d, 1))
			_ultimate(p, t)
			draw_set_transform(Vector2.ZERO)

func _special(p: float, t: float) -> void:
	var hand := Vector2(49, -88)
	if p < 0.42:
		var q: float = p / 0.42
		_cell(PULSE, mini(3, floori(q * 4)), hand, Vector2(132, 132))
		for i in range(3):
			draw_arc(hand, 25 + i * 10 + q * 10, -t * (3 + i), -t * (3 + i) + PI * 1.4, 26, Color(0.7, 0.18, 1, (0.3 + q * 0.4) / (i + 1)), 3, false)
	elif p < 0.63:
		var q: float = (p - 0.42) / 0.21
		_cell(PULSE, 4 + mini(3, floori(q * 4)), hand + Vector2(q * 30, 0), Vector2(172, 144), 1.0 - q * 0.2)
	else:
		var fade: float = maxf(0.0, (1.0 - p) / 0.37)
		for i in range(10):
			var pos := hand + Vector2(12 + i * 7, sin(t * 17 + i * 2.0) * (8 + i))
			draw_rect(Rect2(pos, Vector2(3 + i % 2, 4)), Color(0.72, 0.2, 1, fade * 0.65))

func _ultimate(p: float, t: float) -> void:
	var power: float = sin(p * PI)
	# Ground rune and ascending sparks keep the character grounded while charging.
	draw_set_transform(Vector2(0, -2), 0, Vector2(1, 0.28))
	for i in range(3):
		draw_arc(Vector2.ZERO, 72 + i * 17 + power * 18, t * (i + 1), t * (i + 1) + PI * 1.7, 48, Color(0.65, 0.15, 1, power * 0.65), 4, false)
	draw_set_transform(Vector2.ZERO)
	for i in range(22):
		var x: float = sin(i * 8.1) * 72
		var y: float = -fmod(t * 145 + i * 19, 220)
		draw_rect(Rect2(Vector2(x, y), Vector2(3 + i % 3, 7 + i % 6)), Color(0.68, 0.14, 1, power * 0.7))
	if p < 0.35:
		var q: float = p / 0.35
		_cell(DRAGON, mini(3, floori(q * 4)), Vector2(5, -92), Vector2(220, 230))
	elif p < 0.49:
		var q: float = (p - 0.35) / 0.14
		_cell(DRAGON, 4 + mini(3, floori(q * 4)), Vector2(105, -145), Vector2(340, 280))
	elif p < 0.80:
		var q: float = (p - 0.49) / 0.31
		_cell(DRAGON, 8 + mini(3, floori(q * 4)), Vector2(245 + q * 65, -153), Vector2(590, 340))
		var trail := PackedVector2Array()
		for i in range(32):
			var u: float = float(i) / 31.0
			trail.append(Vector2(58 + u * (100 + q * 470), -106 - sin(u * TAU * 1.2 - t * 7) * (15 + u * 30)))
		draw_polyline(trail, Color(0.56, 0.11, 1, 0.32), 28, false)
		draw_polyline(trail, Color(0.92, 0.69, 1, 0.42), 8, false)
	else:
		var q: float = (p - 0.80) / 0.20
		_cell(DRAGON, 12 + mini(3, floori(q * 4)), Vector2(395, -155), Vector2(620, 345), 1.0 - q * 0.25)
