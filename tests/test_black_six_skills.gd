extends "res://tests/test_contact_controls.gd"
## Actual collision, life cycles and input ownership, not only metadata checks.
const ATTACKS_BLACK := ["BLOOD_FANG","RAGE_DRIVE","HELL_RISER","GRIN_CRUSH","CRIMSON_BURST"]
const DAMAGES := [22,30,28,32,18]
const EMPOWERED := [29,38,36,42,23]

func release() -> void:
	super.release()
	for code: int in [KEY_U,KEY_I,KEY_KP_4,KEY_KP_5]: key(code,false)

func distance_for(move: String) -> float:
	return 310 if move == "BLOOD_FANG" else 110

func arrange(move: String, left: bool = false) -> void:
	await setup("BLACK_COAT",left)
	b.position.x = a.position.x+(-1 if left else 1)*distance_for(move)
	await frames(3)

func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	await setup("BLACK_COAT")
	check(Book.ROSTER.BLACK_COAT.size() == 6 and not "" in Book.ROSTER.BLACK_COAT,"BLACK has six assigned skills including the original pact")
	for left: bool in [false,true]:
		for i in range(5):
			var move: String = ATTACKS_BLACK[i]
			await arrange(move,left)
			var hp: float = a.health
			check(a.start_action(move) and a.energy == 100-Book.cost(move),"Single mana spend "+move+" left="+str(left))
			await frames(180)
			check(b.damage_taken == DAMAGES[i],"Real collision "+move+" damage="+str(b.damage_taken)+" left="+str(left))
			check(a.health == hp and a.energy == 100-Book.cost(move),"Attacks neither self-bleed nor grant normal-hit mana: "+move)
			var mp: float = a.energy
			check(not a.start_action(move) and a.energy == mp,"Cooldown blocks repeated input without extra cost: "+move)
			await arrange(move,left)
			a.pact.commit()
			check(a.start_action(move),"Cast empowered "+move)
			await frames(180)
			check(b.damage_taken == EMPOWERED[i],"Pact scales each actual contact once: "+move+" got="+str(b.damage_taken))
			await arrange(move,left)
			Input.action_press("p2_guard")
			await frames(15)
			a.start_action(move)
			await frames(150)
			check(b.damage_taken == (6 if move == "RAGE_DRIVE" else 2),"Held guard retains fixed chip: "+move+" left="+str(left))
			check(not b.launched_once and b.is_on_floor(),"Blocked red skill does not launch: "+move)
			await arrange(move,left)
			a.energy = Book.cost(move)-0.1
			check(not a.start_action(move) and a.skills.cooldowns.is_empty(),"Insufficient mana never starts cooldown: "+move)
			await arrange(move,left)
			a.start_action(move)
			await frames(5)
			a.receive_attack(8,"PUNCH",b)
			if move in ["HELL_RISER","GRIN_CRUSH"]: check(not a.skills.black.body.visible and a.rig.visible,"Interruption immediately removes the special body, including during hit pause: "+move)
			await frames(150)
			check(b.damage_taken == 0 and a.energy == 100-Book.cost(move),"Interrupt before active frames cancels damage without refund: "+move)
	await arrange("RAGE_DRIVE")
	var gap: bool = true
	var peak_step: float = 0
	var previous: float = a.position.x
	var hits: Array[int] = []
	a.target_struck.connect(func(amount: int) -> void: hits.append(amount))
	a.start_action("RAGE_DRIVE")
	for _i in range(100):
		await frames(1)
		gap = gap and absf(b.position.x-a.position.x) >= 87.9
		peak_step = maxf(peak_step,absf(a.position.x-previous))
		previous = a.position.x
	check(hits == [8,8,14],"Rage drive confirms exactly three independently timed contacts")
	check(gap and peak_step < 5 and a.position.x > 515,"Rage drive advances continuously through solid pushboxes")
	await arrange("HELL_RISER")
	a.start_action("HELL_RISER")
	await frames(26)
	check(b.launched_once and b.position.y < 586 and b.velocity.y < 0 and b.action_name == "FALL","Hell riser launches the actual tumbling opponent")
	check(a.skills.black.body.visible and not a.rig.visible and a.skills.black.body.animation == "RISE","Uppercut owns its full-body animation")
	await arrange("GRIN_CRUSH")
	Input.action_press("p2_guard")
	await frames(15)
	a.start_action("GRIN_CRUSH")
	await frames(43)
	check(b.guard_meter == 60 and b.damage_taken == 2,"Grin crush removes forty guard without inflating chip damage")
	await arrange("GRIN_CRUSH")
	Input.action_press("p2_guard")
	await frames(15)
	b.guard_meter = 35
	a.start_action("GRIN_CRUSH")
	await frames(43)
	check(b.guard_break_remaining > 0 and b.damage_taken == 2,"Crush can break a depleted guard with the common punish window")
	await arrange("GRIN_CRUSH")
	a.start_action("GRIN_CRUSH")
	await frames(29)
	Input.action_press("p2_guard")
	await frames(10)
	check(b.damage_taken == 0 and b.guard_meter == 100 and b.defense_feedback == "PERFECT GUARD","Well-timed guard counters even the guard crusher")
	for side: int in [-1,1]:
		await arrange("CRIMSON_BURST",side < 0)
		a.facing = -side # Enemy is behind the caster for the entire cast.
		var origin: float = b.position.x
		a.start_action("CRIMSON_BURST")
		await frames(52)
		check(b.damage_taken == 18 and (b.position.x-origin)*side > 80,"Outburst hits behind and knocks outward, side="+str(side))
	await arrange("BLOOD_FANG")
	b.position.x = a.position.x+700
	a.start_action("BLOOD_FANG")
	await frames(120)
	check(b.damage_taken == 0 and get_nodes_in_group("crimson_fangs").is_empty(),"Fang has finite range and cleans itself after a miss")
	await arrange("BLOOD_FANG")
	a.start_action("BLOOD_FANG")
	await frames(25)
	check(get_nodes_in_group("crimson_fangs").size() == 1,"Exactly one scarlet projectile is released per cast")
	paused = true
	var fang: Node2D = get_nodes_in_group("crimson_fangs")[0]
	var pos: Vector2 = fang.position
	for _i in range(4): await process_frame
	check(fang.position == pos,"Pausing freezes the red projectile")
	paused = false
	stage.start_round()
	await frames(3)
	check(get_nodes_in_group("six_skill_effects").is_empty() and a.energy == 50 and a.skills.cooldowns.is_empty(),"Round clears red effects/cooldowns and keeps opening mana fifty")
	await arrange("BLOOD_FANG")
	a.start_action("BLOOD_FANG")
	await frames(25)
	a.health = 0
	await frames(3)
	check(get_nodes_in_group("crimson_fangs").is_empty(),"Caster KO removes a travelling fang")
	await setup("PHUZASHI")
	for move: String in ATTACKS_BLACK:
		check(not a.start_action(move) and a.energy == 100,"Other fighters cannot borrow "+move)
	await setup("BLACK_COAT")
	a.velocity.y = -300
	check(not a.start_action("BLOOD_FANG") and a.energy == 100,"Red skills cannot start while jumping")
	await setup("BLACK_COAT")
	a.apply_movement_lock(1)
	check(not a.start_action("CRIMSON_BURST") and a.energy == 100,"Outburst does not bypass an existing movement lock")
	await setup("BLACK_COAT")
	a.start_action("HELL_RISER")
	await frames(8)
	check(a.skills.black.body.visible,"Dedicated body is visible before a bind interruption")
	a.apply_movement_lock(0.7)
	check(not a.skills.black.body.visible and a.rig.visible,"Bind immediately restores one ordinary body and cancels the cast")
	# Standing U/RT and ultimate, plus all four down chords, for both players.
	var pads: Node = root.get_node("Gamepads")
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.configure_devices([2,5],{2:{"guid":"black1","name":"Pad1"},5:{"guid":"black2","name":"Pad2"}})
	for second: bool in [false,true]:
		for slot in range(6):
			for use_pad: bool in [false,true]:
				await setup("BLACK_COAT")
				var actor: PhuzashiCharacter = a
				if second:
					b.select_fighter("BLACK_COAT")
					b.energy = 100
					actor = b
					await frames(3)
				pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
				pads.waiting_neutral = false
				pads._apply_layout()
				if use_pad:
					var device: int = 5 if second else 2
					if slot in [1,2,3,4]:
						button(device,JOY_BUTTON_DPAD_DOWN,true)
						await frames(2)
					if slot == 0:
						var trigger := InputEventJoypadMotion.new()
						trigger.device = device
						trigger.axis = JOY_AXIS_TRIGGER_RIGHT
						trigger.axis_value = 1
						Input.parse_input_event(trigger)
						Input.flush_buffered_events()
					else: button(device,[JOY_BUTTON_X,JOY_BUTTON_X,JOY_BUTTON_B,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_Y][slot],true)
				else:
					if slot in [1,2,3,4]:
						key(KEY_DOWN if second else KEY_S,true)
						await frames(2)
					key(([KEY_KP_4,KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_CTRL,KEY_KP_5] if second else [KEY_U,KEY_J,KEY_K,KEY_L,KEY_SHIFT,KEY_I])[slot],true)
				await frames(2)
				check(actor.action_name == Book.ROSTER.BLACK_COAT[slot] and actor.energy == 100-Book.cost(Book.ROSTER.BLACK_COAT[slot]),"Real input P%d slot%d pad=%s" % [2 if second else 1,slot+1,str(use_pad)])
				check((a if second else b).action_name == "","Input remains owned by its assigned player")
				# Reset the RT axis, which is not a digital button.
				for device: int in [2,5]:
					var neutral := InputEventJoypadMotion.new()
					neutral.device = device
					neutral.axis = JOY_AXIS_TRIGGER_RIGHT
					neutral.axis_value = 0
					Input.parse_input_event(neutral)
				Input.flush_buffered_events()
	release()
	pads.configure_devices([])
	stage.queue_free()
	await frames(3)
	set_meta("solo_fighter","BLACK_COAT")
	var training: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(training)
	await frames(8)
	var actor: PhuzashiCharacter = training.phuzashi
	var target: Area2D = training.target
	check(actor.fighter_profile == "BLACK_COAT" and actor.energy == 50,"Solo selection loads BLACK with ordinary starting mana")
	for i in range(5):
		actor.reset_training()
		target.reset_target()
		actor.position.x = target.position.x-distance_for(ATTACKS_BLACK[i])
		actor.energy = 100
		await frames(5)
		actor.pact.commit()
		var recorded: Array[int] = []
		var listener: Callable = func(amount: int) -> void: recorded.append(amount)
		actor.target_struck.connect(listener)
		actor.start_action(ATTACKS_BLACK[i])
		await frames(150)
		check(target.total_damage == EMPOWERED[i],"Solo crystal receives empowered red skill: "+ATTACKS_BLACK[i])
		var total: int = 0
		for amount: int in recorded: total += amount
		check(total == EMPOWERED[i],"HUD signal matches actual empowered damage: "+ATTACKS_BLACK[i])
		actor.target_struck.disconnect(listener)
	training.queue_free()
	remove_meta("solo_fighter")
	await frames(3)
	print("BLACK SIX SKILLS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
