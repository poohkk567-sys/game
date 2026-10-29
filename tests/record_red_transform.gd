extends SceneTree
var stage: Node2D

func _initialize() -> void:
	call_deferred("record")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func tap(command: String) -> void:
	Input.action_press(command)
	await frames(2)
	Input.action_release(command)
	await frames(2)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/red_transform_"+name+".png")

func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(115)
	await tap("p2_ultimate")
	var saved: Dictionary = {}
	for _i in range(200):
		await frames(1)
		if stage.p2.action_name == "TRANSFORM":
			var frame: int = stage.p2.rig.draft_animation.frame
			if frame in [3,7,12] and not saved.has(frame):
				await capture({3:"cap_off",7:"yellow_sauce",12:"shirt_off"}[frame])
				saved[frame] = true
	await capture("awakened")
	stage.p1.position.x = 640
	stage.p2.position.x = 750
	await frames(5)
	for _i in range(3):
		await tap("p2_punch")
	for _i in range(100):
		await frames(1)
		if stage.p2.action_name == "PUNCH_3" and stage.p2.action_progress() >= 0.38 and not saved.has("punch"):
			await capture("punch_combo")
			saved["punch"] = true
	stage.p1.reset_training()
	stage.p1.position.x = 640
	stage.p2.position.x = 750
	await frames(5)
	for _i in range(3):
		await tap("p2_kick")
	await frames(110)
	stage.p1.reset_training()
	stage.p1.position.x = 640
	stage.p2.position.x = 750
	await frames(5)
	await tap("p2_jump")
	await tap("p2_kick")
	await frames(8)
	await capture("air_kick")
	await frames(65)
	stage.restart_match()
	await frames(112)
	await capture("reset_capped")
	# Repeat mirrored so the bottle/nozzle and removal remain readable both ways.
	stage.p1.position.x = 1000
	stage.p2.position.x = 500
	await frames(5)
	await tap("p2_ultimate")
	await frames(210)
	await capture("awakened_right")
	stage.show_help = true
	await frames(20)
	await capture("controls")
	await frames(30)
	quit()
