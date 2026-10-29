extends SceneTree
var samples: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640,420)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for spec: Array in [["characters/phuzashi_clear/fino_ultimate",188],["characters/muay_thai/motion_smooth",187.2],["effects/carrot_cyclone",190]]:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = load("res://assets/"+spec[0]+"_frames.res")
		sprite.centered = false
		viewport.add_child(sprite)
		var factor: float = float(spec[1])/float(sprite.sprite_frames.get_meta("source_height"))
		for direction: int in [-1,1]:
			sprite.scale = Vector2(factor*direction,factor)
			sprite.position = Vector2(320,390)-Vector2(512*direction,960)*factor
			for clip: StringName in sprite.sprite_frames.get_animation_names():
				sprite.animation = clip
				for index in range(sprite.sprite_frames.get_frame_count(clip)):
					sprite.frame = index
					await process_frame
					await RenderingServer.frame_post_draw
					var bitmap := BitMap.new()
					bitmap.create_from_image_alpha(viewport.get_texture().get_image(),0.5)
					var large: int = 0
					var clipped: bool = false
					for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(0,0,640,420),0.2):
						var area: float = 0
						for i in range(polygon.size()):
							area += polygon[i].cross(polygon[(i+1)%polygon.size()])
							clipped = clipped or polygon[i].x <= 1 or polygon[i].x >= 639 or polygon[i].y <= 1 or polygon[i].y >= 419
						if absf(area)*0.5 > 300: large += 1
					if large < 1 or clipped:
						failures += 1
						push_error("Chord render "+spec[0]+"/"+str(index)+" dir="+str(direction)+" body="+str(large)+" clipped="+str(clipped))
					samples += 1
		sprite.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	print("CHORD RENDER RESULT: %d samples, %d failures" % [samples,failures])
	quit(1 if failures else 0)
