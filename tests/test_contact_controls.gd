extends SceneTree
const Book = preload("res://scripts/combat/skill_book.gd")
const Profile = preload("res://scripts/input/controller_profile.gd")
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS "+label)
	else:
		failures += 1
		push_error("FAIL "+label)
func key(code: int, held: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = held
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func button(device: int, code: int, held: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = code
	event.pressed = held
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func release() -> void:
	for code: int in [KEY_S,KEY_J,KEY_K,KEY_L,KEY_SHIFT,KEY_DOWN,KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_CTRL]: key(code,false)
	for device: int in [2,5]:
		for code: int in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_X,JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_RIGHT_SHOULDER]: button(device,code,false)
	for command: StringName in InputMap.get_actions(): Input.action_release(command)
func setup(profile: String = "PHUZASHI", left: bool = false) -> void:
	release()
	stage.restart_match()
	stage.phase = "FIGHT"
	a.select_fighter(profile)
	b.select_fighter("PHUZASHI")
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 750 if left else 480
	b.position.x = a.position.x+(-110 if left else 110)
	a.energy = 100
	b.energy = 100
	if profile == "RED_CAP":
		a.red_awakened = true
		a.rig.set_red_awakened(true)
	await frames(6)
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	check(a.energy == 50 and b.energy == 50,"Opening mana remains 50")
	await setup()
	for code: int in [KEY_T,KEY_Y,KEY_F]:
		key(code,true)
		await frames(2)
		key(code,false)
		await frames(1)
	check(a.action_name == "" and a.energy == 100,"Former direct T/Y/F shortcuts no longer cast skills")
	key(KEY_U,true)
	await frames(2)
	key(KEY_U,false)
	check(a.action_name == "SPECIAL" and a.energy == 75,"Standing U remains the ordinary special input")
	await frames(65)
	key(KEY_I,true)
	await frames(2)
	key(KEY_I,false)
	check(a.action_name == "ULTIMATE" and a.energy == 15,"Standing I remains the PHUZASHI ultimate input")
	for left: bool in [false,true]:
		await setup("PHUZASHI",left)
		var original: float = b.position.x
		Input.action_press("p1_move_left" if left else "p1_move_right")
		var valid: bool = true
		for _i in range(60):
			await frames(1)
			valid = valid and absf(b.position.x-a.position.x) >= 87.9 and (b.position.x-a.position.x)*(-1 if left else 1) > 0
		check(valid and absf(b.position.x-original) > 90,"Walking pressure pushes without overlap in every tick, left="+str(left))
		await setup("PHUZASHI",left)
		b.position.x = 75 if left else 1205
		a.position.x = b.position.x+(88 if left else -88)
		Input.action_press("p1_move_left" if left else "p1_move_right")
		Input.action_press("p1_run")
		await frames(60)
		check(absf(absf(b.position.x-a.position.x)-88) < 0.1 and b.position.x == (75 if left else 1205),"Arena wall stops pressure without swapping or penetrating, left="+str(left))
		await setup("PHUZASHI",left)
		b.apply_movement_lock(1)
		original = b.position.x
		Input.action_press("p1_move_left" if left else "p1_move_right")
		await frames(20)
		check(b.position.x == original and absf(b.position.x-a.position.x) >= 87.9,"Bound fighter anchors the pushbox, left="+str(left))
		var displacements: Array[float] = []
		for move: String in ["PUNCH","KICK","KICK_3","ULTIMATE"]:
			await setup("PHUZASHI",left)
			original = b.position.x
			b.receive_attack(8 if move == "PUNCH" else (14 if move == "KICK" else (22 if move == "KICK_3" else 60)),move,a)
			check(b.hit_shake > 0 and b.impact_pause > 0,"Hit registers body shake and hit pause: "+move)
			await frames(22)
			displacements.append(absf(b.position.x-original))
			check((b.position.x-original)*(-1 if left else 1) > 1,"Recoil travels away from attacker: "+move+" left="+str(left))
		check(displacements[0] < displacements[1] and displacements[1] < displacements[2] and displacements[2] < displacements[3],"Punch, kick, finisher and ultimate have increasing physical recoil")
	for profile: String in Book.ROSTER:
		for slot in range(1,5):
			for second: bool in [false,true]:
				await setup(profile)
				var actor: PhuzashiCharacter = a
				if second:
					b.select_fighter(profile)
					b.energy = 100
					if profile == "RED_CAP":
						b.red_awakened = true
						b.rig.set_red_awakened(true)
					actor = b
					await frames(3)
				var down: int = KEY_DOWN if second else KEY_S
				var command: int = ([KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_CTRL] if second else [KEY_J,KEY_K,KEY_L,KEY_SHIFT])[slot-1]
				key(down,true)
				await frames(2)
				key(command,true)
				await frames(2)
				check(actor.action_name == Book.ROSTER[profile][slot],"Keyboard chord selects slot %d for %s P%d" % [slot+1,profile,2 if second else 1])
				check(actor.position.y == 586,"Crouch chord never accidentally jumps")
	var pads: Node = root.get_node("Gamepads")
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.configure_devices([2,5],{2:{"guid":"chord1","name":"Pad1"},5:{"guid":"chord2","name":"Pad2"}})
	for slot in range(1,5):
		await setup("PHUZASHI")
		pads.waiting_neutral = false
		pads._apply_layout()
		for device: int in [2,5]: button(device,JOY_BUTTON_DPAD_DOWN,true)
		await frames(2)
		for device: int in [2,5]: button(device,[JOY_BUTTON_X,JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_RIGHT_SHOULDER][slot-1],true)
		await frames(2)
		check(a.action_name == Book.ROSTER.PHUZASHI[slot] and b.action_name == Book.ROSTER.PHUZASHI[slot],"Two independent gamepads trigger down chord "+str(slot+1))
		check(a.position.y == 586 and b.position.y == 586,"Down+A is a skill, without jump buffering")
	release()
	pads.configure_devices([])
	await setup("PHUZASHI")
	a.energy = 5
	check(a._start_blink(1) and a.energy == 0,"PHUZASHI Blink now costs exactly five MP")
	await setup("RED_CAP")
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	a.energy = 69.9
	check(not a.start_action("ULTIMATE") and a.energy == 69.9,"Transformation rejects less than 70 MP without spending it")
	a.energy = 100
	check(a.start_action("ULTIMATE") and a.energy == 30,"Transformation spends 70 and preserves the remainder")
	await frames(200)
	check(a.red_awakened and a.energy == 30,"Completing awakening preserves the remaining mana")
	for slot in range(5):
		await setup("RED_CAP")
		a.energy = 0
		check(a.request_skill_slot(slot) and a.energy == 0,"Awakened attack slot %d works at zero mana" % [slot+1])
		await frames(120)
		check(a.energy == 0 and float(a.skills.cooldowns.get(Book.ROSTER.RED_CAP[slot],0)) > 0,"Free awakened attack retains a real cooldown and never drains mana")
	await setup("RED_CAP")
	a.energy = 17
	a.start_action("CARROT_SPIN")
	await frames(2)
	check(not a.rig.visible and not a.skills.extra_body.visible and a.skills.cyclone.visible,"Carrot cyclone replaces every human body layer")
	var protected: bool = true
	for _i in range(45):
		protected = protected and a.receive_attack(24,"SPECIAL",b) == -1 and not a.apply_movement_lock(0.7) and not a.hurt_area.can_be_hit_by(b)
		await frames(1)
	check(protected and a.health == 200 and a.energy == 17,"Cyclone ignores damage, projectiles and immobilization throughout use")
	await frames(30)
	check(not a.attack_invulnerable() and a.rig.visible and not a.skills.cyclone.visible,"Cyclone recovery restores the fighter and ends invulnerability")
	check(a.receive_attack(8,"PUNCH",b) >= 0 and a.health < 200,"Damage can hit normally after the cyclone ends")
	await setup("MUAY_THAI")
	check(a.rig.draft_animation.motion_frames.get_frame_count("IDLE") == 8 and a.rig.draft_animation.motion_frames.get_frame_count("DASH") == 8,"Muay Thai uses dedicated planted idle and dash drawings")
	var start: float = a.position.x
	a._start_dash(1)
	var increments: Array[float] = []
	var previous: float = start
	for _i in range(21):
		await frames(1)
		increments.append(absf(a.position.x-previous))
		previous = a.position.x
	check(increments.max() < 8 and increments[0] < increments[8] and a.position.x-start > 70 and a.position.x-start < 100,"Muay dash accelerates and decelerates smoothly without a position teleport")
	await setup("PHUZASHI")
	b.select_fighter("RED_CAP")
	b.energy = 100
	await frames(3)
	stage.get_node("UltimateCutins").history.clear()
	a.start_action("ULTIMATE")
	b.start_action("ULTIMATE")
	var cutin: Node = stage.get_node("UltimateCutins")
	check(cutin.current.profile == "PHUZASHI" and cutin.cards.size() == 1,"Concurrent ultimates queue both left-side portrait cards")
	start = a.position.x
	await frames(105)
	check(cutin.history == ["PHUZASHI","RED_CAP"] and a.position.x-start > 100,"Both portraits play while actual ultimate movement continues")
	await setup("MUAY_THAI")
	a.start_action("GORILLA_KING")
	check(cutin.current.profile == "MUAY_THAI","Muay Thai has its own ultimate portrait")
	stage.start_round()
	check(cutin.current.is_empty() and cutin.cards.is_empty(),"Round reset removes portrait cards and queued casts")
	stage.queue_free()
	await frames(3)
	print("CONTACT CONTROLS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
