extends SceneTree
## Actual player commands and unchanged skill effects on the new character.
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

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/versus_"+label+".png")

func fresh(close: bool = true) -> void:
	stage.restart_match()
	await frames(112)
	stage.p1.position.x = 620 if close else 350
	stage.p2.position.x = 730 if close else 900
	await frames(5)

func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(112)
	await capture("school_gate")
	Input.action_press("p1_move_right")
	Input.action_press("p2_move_left")
	await frames(52)
	Input.action_release("p1_move_right")
	Input.action_release("p2_move_left")
	await frames(10)
	for _i in range(3):
		await tap("p1_punch")
	for _i in range(95):
		await frames(1)
		if stage.p1.action_name == "PUNCH_3" and stage.p1.action_progress() >= 0.38 and stage.p1.action_progress() < 0.42:
			await capture("purple_fist")
	await fresh()
	for _i in range(3):
		await tap("p2_kick")
	await frames(110)
	await fresh()
	Input.action_press("p2_guard")
	await tap("p1_punch")
	await frames(40)
	Input.action_release("p2_guard")
	await tap("p2_jump")
	await tap("p2_kick")
	await frames(8)
	await capture("air_kick")
	await frames(60)
	await fresh(false)
	Input.action_press("p1_crouch")
	await tap("p1_punch")
	Input.action_release("p1_crouch")
	await frames(35)
	Input.action_press("p2_move_left")
	await frames(8)
	await capture("demon_bind")
	Input.action_release("p2_move_left")
	await frames(60)
	await tap("p1_special")
	await frames(70)
	await capture("dark_pulse")
	await frames(35)
	await fresh(false)
	await tap("p1_ultimate")
	await frames(48)
	await capture("dragon")
	await frames(100)
	await fresh(false)
	await tap("p1_move_right")
	await tap("p1_move_right")
	await frames(15)
	await capture("blink")
	await frames(55)
	stage.show_help = true
	await frames(20)
	await capture("controls")
	stage.show_help = false
	stage.p1.position.x = 620
	stage.p2.position.x = 730
	stage.p2.health = 8
	await frames(8)
	await tap("p1_punch")
	await frames(40)
	await capture("round_win")
	await frames(90)
	quit()
