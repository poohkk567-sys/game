extends "res://tests/test_six_skills.gd"
## Separate redesigned fighter; original damage, costs, timing and complete power set.
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	await setup("PHUZASHI_CHILL")
	check(a.display_name == "PHUZASHI CHILL" and a.uses_dark_pulse(),"Chill redesign is independently selectable and belongs to Dark Pulse family")
	check(Book.ROSTER.PHUZASHI_CHILL == Book.ROSTER.PHUZASHI,"Both PHUZASHI versions expose the same six skills in the same slots")
	var bank: SpriteFrames = a.rig.draft_animation.sprite_frames
	var owned: bool = true
	for clip: String in ["IDLE","WALK","RUN","JUMP","CROUCH","GUARD","PUNCH","PUNCH_2","PUNCH_3","KICK","KICK_2","KICK_3","HIT","FALL","SPECIAL","ULTIMATE"]:
		check(bank.has_animation(clip) and bank.get_frame_count(clip) == 8,"Eight redesigned complete poses for "+clip)
		for i in range(8):
			var atlas: AtlasTexture = bank.get_frame_texture(clip,i)
			owned = owned and atlas.atlas.resource_path.contains("/phuzashi_chill/")
	check(owned,"Every normal and casting drawing comes from the new model")
	check(bank.has_animation("BLINK") and bank.get_frame_count("BLINK") == 12,"Blink keeps twelve poses assembled from the new body")
	check(a.fino_visual.sprite_frames.get_frame_texture("FINO",0).atlas.resource_path.contains("/phuzashi_chill/"),"Scooter also uses the new male model with the same female pillion")
	for clip: String in ["PUNCH","PUNCH_2","PUNCH_3","KICK","KICK_2","KICK_3","AIR_PUNCH","AIR_KICK"]:
		check(a.attack_config(clip) == a.ATTACKS[clip],"Unchanged contact timings, reach and damage: "+clip)
	for left: bool in [false,true]:
		for family: String in ["PUNCH","KICK"]:
			await setup("PHUZASHI_CHILL",left,105)
			a.start_action(family)
			a.start_action(family)
			a.start_action(family)
			await frames(120)
			check(b.damage_taken == (34 if family == "PUNCH" else 52),"Three relaxed "+family+" hits retain original total, left="+str(left))
			check(b.position.x < 645 if left else b.position.x > 585,"Combo retains physical recoil, left="+str(left))
			check(a.energy == 100,"Normals still grant mana and respect the hundred-MP cap")
		for spec: Array in [["SPECIAL",24,215],["DARK_RIFT",26,215],["ULTIMATE",60,280]]:
			await setup("PHUZASHI_CHILL",left,spec[2])
			check(a.start_action(spec[0]),"New model casts "+spec[0]+" left="+str(left))
			check(a.energy == 100-Book.cost(spec[0]),"Original MP cost for "+spec[0])
			await frames(150)
			check(b.damage_taken == spec[1],"Original skill damage for "+spec[0]+" got="+str(b.damage_taken))
		await setup("PHUZASHI_CHILL",left,140)
		a.start_action("DEMON_BIND")
		await frames(35)
		check(b.is_movement_locked() and a.energy == 75,"Ordinary demon bind remains 25 MP and locks the actual rival")
		await frames(50)
		check(not b.is_movement_locked(),"Ordinary bind still releases after 0.7 seconds")
		await setup("PHUZASHI_CHILL",left)
		a.start_action("CHEER")
		await frames(55)
		check(a.cheer_buff > 7 and a.energy == 70 and a.status_aura.kind == "PURPLE","Same girl grants eight-second cheer and purple demon cloak")
		a.start_action("DEMON_BIND")
		await frames(35)
		var demons: Array[Node] = get_nodes_in_group("demon_bind_effects")
		check(b.is_movement_locked() and not demons.is_empty() and demons[0].empowered and demons[0].lock_time == 1.1,"Cheered chill fighter receives the same empowered leg bind")
		await setup("PHUZASHI_CHILL",left)
		a.start_action("SHADOW_COUNTER")
		await frames(10)
		b.start_action("PUNCH")
		await frames(55)
		check(a.damage_taken == 0 and b.damage_taken == 20 and a.energy == 70,"Shadow counter timing and retaliation are unchanged")
		await setup("PHUZASHI_CHILL",left,400)
		a.energy = 5
		check(a._start_blink(-1 if left else 1) and a.energy == 0,"New model also blinks for exactly five MP")
		await frames(30)
		check(a.rig.draft_animation.last_state != "BLINK" or a.blink_timer == 0,"New blink finishes without borrowing an old model")
	await setup("PHUZASHI_CHILL")
	a.energy = 100
	a.start_action("ULTIMATE")
	check(stage.get_node("UltimateCutins").current.profile == "PHUZASHI_CHILL","New model receives its own portrait cut-in")
	a.select_fighter("PHUZASHI")
	check(a.display_name == "PHUZASHI" and a.energy == 50,"Original PHUZASHI remains independently playable")
	check(not a.rig.draft_animation.sprite_frames.get_frame_texture("IDLE",0).atlas.resource_path.contains("/phuzashi_chill/"),"Original fighter still owns the previously approved body")
	stage.queue_free()
	await frames(3)
	print("PHUZASHI CHILL RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
