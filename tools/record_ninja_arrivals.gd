extends SceneTree
## Actual gameplay fixture. Extra mana belongs only to this recording.
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
	root.get_texture().get_image().save_png("res://docs/screenshots/ninja_preview_"+label+".png")
func setup(profile: String, left: bool = false, distance: float = 270) -> void:
	stage.restart_match()
	stage.phase = "FIGHT"
	a.select_fighter(profile)
	b.select_fighter("BLACK_COAT")
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 850 if left else 400
	b.position.x = a.position.x+(-distance if left else distance)
	a.energy = 100
	await frames(6)
func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(8)
	a = stage.p1
	b = stage.p2
	await setup("PHUZASHI_CHILL")
	a.start_action("CHEER")
	await frames(80)
	await shot("cheer_first")
	await frames(76)
	await shot("girl_vanish")
	await frames(14)
	await shot("ninja_smoke")
	await frames(22)
	await shot("ninja_ready")
	a.start_action("DEMON_BIND")
	await frames(23)
	await shot("bind_teleport")
	await frames(35)
	await shot("rear_grip_right")
	await frames(95)
	await setup("PHUZASHI_CHILL",true)
	a.start_action("DEMON_BIND")
	await frames(58)
	await shot("rear_grip_left")
	await frames(65)
	await setup("RED_CAP")
	a.start_action("ULTIMATE")
	await frames(100)
	await shot("sauce_no_guardian")
	await frames(33)
	await shot("heaven_high")
	await frames(23)
	await shot("heaven_descent")
	await frames(50)
	await shot("heaven_settled")
	await frames(25)
	await setup("PHUZASHI_CHILL",false,280)
	a.start_action("ULTIMATE")
	for _i in range(100):
		await frames(1)
		if b.damage_taken > 0: break
	await frames(10)
	await shot("fino_launch")
	await frames(20)
	await shot("fino_brake")
	await frames(100)
	await setup("PHUZASHI_CHILL",false,630)
	a.start_action("SPECIAL")
	await frames(38)
	await shot("shuriken")
	await frames(7)
	await shot("shuriken_spin")
	await frames(95)
	quit()
