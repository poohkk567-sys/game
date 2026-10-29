extends RefCounted
const SHEET: Texture2D = preload("res://assets/effects/six_skills_vfx.png")

static func frame(canvas: CanvasItem, index: int, center: Vector2, dimensions: Vector2, opacity: float = 1) -> void:
	var size: Vector2 = SHEET.get_size()/4
	var region := Rect2(Vector2(index%4,floori(float(index)/4))*size,size)
	canvas.draw_texture_rect_region(SHEET,Rect2(center-dimensions*0.5,dimensions),region,Color(1,1,1,opacity),false,true)
