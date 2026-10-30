extends "res://tools/record_ninja_arrivals.gd"
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/return_preview_"+label+".png")
func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(8)
	a = stage.p1
	b = stage.p2
	for profile: String in ["PHUZASHI_CHILL","PHUZASHI"]:
		await setup(profile,false,300)
		await shot("needs_mark_"+profile.to_lower())
		Input.action_press("p2_guard")
		await frames(15)
		a.start_action("SPECIAL")
		await frames(65)
		await shot("guard_mark_"+profile.to_lower())
		Input.action_release("p2_guard")
		a.start_action("SHADOW_RETURN")
		await frames(18)
		await shot("seal_"+profile.to_lower())
		for _i in range(25):
			await frames(1)
			if a.shadow_return.away: break
		await frames(16)
		await shot("rear_strike_"+profile.to_lower())
		await frames(55)
		await shot("home_"+profile.to_lower())
	await setup("PHUZASHI_CHILL",false,350)
	a.cheer_buff = 5 # Demonstrate an already-earned stand; production cheer unchanged.
	a.energy = 0
	await frames(18)
	for i in range(4):
		a._start_blink(1 if i%2 == 0 else -1)
		await frames(12)
		if i == 2: await shot("free_stand_blink")
		await frames(13)
	await setup("RED_CAP",false,110)
	a.start_action("SOY_BOMB") # Same player-facing slot resolves to capped shove.
	await frames(20)
	await shot("capped_palm")
	await frames(18)
	await shot("shove_flight")
	await frames(42)
	a.start_action("ULTIMATE")
	await frames(205)
	await shot("awakened_slot")
	await frames(145)
	b.position.x = a.position.x+300
	await frames(3)
	a.start_action("SOY_BOMB")
	await frames(39)
	await shot("awakened_bottle")
	await frames(95)
	quit()
