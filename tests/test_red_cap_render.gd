extends SceneTree
## Render all 112 Red Cap whole-body drawings mirrored, checking feet and isolation.
var failures: int = 0
var samples: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384,320)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rig: Node2D = load("res://scripts/character/phuzashi_rig.gd").new()
	rig.use_draft_spritesheet = true
	viewport.add_child(rig)
	rig.position = Vector2(192,285)
	rig.set_character_profile("RED_CAP")
	for facing: int in [-1,1]:
		for clip: StringName in rig.draft_animation.RED_FRAMES.get_animation_names():
			for frame in range(8):
				rig.animate(clip,1.0/60.0,facing,float(frame)/8.0)
				var sprite: AnimatedSprite2D = rig.draft_animation
				sprite.frame = frame
				await process_frame
				await RenderingServer.frame_post_draw
				var bitmap := BitMap.new()
				bitmap.create_from_image_alpha(viewport.get_texture().get_image(),0.5)
				var components: int = 0
				var bottom: float = -INF
				var clipped: bool = false
				for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(0,0,384,320),0.1):
					var area: float = 0.0
					for i in range(polygon.size()):
						area += polygon[i].cross(polygon[(i+1)%polygon.size()])
						bottom = maxf(bottom,polygon[i].y)
						clipped = clipped or polygon[i].x <= 1 or polygon[i].x >= 383 or polygon[i].y <= 1
					if absf(area)*0.5 > 35:
						components += 1
				if components != 1 or absf(bottom-285.0) > 1.5 or clipped or not sprite.visible:
					failures += 1
					push_error("Red Cap render %s/%d dir=%d components=%d bottom=%f clipped=%s" % [clip,frame,facing,components,bottom,clipped])
				samples += 1
	viewport.queue_free()
	await process_frame
	print("RED CAP RENDER: %d frames, %d failures" % [samples,failures])
	quit(1 if failures > 0 else 0)
