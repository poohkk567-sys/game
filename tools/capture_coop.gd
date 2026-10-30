extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage: Node3D = load("res://scenes/coop_boss.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	stage.boss.ai_enabled = false
	for _i in range(130):
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/coop_preview_arena.png")
	quit()
