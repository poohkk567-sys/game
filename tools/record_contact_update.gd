extends SceneTree
## Native review of pressure, graded recoil, new dash, cyclone and ultimate cut-ins.
var stage: Node2D
func _initialize() -> void: call_deferred("record")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/contact_"+name+".png")
func setup(profile: String = "PHUZASHI", first: float = 480, second: float = 620) -> void:
	for command: StringName in InputMap.get_actions(): Input.action_release(command)
	stage.restart_match()
	stage.phase = "FIGHT"
	stage.p1.select_fighter(profile)
	stage.p2.select_fighter("PHUZASHI")
	stage.p1.controls_enabled = true
	stage.p2.controls_enabled = true
	stage.p1.position.x = first
	stage.p2.position.x = second
	stage.p1.energy = 100 # Review fixture; actual matches still open with 50 MP.
	stage.p2.energy = 100
	await frames(6)
func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(10)
	await setup("PHUZASHI",400,510)
	Input.action_press("p1_move_right")
	await frames(45)
	await capture("push")
	await frames(30)
	await setup("PHUZASHI",1095,1205)
	Input.action_press("p1_move_right")
	Input.action_press("p1_run")
	await frames(40)
	await capture("wall")
	await frames(20)
	await setup("PHUZASHI",480,590)
	stage.p1.start_action("PUNCH")
	await frames(12)
	await capture("punch_impact")
	await frames(45)
	await setup("PHUZASHI",480,590)
	for _i in range(3): stage.p1.start_action("KICK")
	await frames(70)
	await capture("kick_impact")
	await frames(65)
	await setup("PHUZASHI",380,880)
	stage.p1.start_action("ULTIMATE")
	await frames(18)
	await capture("cutin_phu")
	await frames(35)
	await capture("fino_duo")
	await frames(90)
	await setup("RED_CAP",480,900)
	stage.p1.start_action("ULTIMATE")
	await frames(18)
	await capture("cutin_assjiro")
	await frames(60)
	await capture("soy_70mp")
	await frames(123)
	stage.p2.position.x = stage.p1.position.x+110
	Input.action_press("p1_crouch")
	await frames(2)
	Input.action_press("p1_chord_five")
	await frames(2)
	Input.action_release("p1_chord_five")
	Input.action_release("p1_crouch")
	stage.p2.start_action("PUNCH")
	await frames(24)
	await capture("cyclone")
	await frames(80)
	await setup("MUAY_THAI",480,1000)
	await frames(75)
	await capture("muay_idle")
	Input.action_press("p1_dash")
	await frames(8)
	Input.action_release("p1_dash")
	await capture("muay_dash")
	await frames(35)
	await setup("MUAY_THAI",480,590)
	stage.p1.start_action("GORILLA_KING")
	await frames(18)
	await capture("cutin_muay")
	await frames(45)
	await capture("gorilla_impact")
	await frames(125)
	quit()
