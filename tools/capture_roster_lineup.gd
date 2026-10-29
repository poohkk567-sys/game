extends SceneTree
## Render actual in-game standing frames, not newly invented comparison poses.
const Rig = preload("res://scripts/character/phuzashi_rig.gd")
var board: Node2D
func _initialize() -> void: call_deferred("capture")
func label_at(line: String, point: Vector2, width: float, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = line
	label.position = point
	label.size = Vector2(width,48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	board.add_child(label)
func concept(point: Vector2) -> void:
	var picture := Image.load_from_file("res://docs/concepts/track_jacket_neutral.png")
	var mask := BitMap.new()
	mask.create_from_image_alpha(picture,0.5)
	var low := Vector2(INF,INF)
	var high := Vector2(-INF,-INF)
	for polygon: PackedVector2Array in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO,picture.get_size()),0.2):
		for p: Vector2 in polygon:
			low = Vector2(minf(low.x,p.x),minf(low.y,p.y))
			high = Vector2(maxf(high.x,p.x),maxf(high.y,p.y))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(picture)
	sprite.centered = false
	var factor: float = 156.0/(high.y-low.y)*1.6
	sprite.scale = Vector2.ONE*factor
	sprite.position = point-Vector2((low.x+high.x)*0.5,high.y)*factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout := ShaderMaterial.new()
	cutout.shader = load("res://assets/characters/phuzashi_chill/chill_cutout.gdshader")
	sprite.material = cutout
	board.add_child(sprite)
func capture() -> void:
	root.get_node("Gamepads").settings_panel.visible = false
	root.content_scale_size = Vector2i(1920,760)
	root.size = Vector2i(1920,760)
	board = Node2D.new()
	root.add_child(board)
	var font := Theme.new()
	font.default_font = load("res://assets/fonts/NotoSansThai-Regular.ttf")
	root.theme = font
	var backdrop := ColorRect.new()
	backdrop.color = Color("131b29")
	backdrop.size = Vector2(1920,760)
	board.add_child(backdrop)
	label_at("PHUZASHI — DARK PULSE",Vector2(0,45),1920,40,Color("eee7ff"))
	label_at("ภาพยืนจากเกมจริง • ใช้พื้นระดับเดียวกัน • ไม่แสดงออร่า",Vector2(0,108),1920,22,Color("b6c4d7"))
	label_at("5 ตัวเลือกเล่น + 1 คอนเซปต์ + ร่างแปลงและตัวช่วย",Vector2(0,151),1920,20,Color("d0acfa"))
	var profiles: Array[String] = ["PHUZASHI","PHUZASHI_CHILL","RED_CAP","MUAY_THAI","BLACK_COAT","CONCEPT","AWAKENED","ASSIST"]
	var names: Array[String] = ["PHUZASHI","PHUZASHI CHILL","ASSJIRO","MUAY THAI","BLACK COAT","TRACK JACKET","ASSJIRO AWAKENED","CHEER ASSIST"]
	for i in range(profiles.size()):
		var point := Vector2(135+i*235,600)
		var card := ColorRect.new()
		card.position = Vector2(point.x-111,250)
		card.size = Vector2(222,430)
		card.color = Color(0.10,0.13,0.20,0.75 if i%2 else 0.35)
		board.add_child(card)
		var floor_line := Line2D.new()
		floor_line.points = PackedVector2Array([Vector2(point.x-106,602),Vector2(point.x+106,602)])
		floor_line.width = 2
		floor_line.default_color = Color("68768e")
		board.add_child(floor_line)
		if profiles[i] == "CONCEPT":
			concept(point)
		elif profiles[i] == "ASSIST":
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = load("res://assets/characters/phuzashi_clear/cheer_assist_frames.res")
			sprite.animation = "CHEER"
			sprite.frame = 0
			sprite.centered = false
			var factor: float = 148.0/float(sprite.sprite_frames.get_meta("source_height"))*1.6
			sprite.scale = Vector2.ONE*factor
			sprite.position = point-Vector2(512,960)*factor
			board.add_child(sprite)
		else:
			var wrapper := Node2D.new()
			wrapper.position = point
			wrapper.scale = Vector2.ONE*1.6
			board.add_child(wrapper)
			var rig: Node2D = Rig.new()
			wrapper.add_child(rig)
			rig.set_clear_enabled(true)
			rig.set_character_profile("RED_CAP" if profiles[i] == "AWAKENED" else profiles[i])
			if profiles[i] == "AWAKENED": rig.set_red_awakened(true)
			rig.animate("IDLE",1.0/60,1,0)
		label_at(names[i],Vector2(point.x-116,620),232,18,Color("ffe3ad") if i == 5 else Color("ebe8ff"))
		label_at("คอนเซปต์ / ยังไม่มีท่า" if i == 5 else ("ร่างแปลง" if i == 6 else ("ตัวช่วยสกิล" if i == 7 else "เลือกเล่นได้")),Vector2(point.x-116,654),232,16,Color("cba4ef"))
	for _i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/pact_preview_all_characters.png")
	quit()
