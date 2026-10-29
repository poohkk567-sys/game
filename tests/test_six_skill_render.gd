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
	for spec: Array in [["muay_thai/gorilla_stand",278],["red_awakened/skills",156],["red_awakened/transform",156]]:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = load("res://assets/characters/"+spec[0]+"_frames.res")
		sprite.centered = false
		var material := ShaderMaterial.new()
		material.shader = load("res://assets/characters/drafts/alpha_cutout.gdshader")
		sprite.material = material
		viewport.add_child(sprite)
		var factor: float = 0
		if spec[0] == "red_awakened/transform": factor = 156.0/286.0*float(sprite.sprite_frames.get_meta("scale"))
		else: factor = float(spec[1])/float(sprite.sprite_frames.get_meta("source_height"))
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
						if absf(area)*0.5 > 500: large += 1
					if large < 1 or clipped:
						failures += 1
						viewport.get_texture().get_image().save_png("res://work/render_fail_"+str(index)+"_"+str(direction)+".png")
						push_error("Six-skill render: "+spec[0]+" "+str(index)+" dir="+str(direction)+" bodies="+str(large)+" clipped="+str(clipped))
					samples += 1
		sprite.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	print("SIX SKILL RENDER RESULT: %d samples, %d failures" % [samples,failures])
	quit(1 if failures else 0)
