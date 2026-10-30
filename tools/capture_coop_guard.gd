extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	var stage: Node3D = load("res://scenes/coop_boss.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	stage.state = "FIGHT"
	stage.boss.ai_enabled = false
	stage.boss.position = Vector3.ZERO
	stage.team[0].position = Vector3(0,0,2.4)
	stage.team[1].position = Vector3(-4,0,2.5)
	Input.action_press("p1_guard")
	await frames(30)
	stage.boss.start_attack("SWEEP",stage.team[0].position)
	await frames(65)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/coop_preview_guard.png")
	Input.action_release("p1_guard")
	quit()
