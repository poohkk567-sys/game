extends "res://tests/test_contact_controls.gd"
const Pulse = preload("res://scripts/character/dark_pulse.gd")
func setup(profile: String = "PHUZASHI", left: bool = false) -> void:
	await super.setup(profile,left)
	a.shadow_return.reset()
	b.shadow_return.reset()
func capped(left: bool = false) -> void:
	await setup("RED_CAP",left)
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	await frames(2)
func until_away(actor: Node2D) -> void:
	for _i in range(45):
		await frames(1)
		if actor.shadow_return.away: return
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	check(a.energy == 50 and a.shadow_return.target() == null,"Real round starts at50MP without an invented shuriken mark")
	for profile: String in ["PHUZASHI","PHUZASHI_CHILL"]:
		await setup(profile)
		check(not a.start_action("SHADOW_RETURN") and a.energy == 100 and a.skills.cooldowns.is_empty(),"No mark rejects return without spending mana or cooldown: "+profile)
		check(not a.start_action("DARK_RIFT"),"Removed floor-hole action cannot be cast")
		for block in range(3):
			await setup(profile,block == 1)
			a.position.x = 850 if block == 1 else 400
			b.position.x = a.position.x+(-300 if block == 1 else 300)
			await frames(3)
			if block == 1:
				Input.action_press("p2_guard")
				await frames(15)
			a.start_action("SPECIAL")
			if block == 2:
				await frames(35)
				Input.action_press("p2_guard")
				await frames(30)
			else: await frames(65)
			check(a.shadow_return.target() == b,"Actual shuriken hit grants one mark, guard mode="+str(block))
			check(b.damage_taken == [24,2,0][block],"Ordinary, guard and Perfect Guard damage confirms the correct collision path")
			Input.action_release("p2_guard")
			await frames(2)
			var home: Vector2 = a.global_position
			var look: int = b.facing
			check(a.start_action("SHADOW_RETURN") and a.energy == 45 and a.shadow_return.target() == null,"Return spends30MP and consumes exactly one confirmed mark")
			await frames(15)
			check(a.position == home and a.shadow_return.seal.visible and not a.rig.visible,"Complete hand-seal drawing plays before any teleport")
			check(a.shadow_return.seal.animation == ("SEAL_CHILL" if profile == "PHUZASHI_CHILL" else "SEAL_CLASSIC"),"Each PHU model keeps its own face/outfit during hand seals")
			await until_away(a)
			check(a.shadow_return.away and (a.position.x-b.position.x)*look < 0 and absf(a.position.x-b.position.x) >= 88,"Teleport appears on the marked enemy's rear with a solid body gap")
			await frames(95)
			check(a.global_position.distance_to(home) < 0.1 and not a.shadow_return.active,"Skill returns to its exact departure point after the rear strike")
			check(b.damage_taken == [50,28,26][block] and a.energy == 45,"Rear strike deals26 exactly once without awarding normal-hit mana")
			check(not a.start_action("SHADOW_RETURN") and get_nodes_in_group("six_skill_effects").is_empty(),"Consumed mark cannot repeat and no ground-hole projectile exists")
		await setup(profile)
		a.energy = 0
		a.cheer_buff = 8
		a.blink_cooldown = 1
		var all_free: bool = true
		for i in range(6):
			all_free = all_free and a._start_blink(1 if i%2 == 0 else -1)
			await frames(25)
			all_free = all_free and a.energy == 0 and a.blink_cooldown == 0
		check(all_free,"Stand allows repeated zero-mana dashes with no cooldown: "+profile)
		a._start_blink(1)
		await frames(5)
		check(a._start_blink(-1) and a.buff_blink_buffer == -1,"Rapid next dash press is buffered during a free stand dash")
		await frames(22)
		check(a.blink_timer > 0 and a.blink_direction == -1 and a.energy == 0,"Buffered stand dash chains after the first ends, without mana drain")
		a.cheer_buff = 0.03
		a._start_blink(1)
		await frames(28)
		check(a.blink_timer == 0 and a.buff_blink_buffer == 0 and not a._start_blink(1),"Expiring stand clears the queued free dash and restores the5MP requirement")
		a.energy = 5
		check(a._start_blink(1) and a.energy == 0 and a.blink_cooldown == 0.5,"Normal dash cost and cooldown return after the buff")
	# Evading a shuriken does not grant a mark.
	await setup()
	b._start_blink(-1)
	await frames(10)
	var star := Pulse.new()
	star.source = a
	star.position = Vector2(20,100)
	stage.add_child(star)
	star._on_target(b.hurt_area)
	check(not star.hit and a.shadow_return.target() == null,"Invulnerable evade does not count as a shuriken hit")
	star.queue_free()
	# Marks survive failed resource/cooldown requests and belong to one owner.
	await setup()
	a.shadow_return.confirm(b.hurt_area)
	a.energy = 29
	check(not a.start_action("SHADOW_RETURN") and a.shadow_return.target() == b and a.energy == 29,"Insufficient mana preserves the earned mark")
	a.energy = 100
	a.skills.cooldowns.SHADOW_RETURN = 3
	check(not a.start_action("SHADOW_RETURN") and a.shadow_return.target() == b,"Cooldown rejection also preserves the mark")
	await setup()
	a.shadow_return.confirm(b.hurt_area)
	check(b.shadow_return.target() == null,"One player's shuriken never unlocks the opponent's warp")
	b.shadow_return.confirm(a.hurt_area)
	var home_a: Vector2 = a.position
	var home_b: Vector2 = b.position
	a.start_action("SHADOW_RETURN")
	check(b.shadow_return.target() == a,"Spending P1's mark does not consume P2's mark")
	b.start_action("SHADOW_RETURN")
	await frames(105)
	check(not a.shadow_return.active and not b.shadow_return.active and a.shadow_return.origin == home_a and b.shadow_return.origin == home_b and a.position.distance_to(home_a) < 70 and b.position.distance_to(home_b) < 70,"Concurrent return skills retain separate origins and return home with normal hit recoil")
	for after_warp: bool in [false,true]:
		await setup()
		a.shadow_return.confirm(b.hurt_area)
		var home: Vector2 = a.position
		a.start_action("SHADOW_RETURN")
		if after_warp: await until_away(a)
		else: await frames(10)
		a.receive_attack(8,"PUNCH",b)
		await frames(8)
		check(not a.shadow_return.active and a.position.distance_to(home) < 50 and a.energy == 70,"Hit interruption returns safely with normal recoil and no refund, after_warp="+str(after_warp))
	await setup()
	a.shadow_return.confirm(b.hurt_area)
	var home: Vector2 = a.position
	a.start_action("SHADOW_RETURN")
	await until_away(a)
	a.apply_movement_lock(0.7)
	await frames(3)
	check(a.is_movement_locked() and a.position.distance_to(home) < 0.1 and a.movement_lock.anchor == home,"Being locked during a warp returns the lock anchor home instead of stranding the fighter")
	for left: bool in [false,true]:
		await setup()
		a.position.x = 400 if left else 850
		b.position.x = 75 if left else 1205
		await frames(3)
		a.shadow_return.confirm(b.hurt_area)
		a.start_action("SHADOW_RETURN")
		await until_away(a)
		check(a.position.x >= 75 and a.position.x <= 1205 and absf(a.position.x-b.position.x) >= 88,"Wall fallback stays on screen without overlapping bodies, left="+str(left))
	await capped()
	for slot in [0,1,2,4]: check(not a.request_skill_slot(slot),"Capped form still rejects carrot skill slot="+str(slot))
	a.energy = 29
	check(not a.request_skill_slot(3) and a.energy == 29,"Palm shove requires30MP and does not spend on failure")
	for left: bool in [false,true]:
		await capped(left)
		var x: float = b.position.x
		check(a.slot_action(3) == "CAPPED_SHOVE" and a.request_skill_slot(3) and a.energy == 70,"Bottle slot becomes a30MP palm shove in capped form")
		await frames(5)
		check(a.skills.extra_body.visible and a.skills.extra_body.animation == "SHOVE" and not a.red_awakened,"Capped shove uses its own open-palm drawings with cap and shirt")
		await frames(65)
		check(b.damage_taken == 10 and absf(b.position.x-x) > 200 and a.energy == 70,"Shove hits once and sends the actual enemy far away, left="+str(left))
		check(get_nodes_in_group("six_skill_effects").is_empty(),"Capped shove never secretly throws a bottle")
	await capped()
	Input.action_press("p2_guard")
	await frames(15)
	a.request_skill_slot(3)
	await frames(65)
	check(b.damage_taken == 2 and b.is_on_floor(),"Guarding a shove keeps normal chip and prevents the airborne launch")
	await capped()
	a.request_skill_slot(3)
	await frames(60)
	check(a.start_action("ULTIMATE") and a.energy == 0,"Capped shove and70MP transformation use their normal mana costs")
	await frames(200)
	check(a.red_awakened and a.slot_action(3) == "SOY_BOMB" and not a.request_skill_slot(3),"Awakening replaces shove with bottle while retaining the slot's cooldown")
	await frames(250)
	check(a.request_skill_slot(3) and a.action_name == "SOY_BOMB" and a.energy == 0,"Awakened bottle is free as before after the shared cooldown")
	await frames(36)
	var bottles: Array[Node] = get_nodes_in_group("six_skill_effects")
	check(not bottles.is_empty() and bottles[0].kind == "SOY_BOMB","Awakened slot spawns the real bottle projectile")
	var pads: Node = root.get_node("Gamepads")
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.configure_devices([2,5],{2:{"guid":"shove1","name":"Pad1"},5:{"guid":"shove2","name":"Pad2"}})
	for second: bool in [false,true]:
		await capped()
		var actor: PhuzashiCharacter = a
		if second:
			b.select_fighter("RED_CAP")
			b.controls_enabled = true
			b.energy = 100
			actor = b
		pads.waiting_neutral = false
		pads._apply_layout()
		button(5 if second else 2,JOY_BUTTON_DPAD_DOWN,true)
		await frames(2)
		button(5 if second else 2,JOY_BUTTON_LEFT_SHOULDER,true)
		await frames(3)
		check(actor.action_name == "CAPPED_SHOVE" and actor.energy == 70,"Each player's down+LB casts capped shove, P"+str(2 if second else 1))
	release()
	pads.configure_devices([])
	await setup()
	b.select_fighter("RED_CAP")
	b.controls_enabled = true
	b.energy = 100
	a.shadow_return.confirm(b.hurt_area)
	key(KEY_S,true)
	key(KEY_L,true)
	key(KEY_DOWN,true)
	key(KEY_KP_3,true)
	await frames(3)
	check(a.action_name == "SHADOW_RETURN" and b.action_name == "CAPPED_SHOVE","Both keyboard players independently use the same fourth-slot chord")
	release()
	stage.start_round()
	await frames(3)
	check(a.energy == 50 and a.shadow_return.target() == null and not a.shadow_return.active and a.buff_blink_buffer == 0,"New round clears marks, return state and dash buffer with the50MP opening")
	stage.queue_free()
	await frames(3)
	check(get_nodes_in_group("six_skill_effects").is_empty(),"Scene exit leaves no slot projectiles")
	print("SHADOW RETURN RULES RESULT: %d checks, %d failures" % [checks,failures])
	call_deferred("quit",1 if failures else 0)
