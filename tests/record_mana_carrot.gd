extends SceneTree
var stage: Node2D

func _initialize() -> void:
	call_deferred("record")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func setup(left: bool = false) -> void:
	for command: StringName in InputMap.get_actions():
		Input.action_release(command)
	stage.restart_match()
	stage.phase = "FIGHT"
	stage.p1.controls_enabled = true
	stage.p2.controls_enabled = true
	stage.p1.position.x = 780 if left else 540
	stage.p2.position.x = 660 if left else 660
	await frames(5)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/mana_carrot_"+name+".png")

func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(115)
	stage.p1.energy = 20
	stage.p2.energy = 30
	Input.action_press("p1_charge")
	Input.action_press("p2_charge")
	await frames(90)
	await capture("charge")
	await frames(30)
	await setup()
	Input.action_press("p1_guard")
	await frames(12)
	stage.p2.start_action("DEMON_BIND")
	await frames(40)
	await capture("barrage_guard")
	await frames(55)
	await setup()
	Input.action_press("p1_guard")
	await frames(2)
	stage.p1.receive_attack(8,"PUNCH",stage.p2)
	await frames(4)
	await capture("perfect_guard")
	await frames(30)
	await setup()
	Input.action_press("p1_guard")
	await frames(12)
	stage.p1.guard_meter = 20
	stage.p2.start_action("DEMON_BIND")
	await frames(46)
	await capture("guard_break")
	await frames(55)
	for left: bool in [false,true]:
		await setup(left)
		stage.p2.start_action("SPECIAL")
		await frames(23)
		await capture("headbutt_right" if left else "headbutt_left")
		await frames(45)
		await setup(left)
		stage.p2.start_action("DEMON_BIND")
		await frames(36)
		await capture("barrage_right" if left else "barrage_left")
		await frames(60)
	await setup()
	stage.p2.start_action("ULTIMATE")
	await frames(200)
	stage.p2.energy = 100
	stage.p1.position.x = 540
	stage.p2.position.x = 660
	await frames(5)
	stage.p2.start_action("SPECIAL")
	await frames(23)
	await capture("awakened_headbutt")
	await frames(45)
	stage.p1.reset_training()
	stage.p1.position.x = 540
	stage.p2.position.x = 660
	await frames(5)
	stage.p2.start_action("DEMON_BIND")
	await frames(36)
	await capture("awakened_barrage")
	await frames(60)
	stage.show_help = true
	await frames(20)
	await capture("controls")
	await frames(40)
	stage.queue_free()
	await frames(3)
	quit()
