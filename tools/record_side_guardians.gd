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
	root.get_texture().get_image().save_png("res://docs/screenshots/guardian_preview_"+label+".png")
func setup(profile: String, left: bool = false) -> void:
	stage.restart_match()
	stage.phase = "FIGHT"
	a.select_fighter(profile)
	b.select_fighter("RED_CAP")
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 800 if left else 400
	b.position.x = a.position.x+(-220 if left else 220)
	a.energy = 100 # Preview only. Actual rounds continue to open at 50MP.
	await frames(6)
func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(8)
	a = stage.p1
	b = stage.p2
	for left: bool in [false,true]:
		await setup("PHUZASHI_CHILL",left)
		a.start_action("CHEER")
		await frames(180)
		a.start_action("DEMON_BIND")
		await frames(40)
		await shot("shinobi_left" if left else "shinobi_right")
		await frames(60)
	await setup("BLACK_COAT")
	a.start_action("ULTIMATE")
	await frames(115)
	await shot("crimson_right")
	await frames(40)
	await setup("BLACK_COAT",true)
	a.start_action("ULTIMATE")
	await frames(115)
	await shot("crimson_left")
	await setup("RED_CAP")
	a.start_action("ULTIMATE")
	await frames(205)
	await shot("gold_right")
	await frames(40)
	await setup("PHUZASHI_CHILL")
	a.start_action("ULTIMATE")
	await frames(55)
	await shot("fino")
	await frames(70)
	await setup("PHUZASHI_CHILL")
	a.cheer_buff = 8
	b.select_fighter("BLACK_COAT")
	b.controls_enabled = true
	b.pact.commit()
	b.energy = 30
	await frames(30)
	await shot("duel")
	await frames(60)
	quit()
