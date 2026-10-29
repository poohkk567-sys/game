extends SceneTree
var samples: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func inspect(viewport: SubViewport, label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(viewport.get_texture().get_image(),0.5)
	var large: int = 0
	var clipped: bool = false
	for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(0,0,512,360),0.2):
		var area: float = 0
		for i in range(polygon.size()):
			area += polygon[i].cross(polygon[(i+1)%polygon.size()])
			clipped = clipped or polygon[i].x <= 1 or polygon[i].x >= 511 or polygon[i].y <= 1
		if absf(area)*0.5 > 500: large += 1
	if large < 1 or clipped:
		failures += 1
		push_error("Roster render "+label+" body="+str(large)+" clipped="+str(clipped))
	samples += 1
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512,360)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rig: Node2D = load("res://scripts/character/phuzashi_rig.gd").new()
	viewport.add_child(rig)
	rig.position = Vector2(256,310)
	rig.set_character_profile("MUAY_THAI")
	for direction: int in [-1,1]:
		for clip: StringName in rig.draft_animation.sprite_frames.get_animation_names():
			for index in range(8):
				rig.animate(clip,1.0/60,direction,float(index)/8)
				rig.draft_animation.frame = index
				await inspect(viewport,"MUAY "+clip+"/"+str(index)+" dir="+str(direction))
	rig.set_clear_enabled(true)
	rig.set_character_profile("PHUZASHI")
	for direction: int in [-1,1]:
		for index in range(8):
			rig.animate("WALK",1.0/60,direction,float(index)/8)
			await inspect(viewport,"WALK "+str(index)+" dir="+str(direction))
	rig.queue_free()
	await process_frame
	for bank: String in ["fino_ultimate","cheer_assist"]:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = load("res://assets/characters/phuzashi_clear/"+bank+"_frames.res")
		sprite.centered = false
		viewport.add_child(sprite)
		var factor: float = (188.0 if bank == "fino_ultimate" else 148.0)/float(sprite.sprite_frames.get_meta("source_height"))
		for direction: int in [-1,1]:
			sprite.scale = Vector2(factor*direction,factor)
			sprite.position = Vector2(256,310)-Vector2(512*direction,960)*factor
			for clip: StringName in sprite.sprite_frames.get_animation_names():
				sprite.animation = clip
				for index in range(sprite.sprite_frames.get_frame_count(clip)):
					sprite.frame = index
					await inspect(viewport,bank+"/"+clip+"/"+str(index))
		sprite.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	print("ROSTER RENDER RESULT: %d samples, %d failures" % [samples,failures])
	quit(1 if failures else 0)
