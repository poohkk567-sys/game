extends SceneTree
var checks: int = 0
var failures: int = 0
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS "+label)
	else:
		failures += 1
		push_error("FAIL "+label)

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func setup(left: bool = false, awaken: bool = true) -> void:
	for command: StringName in InputMap.get_actions():
		Input.action_release(command)
	stage.restart_match()
	stage.phase = "FIGHT"
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 750 if left else 640
	b.position.x = 640 if left else 750
	await frames(5)
	if awaken:
		b.red_awakened = true
		b.rig.set_red_awakened(true)

func tap_key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	# Godot 4.2's headless DisplayServer updates Input but has no window dispatcher.
	# Feed the same event to the root viewport to exercise _input callbacks too.
	if DisplayServer.get_name() == "headless" and Engine.get_version_info().minor == 2:
		root.push_input(event)
	await frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	# Godot 4.2's headless DisplayServer updates Input but has no window dispatcher.
	# Feed the same event to the root viewport to exercise _input callbacks too.
	if DisplayServer.get_name() == "headless" and Engine.get_version_info().minor == 2:
		root.push_input(event)
	await frames(2)

func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	stage.round_health = 100 # Original damage/KO fixture; production defaults are covered separately.
	root.add_child(stage)
	await frames(5)
	a = stage.p1
	b = stage.p2
	check(not b.start_action("SPECIAL") and not b.start_action("DEMON_BIND"),"Countdown blocks both new Red Cap skills")
	for left: bool in [false,true]:
		await setup(left)
		var origin: Vector2 = b.position
		check(b.start_action("SPECIAL") and b.energy == 75 and b.action_name == "CARROT_HEADBUTT","Headbutt starts for exactly 25 MP, left="+str(left))
		await frames(18)
		check(b.position.y < origin.y and b.headbutt_launched,"Headbutt performs a real physical hop")
		check((b.position.x-origin.x)*b.facing > 10 and absf(b.rig.rotation) > 0.1,"Headbutt moves forward with a leaning whole-body pose")
		await frames(45)
		check(a.damage_taken == 22 and a.health == 78,"Headbutt hits exactly once for 22 damage, left="+str(left))
		check(b.energy == 75 and b.action_name == "" and b.rig.rotation == 0,"Recovery ends the aura/lean without generating mana")
		check(b.is_on_floor() and b.red_awakened,"Awakened body lands without reverting")
		await setup(left)
		check(b.start_action("DEMON_BIND") and b.energy == 70 and b.action_name == "CARROT_RUSH","Barrage starts for exactly 30 MP, left="+str(left))
		await frames(85)
		check(a.damage_taken == 32 and a.health == 68,"Seven real barrage pulses deal 6x4+8 damage, left="+str(left))
		check(b.carrot_pulse == 6 and b.energy == 70,"Barrage finishes its seventh pulse and never farms mana")
		check(not a.is_movement_locked() and get_nodes_in_group("demon_bind_effects").is_empty(),"Red Cap's Down+punch never borrows the purple movement-lock demon")
	for action: String in ["SPECIAL","DEMON_BIND"]:
		await setup()
		b.energy = 24 if action == "SPECIAL" else 29
		var mana: float = b.energy
		check(not b.start_action(action) and b.energy == mana,"Insufficient MP rejects new skill without spending: "+action)
		b.energy = 100
		Input.action_press("p2_guard")
		check(not b.start_action(action) and b.energy == 100,"Held guard blocks new skill: "+action)
		Input.action_release("p2_guard")
		b.velocity.y = -200
		check(not b.start_action(action) and b.energy == 100,"New skill must start on the ground: "+action)
		await setup()
		b.apply_movement_lock(0.7)
		check(not b.start_action(action) and b.energy == 100,"Movement lock blocks new skill: "+action)
		await setup()
		b.start_action("PUNCH")
		check(not b.start_action(action) and b.energy == 100,"Normal recovery cannot be cancelled into new skill: "+action)
	await setup()
	Input.action_press("p2_guard")
	await frames(12)
	check(a.start_action("PUNCH"),"Original PHUZASHI normals still work")
	await frames(35)
	check(b.guard_meter == 90 and is_equal_approx(b.health,98.6),"New skills do not alter normal guard rules")
	await setup()
	Input.action_press("p1_guard")
	await frames(12)
	b.start_action("DEMON_BIND")
	await frames(85)
	check(a.health == 86 and a.guard_meter == 64,"Blocking all seven barrage pulses costs 36 guard and 14 chip")
	check(b.energy == 70,"Barrage against guard never refunds mana")
	await setup()
	b.start_action("DEMON_BIND")
	await frames(20)
	b.receive_attack(8,"PUNCH",a)
	var damage_before: int = a.damage_taken
	await frames(80)
	check(a.damage_taken == damage_before and is_equal_approx(b.health,94.4),"Getting hit cancels remaining barrage pulses with awakened reduction")
	await setup()
	b.start_action("SPECIAL")
	await frames(7)
	b.apply_movement_lock(0.7)
	var pinned: Vector2 = b.position
	await frames(20)
	check(b.position.distance_to(pinned) < 0.1 and b.action_name == "" and b.rig.rotation == 0,"Demon lock cancels the headbutt hop, aura and rotation")
	await setup()
	await tap_key(KEY_KP_4)
	check(b.action_name == "CARROT_HEADBUTT" and b.energy == 75,"P2 Num4 starts headbutt through real keyboard input")
	await setup()
	await tap_key(KEY_APOSTROPHE)
	check(b.action_name == "CARROT_HEADBUTT","P2 apostrophe provides a laptop headbutt alternative")
	await setup()
	Input.action_press("p2_crouch")
	await tap_key(KEY_COMMA)
	check(b.action_name == "CARROT_RUSH" and b.energy == 70,"P2 Down + comma starts the new barrage")
	await setup(false,false)
	b.start_action("ULTIMATE")
	await frames(200)
	check(b.red_awakened,"Cap Off transformation still completes")
	b.energy = 100
	b.position.x = 750
	a.position.x = 640
	await frames(5)
	b.start_action("SPECIAL")
	await frames(60)
	check(b.red_awakened and a.damage_taken == 22,"Awakened bald body can headbutt without reverting to the cap")
	check(str(b.rig.draft_animation.get_script().resource_path).contains("red_awakened"),"Headbutt presentation keeps awakened art")
	a.reset_training()
	a.position.x = 640
	b.position.x = 750
	await frames(5)
	b.start_action("DEMON_BIND")
	await frames(85)
	check(b.red_awakened and a.damage_taken == 32,"Awakened body can also perform the full barrage")
	check(not b.purple_fist.active and get_nodes_in_group("purple_punch_impacts").is_empty(),"Both orange skills stay separate from PHUZASHI purple-fist art")
	await setup()
	stage.phase = "ROUND_OVER"
	b.controls_enabled = false
	check(not b.start_action("SPECIAL") and not b.start_action("DEMON_BIND"),"Round results gate both new skills")
	stage.queue_free()
	await frames(3)
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(5)
	b = stage.phuzashi
	b.select_fighter("RED_CAP")
	await frames(5)
	b.red_awakened = true
	b.rig.set_red_awakened(true)
	await tap_key(KEY_I)
	check(b.action_name == "CARROT_HEADBUTT" and b.energy == 75,"Solo Red Cap I is now headbutt, not the cap-removal ultimate")
	b.reset_training()
	await frames(5)
	await tap_key(KEY_O)
	check(b.action_name == "TRANSFORM" and b.energy == 0,"Solo Red Cap O retains the 100-MP transformation")
	b.select_fighter("PHUZASHI")
	await frames(5)
	await tap_key(KEY_I)
	check(b.action_name == "ULTIMATE" and b.energy == 40,"PHUZASHI I remains the original 60-MP dragon")
	stage.queue_free()
	await frames(3)
	print("CARROT SKILLS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
