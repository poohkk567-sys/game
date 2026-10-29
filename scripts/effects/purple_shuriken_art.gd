extends RefCounted
## Crisp four-bladed ninja star; geometry rotates while its collision stays fixed.
static func draw(canvas: CanvasItem, center: Vector2, angle: float, size: float = 1, opacity: float = 1) -> void:
	canvas.draw_set_transform(center,angle,Vector2.ONE*size)
	var outline := PackedVector2Array()
	for blade in range(4):
		for point: Vector2 in [Vector2(0,-41),Vector2(16,-13),Vector2(11,-2)]:
			outline.append(point.rotated(blade*PI/2))
	for layer in [1.32,1.14]:
		var glow := PackedVector2Array()
		for point: Vector2 in outline: glow.append(point*layer)
		canvas.draw_colored_polygon(glow,Color(0.57,0.12,1,opacity*(0.13 if layer > 1.2 else 0.3)))
	canvas.draw_colored_polygon(outline,Color(0.25,0.04,0.46,opacity))
	var edge: PackedVector2Array = outline.duplicate()
	edge.append(edge[0])
	canvas.draw_polyline(edge,Color(0.77,0.41,1,opacity),2,false)
	for blade in range(4):
		var rotation: float = blade*PI/2
		var facet := PackedVector2Array([Vector2(0,-37).rotated(rotation),Vector2(12,-13).rotated(rotation),Vector2(4,-4).rotated(rotation)])
		canvas.draw_colored_polygon(facet,Color(0.66,0.22,0.94,opacity))
		canvas.draw_line(Vector2(0,-36).rotated(rotation),Vector2(3,-12).rotated(rotation),Color(0.96,0.81,1,opacity),2,false)
	canvas.draw_circle(Vector2.ZERO,9,Color(0.11,0.02,0.2,opacity))
	canvas.draw_arc(Vector2.ZERO,8,0,TAU,12,Color(0.9,0.6,1,opacity),2,false)
	canvas.draw_circle(Vector2.ZERO,3,Color(0.05,0.01,0.1,opacity))
	canvas.draw_set_transform(Vector2.ZERO)
