extends SceneTree
var stage: Node2D
func _initialize() -> void: call_deferred("capture")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/pact_preview_"+label+".png")
func prepare(profile: String) -> void:
	stage.restart_match()
	stage.phase = "FIGHT"
	stage.p1.select_fighter(profile)
	stage.p2.select_fighter("RED_CAP")
	stage.p1.controls_enabled = true
	stage.p2.controls_enabled = true
	stage.p1.position.x = 480
	stage.p2.position.x = 760
	stage.p1.energy = 100
	await frames(6)
func capture() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(8)
	await prepare("BLACK_COAT")
	stage.p1.start_action("ULTIMATE")
	await frames(12)
	await shot("cutin")
	await frames(45)
	await shot("fat_slash")
	await frames(72)
	await shot("red_guardian")
	await prepare("PHUZASHI")
	stage.p1.cheer_buff = 8
	stage.p2.position.x = 670
	stage.p1.start_action("DEMON_BIND")
	await frames(40)
	await shot("purple_bind")
	await prepare("RED_CAP")
	stage.p1.start_action("ULTIMATE")
	await frames(210)
	await shot("gold_guardian")
	stage.queue_free()
	await frames(3)
	# Design only: render the latest concept next to ASSJIRO at the same height.
	var comparison := Node2D.new()
	root.add_child(comparison)
	var panel := ColorRect.new()
	panel.color = Color("18202c")
	panel.size = Vector2(1280,720)
	comparison.add_child(panel)
	var ass: Node2D = load("res://scripts/character/phuzashi_rig.gd").new()
	comparison.add_child(ass)
	ass.set_character_profile("RED_CAP")
	ass.position = Vector2(460,510)
	ass.animate("IDLE",1.0/60,1,0)
	var image: Image = Image.load_from_file("res://docs/concepts/track_jacket_neutral.png")
	var mask := BitMap.new()
	mask.create_from_image_alpha(image,0.5)
	var used := Rect2i(100000,100000,0,0)
	var end := Vector2i.ZERO
	for polygon: PackedVector2Array in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),0.2):
		for p: Vector2 in polygon:
			used.position = Vector2i(mini(used.position.x,int(p.x)),mini(used.position.y,int(p.y)))
			end = Vector2i(maxi(end.x,int(p.x)),maxi(end.y,int(p.y)))
	used.size = end-used.position
	var model := Sprite2D.new()
	model.texture = ImageTexture.create_from_image(image)
	model.centered = false
	model.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material_cutout := ShaderMaterial.new()
	material_cutout.shader = load("res://assets/characters/drafts/alpha_cutout.gdshader")
	model.material = material_cutout
	var factor: float = 156.0/used.size.y
	model.scale = Vector2.ONE*factor
	model.position = Vector2(820,510)-Vector2(used.get_center().x,used.end.y)*factor
	comparison.add_child(model)
	for spec: Array in [["DESIGN ONLY / SAME HEIGHT AS ASSJIRO",Vector2(300,210)],["ASSJIRO",Vector2(415,540)],["BLACK / GOLD TRACK JACKET",Vector2(710,540)],["156 px / NO MOVESET YET",Vector2(700,576)]]:
		var label := Label.new()
		label.text = spec[0]
		label.position = spec[1]
		label.add_theme_font_size_override("font_size",20)
		comparison.add_child(label)
	await frames(3)
	await shot("track_design_scale")
	quit()
