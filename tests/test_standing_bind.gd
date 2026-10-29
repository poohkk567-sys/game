extends "res://tests/test_contact_controls.gd"
## Regression for the actual reported occlusion, including both arena edges.
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	for profile: String in ["PHUZASHI","PHUZASHI_CHILL"]:
		for left: bool in [false,true]:
			for empowered: bool in [false,true]:
				await setup(profile,left)
				b.select_fighter("MUAY_THAI" if empowered else "BLACK_COAT")
				b.controls_enabled = true
				a.position.x = 850 if left else 400
				b.position.x = 530 if left else 720
				a.cheer_buff = 8 if empowered else 0
				await frames(3)
				a.start_action("DEMON_BIND")
				await frames(40)
				var demon: Node2D = get_nodes_in_group("demon_bind_effects")[0]
				check(demon.phase == "HOLD" and b.is_movement_locked(),"Standing ninja still applies the actual lock: "+profile)
				check(demon.visual_height == (116 if empowered else 100) and demon.lock_time == (1.1 if empowered else 0.7),"Small size and original normal/empowered lock duration remain")
				var bounds: Rect2 = demon.visual_bounds()
				var body := Rect2(b.global_position-Vector2(25,b.standing_height()),Vector2(50,b.standing_height()))
				check(not bounds.intersects(body),"Whole standing body, not just one eye, stays separate from the victim at center stage")
				check(demon.grip_position.x*b.facing < 0 and demon.direction == b.facing,"Standing chain puller remains on the victim's rear side")
				check(demon.guardian.z_index > b.z_index and demon.chains.z_index > demon.guardian.z_index,"Victim cannot paint over either the ninja or foreground torso chains")
				check(demon.chains.visible and a.energy == 75 and b.damage_taken == 0,"Visible torso restraint preserves25MP and deals no damage")
				var readable: bool = true
				for index in range(8):
					demon.age = index/10.0
					demon._update_visual()
					readable = readable and not demon.visual_bounds().intersects(body)
				check(readable,"Every standing drawing stays clear of the victim in both directions")
				await frames(110)
				check(not b.is_movement_locked() and get_nodes_in_group("demon_bind_effects").is_empty(),"Chains and standing ninja leave together when the lock ends")
	for left_wall: bool in [false,true]:
		await setup("PHUZASHI_CHILL")
		b.select_fighter("RED_CAP")
		b.controls_enabled = true
		a.position.x = 400 if left_wall else 850
		b.position.x = 75 if left_wall else 1205
		await frames(3)
		a.start_action("DEMON_BIND")
		await frames(40)
		var demon: Node2D = get_nodes_in_group("demon_bind_effects")[0]
		var complete: bool = true
		for index in range(8):
			demon.age = index/10.0
			demon._update_visual()
			var bounds: Rect2 = demon.visual_bounds()
			complete = complete and bounds.position.x >= 11.99 and bounds.end.x <= 1268.01
		check(complete,"All eight full-body drawings stay inside the viewport at wall, left="+str(left_wall))
		check(demon.direction == b.facing and demon.guardian.z_index > b.z_index,"At the wall the complete small ninja retains facing and cannot be hidden by the victim")
	stage.start_round()
	await frames(3)
	check(a.energy == 50 and b.energy == 50 and get_nodes_in_group("demon_bind_effects").is_empty(),"Round reset clears standing ninja and chains, retaining50MP")
	stage.queue_free()
	await frames(3)
	check(get_nodes_in_group("demon_bind_effects").is_empty(),"No standing bind actors survive scene exit")
	print("STANDING BIND RESULT: %d checks, %d failures" % [checks,failures])
	call_deferred("quit",1 if failures else 0)
