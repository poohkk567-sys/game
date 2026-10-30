extends "res://tools/record_ninja_arrivals.gd"
## Recording-only mana fixtures, no gameplay balance overrides.
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/black_preview_"+label+".png")

func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(8)
	a = stage.p1
	b = stage.p2
	for move: String in ["BLOOD_FANG","RAGE_DRIVE","HELL_RISER","GRIN_CRUSH","CRIMSON_BURST"]:
		await setup("BLACK_COAT",false,320 if move == "BLOOD_FANG" else 110)
		b.select_fighter("PHUZASHI_CHILL")
		b.position.x = a.position.x+(320 if move == "BLOOD_FANG" else 110)
		await frames(6)
		a.start_action(move)
		await frames(26 if move != "GRIN_CRUSH" else 36)
		await shot(move.to_lower())
		await frames(95)
	await setup("BLACK_COAT",true,110)
	b.select_fighter("MUAY_THAI")
	b.position.x = a.position.x-110
	await frames(6)
	Input.action_press("p2_guard")
	await frames(15)
	b.guard_meter = 35
	a.start_action("GRIN_CRUSH")
	await frames(42)
	await shot("guard_break_left")
	await frames(70)
	Input.action_release("p2_guard")
	await setup("BLACK_COAT",false,240)
	b.select_fighter("RED_CAP")
	b.position.x = a.position.x+240
	await frames(6)
	a.start_action("ULTIMATE")
	await frames(18)
	await shot("pact_cutin")
	await frames(40)
	await shot("pact_slash")
	await frames(58)
	a.start_action("BLOOD_FANG")
	await frames(42)
	await shot("empowered_fang")
	await frames(100)
	quit()
