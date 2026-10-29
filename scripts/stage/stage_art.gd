extends Node2D
## Static artwork is drawn once. All mountain outlines have an ordered ridge
## strictly above their shared base, so triangulation cannot self-intersect.
const WIDTH: float = 1280.0
const FLOOR: float = 586.0
var mountain_polygons: Array[PackedVector2Array] = []

func _ready() -> void:
	queue_redraw()

func mountain_points(x: float, peak: float, width: float, base: float = 370.0) -> PackedVector2Array:
	var top: float = minf(peak, base - 95.0)
	return PackedVector2Array([
		Vector2(x - width, base), Vector2(x - width * 0.58, top + 90),
		Vector2(x - width * 0.28, top + 64), Vector2(x, top),
		Vector2(x + width * 0.18, top + 43), Vector2(x + width * 0.44, top + 69),
		Vector2(x + width, base)
	])

func _draw() -> void:
	mountain_polygons.clear()
	for row in range(75):
		draw_rect(Rect2(0, row * 8, WIDTH, 8), Color("427bb6").lerp(Color("c5e5d7"), row / 75.0))
	draw_circle(Vector2(1000, 168), 54, Color(0.96, 0.94, 0.75, 0.33))
	draw_circle(Vector2(1000, 168), 39, Color("f5eaca"))
	for i in range(9):
		_cloud(float((i * 193 + 25) % 1280), float(122 + (i * 31) % 100))
	_mountain(260, 169, 340, Color("719dac"))
	_mountain(640, 128, 385, Color("5b8caa"))
	_mountain(1060, 194, 370, Color("648d9b"))
	_mountain(88, 252, 310, Color("467d8e"))
	_mountain(900, 232, 330, Color("3c788a"))
	draw_rect(Rect2(0, 365, WIDTH, 221), Color("4e916d"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,424),Vector2(160,382),Vector2(390,408),Vector2(620,378),Vector2(860,406),Vector2(1090,390),Vector2(1280,419),Vector2(1280,586),Vector2(0,586)]), Color("7bac76"))
	for i in range(54):
		_pine(float(i * 25 + i % 4 * 7), float(371 + (i * 13) % 40), float(26 + (i * 19) % 38))
	draw_rect(Rect2(0, 461, WIDTH, 125), Color("95b985"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,539),Vector2(400,483),Vector2(800,505),Vector2(1280,476),Vector2(1280,586),Vector2(0,586)]), Color("c4c397"))
	for i in range(130):
		var point := Vector2((i * 97 + 17) % 1280, 452 + (i * 41) % 128)
		draw_rect(Rect2(point, Vector2(3, 6)), Color("6c9c6e"))
		if i % 4 == 0:
			draw_rect(Rect2(point + Vector2(3, 1), Vector2(3, 3)), Color("e2d6ad"))
	_stone_lantern(121, 547)
	_stone_lantern(1153, 547)
	# Two distant banners frame the playable training lane.
	for x: float in [180.0, 1100.0]:
		draw_rect(Rect2(x, 354, 6, 211), Color("49485b"))
		draw_rect(Rect2(x - 5, 349, 72, 5), Color("35364a"))
		draw_colored_polygon(PackedVector2Array([Vector2(x+7,359),Vector2(x+58,359),Vector2(x+58,447),Vector2(x+32,435),Vector2(x+7,447)]), Color("343052"))
		draw_line(Vector2(x+14,367), Vector2(x+14,427), Color("8267a0"), 2)
		draw_arc(Vector2(x+35,390), 12, 0, TAU, 16, Color("c4a0e3"), 2)
		draw_line(Vector2(x+30,397), Vector2(x+41,381), Color("e0c7ff"), 3)
	# Ground surface aligns exactly with the physics collider at y=586.
	draw_rect(Rect2(0, FLOOR, WIDTH, 134), Color("77798a"))
	draw_rect(Rect2(0, FLOOR, WIDTH, 5), Color("e2dfc7"))
	draw_rect(Rect2(0, FLOOR + 5, WIDTH, 8), Color("53596a"))
	for row in range(4):
		var y: float = FLOOR + 14 + row * 34
		draw_line(Vector2(0,y), Vector2(WIDTH,y), Color("545b6c"), 2)
		for column in range(13):
			var x: float = column * 112.0 + (56.0 if row % 2 else 0.0)
			draw_line(Vector2(x,y), Vector2(x-7,y+34), Color("545b6c"), 2)
			draw_line(Vector2(x+5,y+4), Vector2(x+95,y+4), Color("898b99"), 1)
	for x in range(80, 1280, 140):
		draw_rect(Rect2(x, 605, 33, 2), Color("b8b4b7"))
		draw_rect(Rect2(x+15, 601, 2, 10), Color("b8b4b7"))

func _mountain(x: float, peak: float, width: float, tint: Color) -> void:
	var points: PackedVector2Array = mountain_points(x, peak, width)
	mountain_polygons.append(points)
	draw_colored_polygon(points, tint)
	var top: float = points[3].y
	draw_colored_polygon(PackedVector2Array([Vector2(x,top),Vector2(x+width*0.18,top+43),Vector2(x+width*0.44,top+69),Vector2(x+width,370),Vector2(x+width*0.07,370)]), tint.darkened(0.18))
	# Snow is a separate simple polygon; its ridge never crosses itself.
	draw_colored_polygon(PackedVector2Array([Vector2(x-width*0.28,top+64),Vector2(x,top),Vector2(x+width*0.18,top+43),Vector2(x+width*0.11,top+62),Vector2(x+width*0.015,top+38),Vector2(x-width*0.055,top+58),Vector2(x-width*0.13,top+47)]), Color("d5e6e8"))
	for i in range(7):
		var y: float = top + 95 + i * 23
		if y < 365:
			draw_line(Vector2(x-width*0.34-i*5,y), Vector2(x-width*0.13,y-15), tint.lightened(0.07), 3)

func _cloud(x: float, y: float) -> void:
	draw_rect(Rect2(x, y+14, 109, 13), Color(0.87,0.95,0.95,0.5))
	draw_rect(Rect2(x+16,y+5,38,20), Color(0.94,0.98,0.96,0.65))
	draw_rect(Rect2(x+45,y,37,25), Color(0.94,0.98,0.96,0.65))

func _pine(x: float, y: float, height: float) -> void:
	draw_rect(Rect2(x-2,y,4,18), Color("4a6455"))
	for tier in range(3):
		var h: float = height * (0.65 + tier * 0.15)
		var yy: float = y-height+tier*height*0.25
		draw_colored_polygon(PackedVector2Array([Vector2(x,yy),Vector2(x-h*0.36,yy+h*0.68),Vector2(x+h*0.36,yy+h*0.68)]), Color("306b5c") if tier % 2 else Color("3c7c60"))

func _stone_lantern(x: float, y: float) -> void:
	draw_rect(Rect2(x-19,y-8,38,8), Color("777e87"))
	draw_rect(Rect2(x-7,y-55,14,47), Color("8b9296"))
	draw_rect(Rect2(x-16,y-76,32,27), Color("78818b"))
	draw_rect(Rect2(x-8,y-70,16,16), Color("d7c7a4"))
	draw_colored_polygon(PackedVector2Array([Vector2(x-27,y-76),Vector2(x-13,y-90),Vector2(x+13,y-90),Vector2(x+27,y-76)]), Color("646d7d"))
