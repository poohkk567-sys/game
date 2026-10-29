extends SceneTree
## Render all completed-form drawings and transformation props in both directions.
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
	viewport.add_child(rig)
	rig.position = Vector2(192,285)
	rig.set_character_profile("RED_CAP")
	for awakened: bool in [false,true]:
		rig.set_red_awakened(awakened)
		var names: PackedStringArray = rig.draft_animation.sprite_frames.get_animation_names() if awakened else PackedStringArray(["TRANSFORM"])
		for facing: int in [-1,1]:
			for clip: StringName in names:
				var count: int = rig.draft_animation.sprite_frames.get_frame_count(clip)
				for frame in range(count):
					rig.animate(clip,1.0/60.0,facing,float(frame)/count)
					var sprite: AnimatedSprite2D = rig.draft_animation
					sprite.frame = frame
					await process_frame
					await RenderingServer.frame_post_draw
					var bitmap := BitMap.new()
					bitmap.create_from_image_alpha(viewport.get_texture().get_image(),0.5)
					var body_count: int = 0
					var components: int = 0
					var bottom: float = -INF
					var clipped: bool = false
					for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(0,0,384,320),0.1):
						var area: float = 0
						for i in range(polygon.size()):
							area += polygon[i].cross(polygon[(i+1)%polygon.size()])
							bottom = maxf(bottom,polygon[i].y)
							clipped = clipped or polygon[i].x <= 1 or polygon[i].x >= 383 or polygon[i].y <= 1
						area = absf(area)*0.5
						if area > 35:
							components += 1
						if area > 500:
							body_count += 1
					var intact: bool = components == 1 if awakened else (body_count == 1 and components <= 4)
					if not intact or absf(bottom-285.0) > 1.5 or clipped or not sprite.visible:
						failures += 1
						push_error("Awakened render %s/%d dir=%d parts=%d body=%d bottom=%f clipped=%s" % [clip,frame,facing,components,body_count,bottom,clipped])
					samples += 1
	viewport.queue_free()
	await process_frame
	print("RED AWAKENED RENDER: %d samples, %d failures" % [samples,failures])
	quit(1 if failures > 0 else 0)
