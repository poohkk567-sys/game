extends Node2D
const BACKDROP: Texture2D = preload("res://assets/stages/school_gate.png")
const THAI: Font = preload("res://assets/fonts/NotoSansThai-Regular.ttf")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(BACKDROP,Rect2(0,0,1280,720),false)
	# Accurate text is laid out by Godot instead of baked AI-generated lettering.
	_centered("โรงเรียนบรรหารแจ่มใสวิทยา ๕",Vector2(548,353),29,Color("e9cf86"))
	_centered("BANHARNJAMSAIWITTAYA 5 SCHOOL",Vector2(548,384),14,Color("dbc38c"),ThemeDB.fallback_font)
	_centered("อำเภอสองพี่น้อง จังหวัดสุพรรณบุรี",Vector2(548,414),18,Color("d0b97e"))

func _centered(line: String, point: Vector2, size: int, color: Color, font: Font = THAI) -> void:
	var width: float = font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(font,point-Vector2(width*0.5,0),line,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
