extends "res://tests/test_contact_controls.gd"
## Real sequence order, rear-side targeting, interrupted arrivals and ram physics.
const Grip: SpriteFrames = preload("res://assets/effects/ninja_grapple_frames.res")
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	check(Grip.get_frame_count("GRIP") == 8,"Rear ninja owns eight separate standing chain-pulling drawings")
	for profile: String in ["PHUZASHI","PHUZASHI_CHILL"]:
		for left: bool in [false,true]:
			await setup(profile,left)
			check(a.start_action("CHEER") and a.energy == 70,"Cheer still spends 30MP: "+profile)
			await frames(50)
			var helper: Node2D = get_nodes_in_group("cheer_assists")[0]
			check(helper.sprite.visible and helper.sprite.animation == "CHEER" and a.cheer_buff == 0 and not a.status_aura.visible,"Girl cheers first; no premature buff or giant ninja")
			for _i in range(120):
				await frames(1)
				if helper.vanished: break
			check(helper.vanished and not helper.sprite.visible and a.cheer_buff == 0,"Support disappears before the ninja is summoned")
			var helper_age: float = helper.age
			paused = true
			for _i in range(8): await process_frame
			check(helper.age == helper_age and a.cheer_buff == 0,"Pause cannot skip the vanish-to-summon gap")
			paused = false
			await frames(12)
			check(get_nodes_in_group("cheer_assists").is_empty() and a.cheer_buff > 7.8,"Full eight seconds start only after completed cheer and disappearance")
			check(a.status_aura.kind == "PURPLE" and a.status_aura.arrival_age < 0.2 and not get_nodes_in_group("ninja_smoke_effects").is_empty(),"Purple guardian enters quickly inside a smoke burst")
			await frames(22)
			check(a.status_aura.sprite.modulate.a > 0.8,"Ninja finishes its fast smoke reveal")
			a.start_action("DEMON_BIND")
			await frames(22)
			var demon: Node2D = get_nodes_in_group("demon_bind_effects")[0]
			check(demon.phase == "FLIGHT" and not demon.guardian.visible and demon.global_position == demon.origin,"Teleport interval is invisible, with no sliding spirit across the stage")
			await frames(17)
			check(demon.caught and demon.phase == "HOLD" and b.is_movement_locked() and demon.lock_time == 1.1,"Rear teleport starts a real empowered 1.1-second hold")
			check(demon.guardian.sprite_frames == Grip and demon.guardian.sprite_frames != a.status_aura.sprite.sprite_frames,"Standing chain ninja uses a separate pose from the large stand")
			check(demon.grip_position.x*b.facing < 0 and demon.direction == b.facing and demon.visual_height == 116,"Compact creature attaches behind the victim's back in either direction")
			var atlas: AtlasTexture = Grip.get_frame_texture("GRIP",demon.guardian.frame)
			var eye: Vector2 = demon.guardian.to_global(atlas.margin.position+atlas.get_meta("core"))
			check((eye.x-b.global_position.x)*b.facing < -26,"Ninja's mask stays visible beyond the victim's body instead of hiding entirely behind it")
			await frames(100)
			check(not b.is_movement_locked() and get_nodes_in_group("demon_bind_effects").is_empty(),"Rear lock and grappler release cleanly")
			await setup(profile,left)
			b.set_physics_process(false)
			b.facing = a.facing # Victim looking away: behind is the opposite side now.
			a.start_action("DEMON_BIND")
			await frames(39)
			demon = get_nodes_in_group("demon_bind_effects")[0]
			check(demon.lock_time == 0.7 and demon.visual_height == 100 and not demon.empowered,"Normal bind keeps 25MP/0.7s and an even smaller grappler")
			check(demon.direction == b.facing and demon.grip_position.x*b.facing < 0,"Victim facing, not caster direction, chooses the rear when enemy looks away")
			b.set_physics_process(true)
			await setup(profile,left)
			a.position.x = 800 if left else 400
			b.position.x = a.position.x+(-280 if left else 280)
			await frames(3)
			var old_position: Vector2 = b.position
			a.start_action("ULTIMATE")
			for _i in range(100):
				await frames(1)
				if b.damage_taken > 0: break
			check(b.damage_taken == 60 and a.energy == 40 and b.velocity.y < -350,"Fino rams once for original 60 damage/60MP and launches upward")
			check(b.skills.push_remaining > 0.4 and absf(b.skills.push_velocity) > 800,"Ram gives the victim sustained forward momentum")
			var never_crossed: bool = true
			var highest: float = b.position.y
			for _i in range(30):
				await frames(1)
				never_crossed = never_crossed and (b.position.x-a.position.x)*a.facing > 0
				highest = minf(highest,b.position.y)
			check(never_crossed and highest < old_position.y-40 and absf(b.position.x-old_position.x) > 180,"Rider brakes while rival flies away; scooter never runs over the body")
			await frames(100)
			check(b.damage_taken == 60 and b.is_on_floor() and not a.is_fino_active(),"Rival lands and scooter ends without repeated collision damage")
	# A guard blocks the launch; the existing chip, push and guard rules remain.
	await setup("PHUZASHI_CHILL")
	Input.action_press("p2_guard")
	await frames(15)
	a.start_action("ULTIMATE")
	await frames(65)
	check(b.health == 198 and b.is_on_floor() and b.last_hit_blocked,"Guarded Fino stays on the ground and only takes normal guard chip")
	await setup("PHUZASHI_CHILL")
	b.apply_movement_lock(2)
	a.start_action("ULTIMATE")
	for _i in range(70):
		await frames(1)
		if b.damage_taken > 0: break
	check(not b.is_movement_locked() and b.velocity.y < 0,"Ram releases an existing leg bind so the launch cannot be pinned to the floor")
	# Golden monk starts exactly with the shirt-off drawings, not the sauce.
	await setup("RED_CAP")
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	a.start_action("ULTIMATE")
	await frames(100)
	check(a.red_transform_phase() == "BLACK SOY SAUCE" and not a.status_aura.visible,"No monk during cap removal or black sauce phase")
	await frames(32)
	check(a.red_transform_phase() == "SHIRT OFF" and a.status_aura.kind == "GOLD" and a.status_aura.arrival_offset < -180,"Monk appears high above exactly when shirt removal begins")
	var above: float = a.status_aura.arrival_offset
	await frames(26)
	check(a.status_aura.arrival_offset > above and a.status_aura.arrival_offset < -20,"Sacred guardian floats down smoothly through golden heavenly light")
	await frames(50)
	check(a.red_awakened and a.energy == 30 and is_zero_approx(a.status_aura.arrival_offset),"Golden monk settles behind shirtless form; 70MP and remainder unchanged")
	a.start_action("CARROT_SPIN")
	await frames(2)
	check(not a.status_aura.visible,"Cyclone hides the guardian with the human body")
	await frames(75)
	check(a.status_aura.visible and is_zero_approx(a.status_aura.arrival_offset),"Returning from cyclone does not replay the heavenly descent")
	await setup("RED_CAP")
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	a.start_action("ULTIMATE")
	await frames(135)
	a.receive_attack(8,"PUNCH",b)
	await frames(3)
	check(not a.red_awakened and not a.status_aura.visible and a.energy == 30,"Interrupted shirt removal cancels the heavenly guardian without refund or form commit")
	# Shuriken visuals rotate; projectile collision/damage/range stay authoritative.
	for left: bool in [false,true]:
		await setup("PHUZASHI_CHILL",left)
		a.position.x = 1000 if left else 200
		b.position.x = 250 if left else 950
		await frames(3)
		a.start_action("SPECIAL")
		await frames(32)
		var star: Area2D = get_nodes_in_group("dark_pulses")[0]
		var angle: float = star.spin_angle
		var x: float = star.position.x
		await frames(3)
		check(absf(star.spin_angle-angle) > 1 and is_equal_approx(absf(star.position.x-x),31),"Purple star spins while flying at exactly 620px/s, left="+str(left))
		paused = true
		angle = star.spin_angle
		for _i in range(8): await process_frame
		check(star.spin_angle == angle,"Pause freezes shuriken spin and movement")
		paused = false
		await frames(110)
		check(b.damage_taken == 24 and a.energy == 75 and get_nodes_in_group("dark_pulses").is_empty(),"Shuriken hits once for 24 damage/25MP and frees after impact")
	stage.start_round()
	await frames(3)
	check(a.energy == 50 and b.energy == 50 and get_nodes_in_group("ninja_smoke_effects").is_empty(),"Round reset clears transient smoke and retains opening 50MP")
	stage.queue_free()
	await frames(3)
	check(get_nodes_in_group("demon_bind_effects").is_empty(),"Scene exit frees every rear grappler")
	print("NINJA ARRIVALS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
