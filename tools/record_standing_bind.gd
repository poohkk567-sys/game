extends "res://tools/record_ninja_arrivals.gd"
## Focused actual-game recording for the standing chain restraint.
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/standing_bind_"+label+".png")
func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(8)
	a = stage.p1
	b = stage.p2
	for left: bool in [false,true]:
		for empowered: bool in [false,true]:
			await setup("PHUZASHI_CHILL",left,300)
			a.cheer_buff = 8 if empowered else 0
			await frames(15)
			a.start_action("DEMON_BIND")
			await frames(58)
			await shot(("left" if left else "right")+("_buff" if empowered else "_normal"))
			await frames(70)
	for left_wall: bool in [false,true]:
		await setup("PHUZASHI_CHILL",left_wall,300)
		a.position.x = 400 if left_wall else 850
		b.position.x = 75 if left_wall else 1205
		await frames(4)
		a.start_action("DEMON_BIND")
		await frames(58)
		await shot("wall_left" if left_wall else "wall_right")
		await frames(65)
	quit()
