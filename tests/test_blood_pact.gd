extends "res://tests/test_contact_controls.gd"
## Combat outcomes and buff lifetimes, including interruption and low-health cases.
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	await setup("BLACK_COAT")
	check(a.display_name == "BLACK COAT" and a.energy == 100,"New black-coat fighter can enter a real match")
	for slot in range(5):
		check(not a.request_skill_slot(slot) and a.energy == 100,"Unassigned special slot stays empty: "+str(slot))
	check(not a.start_action("CHEER") and not a.start_action("SPECIAL"),"New fighter cannot borrow another fighter's spells")
	a.energy = 69
	check(not a.start_action("ULTIMATE") and a.energy == 69,"Pact requires 70 MP without charging a failed cast")
	a.energy = 100
	check(a.start_action("ULTIMATE") and a.energy == 30 and a.action_name == "BLOOD_PACT","Ultimate spends exactly 70 MP")
	await frames(35)
	check(a.pact.buff_remaining == 0 and a.health == 200,"Door startup gives no buff or self bleed before the slash")
	check(a.pact.door.visible and not a.attack_invulnerable(),"Door opens while the caster remains vulnerable")
	await frames(20)
	check(a.pact.buff_remaining > 9.7 and a.pact.bleed_remaining > 4.7,"Slash starts ten-second buff and five-second bleed")
	check(a.pact.flash > 0 and a.status_aura.kind == "RED","Slash shows blood and the red grinning demon")
	var cutins: Node = stage.get_node("UltimateCutins")
	check("BLACK_COAT" in cutins.history,"New fighter receives the same rectangular ultimate cut-in")
	await frames(300)
	check(absf(a.health-180) < 0.01 and a.pact.bleed_remaining == 0,"Full bleed removes exactly 20 HP over five seconds")
	check(a.pact.buff_remaining > 4.9 and a.outgoing_damage(10) == 13,"Attack bonus persists after bleeding stops")
	a.skills.cooldowns.BLOOD_PACT = 0
	check(not a.start_action("BLOOD_PACT") and a.energy == 30,"Active pact cannot stack even if cooldown is cleared")
	await frames(310)
	check(a.pact.buff_remaining == 0 and a.outgoing_damage(10) == 10 and not a.status_aura.visible,"Ten-second expiry removes bonus and red aura")
	await setup("BLACK_COAT")
	a.start_action("ULTIMATE")
	await frames(12)
	a.receive_attack(8,"PUNCH",b)
	await frames(130)
	check(a.pact.buff_remaining == 0 and a.pact.self_damage == 0 and a.health == 192,"Interrupting before the slash cancels the pact without refund")
	check(a.energy == 30 and not a.pact.door.visible,"Interrupted door vanishes and spent mana stays spent")
	await setup("BLACK_COAT")
	a.start_action("ULTIMATE")
	await frames(65)
	var hp: float = a.health
	a.receive_attack(8,"PUNCH",b)
	check(a.health < hp-7.9 and a.pact.buff_remaining > 0,"After slash, enemy attacks hurt normally without deleting the buff")
	await frames(300)
	check(absf(a.health-172) < 0.02,"Self bleed continues during hit stun and totals twenty separately from enemy damage")
	await setup("BLACK_COAT")
	a.health = 5
	a.start_action("ULTIMATE")
	await frames(370)
	check(is_equal_approx(a.health,1) and is_equal_approx(a.pact.self_damage,4),"Self sacrifice cannot kill a one-HP fighter")
	a.receive_attack(8,"PUNCH",b)
	await frames(2)
	check(a.health == 0 and a.pact.buff_remaining == 0 and not a.status_aura.visible,"Enemy damage can kill and clears the pact aura/status")
	for left: bool in [false,true]:
		for family: String in ["PUNCH","KICK"]:
			await setup("BLACK_COAT",left)
			a.start_action("ULTIMATE")
			await frames(115)
			a.start_action(family)
			a.start_action(family)
			a.start_action(family)
			await frames(120)
			var expected: int = 44 if family == "PUNCH" else 68
			check(b.damage_taken == expected,"Real +30% three-hit "+family+" combo, left="+str(left)+" got="+str(b.damage_taken))
			check(a.energy == 41,"Buffed normal hits still grant exactly 3+3+5 MP")
	await setup("BLACK_COAT")
	a.pact.commit()
	Input.action_press("p2_guard")
	await frames(15)
	a.start_action("PUNCH")
	await frames(40)
	check(b.damage_taken == 2,"Pact does not amplify two-HP guard chip")
	release()
	stage.start_round()
	await frames(3)
	check(a.energy == 50 and a.health == 200 and a.pact.buff_remaining == 0 and a.pact.bleed_remaining == 0,"New round clears all pact effects and restores the 50-MP opening")
	await setup("PHUZASHI")
	a.cheer_buff = 8
	await frames(2)
	check(a.status_aura.kind == "PURPLE" and a.status_aura.visible and a.bind_lock_duration() == 1.1,"Cheer adds a purple guardian while preserving the 1.1-second lock")
	a.start_action("DEMON_BIND")
	await frames(20)
	var demons: Array[Node] = get_nodes_in_group("demon_bind_effects")
	check(demons.size() == 1 and demons[0].empowered and demons[0].lock_time == 1.1,"Cheered bind snapshots compact rear-grapple presentation and buffed duration")
	a.cheer_buff = 0
	await frames(2)
	check(not a.status_aura.visible and a.bind_lock_duration() == 0.7,"Cheer expiry removes cloak and restores ordinary bind duration")
	await frames(120)
	a.start_action("DEMON_BIND")
	await frames(20)
	demons = get_nodes_in_group("demon_bind_effects")
	check(demons.size() == 1 and not demons[0].empowered and demons[0].lock_time == 0.7,"Next bind returns to its normal effect after cheer expires")
	await setup("RED_CAP")
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	a.start_action("ULTIMATE")
	await frames(135)
	check(a.status_aura.kind == "GOLD" and not a.red_awakened and a.red_transform_phase() == "SHIRT OFF","Orange-gold sacred guardian arrives with shirt removal")
	await frames(70)
	check(a.red_awakened and a.status_aura.kind == "GOLD" and a.energy == 30,"Golden aura remains in bald form without changing transformation cost")
	a.start_action("CARROT_SPIN")
	await frames(2)
	check(not a.status_aura.visible and a.cyclone_active(),"Cyclone replaces the whole body and hides the sacred guardian")
	await frames(75)
	check(a.status_aura.kind == "GOLD" and a.status_aura.visible,"Guardian returns after carrot cyclone")
	a.select_fighter("BLACK_COAT")
	await frames(2)
	check(not a.status_aura.visible and not a.red_awakened,"Changing character clears the previous guardian/form")
	for second: bool in [false,true]:
		await setup("BLACK_COAT")
		var actor: PhuzashiCharacter = a
		if second:
			b.select_fighter("BLACK_COAT")
			b.energy = 100
			actor = b
			await frames(3)
		var code: int = KEY_KP_5 if second else KEY_I
		key(code,true)
		await frames(2)
		key(code,false)
		check(actor.action_name == "BLOOD_PACT" and actor.energy == 30,"Real keyboard ultimate for BLACK COAT P"+str(2 if second else 1))
	var pads: Node = root.get_node("Gamepads")
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	pads.configure_devices([2,5],{2:{"guid":"pact1","name":"Pad1"},5:{"guid":"pact2","name":"Pad2"}})
	for second: bool in [false,true]:
		await setup("BLACK_COAT")
		var actor: PhuzashiCharacter = a
		if second:
			b.select_fighter("BLACK_COAT")
			b.energy = 100
			actor = b
			await frames(3)
		pads.waiting_neutral = false
		pads._apply_layout()
		button(5 if second else 2,JOY_BUTTON_Y,true)
		await frames(2)
		check(actor.action_name == "BLOOD_PACT" and actor.energy == 30,"Real controller ultimate for BLACK COAT P"+str(2 if second else 1))
		var other: PhuzashiCharacter = a if second else b
		check(other.action_name == "","Pact controller input never activates the other player")
	release()
	pads.configure_devices([])
	stage.queue_free()
	await frames(3)
	print("BLOOD PACT RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
