extends SceneTree
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter
func _initialize() -> void: call_deferred("record")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/pact_preview_chill_"+label+".png")
func setup(distance: float = 110) -> void:
	for command: StringName in InputMap.get_actions(): Input.action_release(command)
	stage.restart_match()
	stage.phase = "FIGHT"
	a.select_fighter("PHUZASHI_CHILL")
	b.select_fighter("RED_CAP")
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 480
	b.position.x = 480+distance
	a.energy = 100
	await frames(6)
func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(8)
	a = stage.p1
	b = stage.p2
	await setup(400)
	await frames(24)
	await shot("idle")
	Input.action_press("p1_move_right")
	await frames(50)
	Input.action_release("p1_move_right")
	await frames(18)
	await setup()
	a.start_action("PUNCH")
	a.start_action("PUNCH")
	a.start_action("PUNCH")
	var saved: bool = false
	for _i in range(115):
		await frames(1)
		if not saved and a.action_name == "PUNCH_3" and a.attack_phase() == "ACTIVE":
			await shot("punch_three")
			saved = true
	await setup()
	a.start_action("KICK")
	a.start_action("KICK")
	a.start_action("KICK")
	saved = false
	for _i in range(140):
		await frames(1)
		if not saved and a.action_name == "KICK_3" and a.attack_phase() == "ACTIVE":
			await shot("kick_three")
			saved = true
	await setup(180)
	a.start_action("CHEER")
	await frames(55)
	a.start_action("DEMON_BIND")
	await frames(40)
	await shot("cheer_bind")
	await frames(70)
	await setup(320)
	a.start_action("SPECIAL")
	await frames(70)
	await setup(320)
	a.start_action("ULTIMATE")
	await frames(12)
	await shot("cutin")
	await frames(42)
	await shot("fino")
	await frames(80)
	stage.queue_free()
	await frames(3)
	var menu: Control = load("res://scenes/title_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.selectors[0].select(4)
	menu.selectors[1].select(3)
	menu._refresh_character(0)
	menu._refresh_character(1)
	await frames(20)
	await shot("menu")
	quit()
