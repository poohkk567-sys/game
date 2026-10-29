extends SceneTree
## Display-required regression against the rendered silhouette, not hidden pieces.
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
	rig.set_script(load("res://work/old_rig.gd" if "--baseline" in OS.get_cmdline_user_args() else "res://scripts/character/phuzashi_rig.gd"))
	viewport.add_child(rig)
	rig.position = Vector2(160,220)
	for facing: int in [-1,1]:
		rig.scale = Vector2(facing*3,3)
		for clip: String in rig.CLIPS:
			for step in range(9):
				rig.position.x = 160.375 if step % 2 else 160.0
				rig.apply_pose(rig.sample_pose(clip,step/8.0),clip!="JUMP")
				await process_frame
				await RenderingServer.frame_post_draw
				var image: Image = viewport.get_texture().get_image()
				var bitmap := BitMap.new()
				bitmap.create_from_image_alpha(image,0.5)
				var large_components: int = 0
				for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(0,0,320,256),0.1):
					var area: float = 0.0
					for i in range(polygon.size()):
						area += polygon[i].cross(polygon[(i+1)%polygon.size()])
					if absf(area)*0.5 > 40.0:
						large_components += 1
				if large_components != 1:
					failures += 1
					push_error("Detached body region: %s phase %.3f facing %d (%d components)" % [clip,step/8.0,facing,large_components])
				samples += 1
			print("RENDER CHECK ",clip," facing ",facing)
	print("RENDER RESULT: %d silhouettes, %d failures" % [samples,failures])
	viewport.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
