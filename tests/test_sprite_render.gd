extends SceneTree
## Render every complete draft frame, with floor alignment and both facings.
var failures: int = 0
var samples: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320,256)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rig := Node2D.new()
	rig.set_script(load("res://scripts/character/phuzashi_rig.gd"))
	rig.use_draft_spritesheet = true
	viewport.add_child(rig)
	rig.position = Vector2(160,220)
	for facing: int in [-1,1]:
		for clip: String in rig.CLIPS:
			rig.animate(clip,1.0/60.0,facing)
			var sprite: AnimatedSprite2D = rig.draft_animation
			sprite.pause()
			for frame in range(8):
				sprite.frame = frame
				rig.position.x = 160.375 if frame % 2 else 160.0
				await process_frame
				await RenderingServer.frame_post_draw
				var image: Image = viewport.get_texture().get_image()
				var bitmap := BitMap.new()
				bitmap.create_from_image_alpha(image,0.5)
				var components: int = 0
				for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(0,0,320,256),0.1):
					var area: float = 0.0
					for i in range(polygon.size()):
						area += polygon[i].cross(polygon[(i+1)%polygon.size()])
					if absf(area)*0.5 > 40.0:
						components += 1
				var lowest: int = -1
				for y in range(256):
					for x in range(320):
						if bitmap.get_bit(x,y):
							lowest = y
				if components != 1 or lowest < 218 or lowest > 220 or not sprite.visible or rig.skin.visible:
					failures += 1
					push_error("Sprite render: %s frame %d facing %d, components=%d bottom=%d" % [clip,frame,facing,components,lowest])
				samples += 1
	print("SPRITE RENDER RESULT: %d frames, %d failures" % [samples,failures])
	viewport.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
