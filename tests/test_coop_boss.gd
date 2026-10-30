extends SceneTree
const Rules = preload("res://scripts/coop/coop_rules.gd")
const Profile = preload("res://scripts/input/controller_profile.gd")
var stage: Node3D
var a: CharacterBody3D
var b: CharacterBody3D
var boss: CharacterBody3D
var pads: Node
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
func dispatch(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	if DisplayServer.get_name() == "headless" and Engine.get_version_info().minor == 2: root.push_input(event)
func key(code: int, held: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = held
	dispatch(event)
func button(device: int, code: int, held: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = code
	event.pressed = held
	dispatch(event)
func axis(device: int, code: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = code
	event.axis_value = value
	dispatch(event)
func release() -> void:
	for code: int in [KEY_W,KEY_S,KEY_A,KEY_D,KEY_SPACE,KEY_J,KEY_K,KEY_L,KEY_Q,KEY_SHIFT,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_ENTER,KEY_KP_ENTER,KEY_KP_0,KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_P,KEY_CTRL,KEY_F1,KEY_ESCAPE,KEY_F9,KEY_U,KEY_I]: key(code,false)
	for device: int in [2,5]:
		for code: int in range(JOY_BUTTON_MAX): button(device,code,false)
		for code: int in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]: axis(device,code,0)
	for action: StringName in InputMap.get_actions(): Input.action_release(action)
func setup() -> void:
	release()
	stage.restart()
	stage.state = "FIGHT"
	boss.ai_enabled = false
	boss.position = Vector3.ZERO
	a.position = Vector3(-1.7,0.05,0.2)
	b.position = Vector3(1.7,0.05,0.2)
	await frames(6)
func run() -> void:
	pads = root.get_node("Gamepads")
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	pads.configure_devices([])
	stage = load("res://scenes/coop_boss.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	a = stage.team[0]
	b = stage.team[1]
	boss = stage.boss
	boss.ai_enabled = false
	await frames(8)
	check(stage.state == "READY" and not a.request_attack("PUNCH"),"Intro cannot attack early")
	check(a.profile == "PHUZASHI_CHILL" and b.profile == "RED_CAP","Exactly PHU CHILL and capped ASSJIRO enter co-op")
	check(a is CharacterBody3D and b is CharacterBody3D and boss is CharacterBody3D,"Players and boss use actual 3D physics bodies")
	check(a.sprite is Sprite3D and a.sprite.frames.resource_path.ends_with("chill_frames.res") and b.sprite.frames.resource_path.ends_with("red_cap_frames.res"),"Sprites reuse their own approved atlas banks without image conversion")
	check(stage.camera is Camera3D and stage.get_node("Courtyard3D/Floor3D") is StaticBody3D,"Shared 3D camera and solid 3D floor are present")
	await frames(110)
	check(stage.state == "FIGHT" and a.health == 200 and b.health == 200 and boss.health == 900,"Ready transitions to a playable two-person boss encounter")
	for actor: CharacterBody3D in [a,b]:
		for family: String in ["PUNCH","KICK"]:
			await setup()
			check(actor.request_attack(family) and actor.request_attack(family) and actor.request_attack(family),"Queue all three "+family+" hits for "+actor.display_name)
			await frames(120)
			check(boss.health == 900-(34 if family == "PUNCH" else 52),"Actual three-hit combo damage: "+actor.display_name+" "+family+" got="+str(900-boss.health))
			check(actor.damage_dealt == (34 if family == "PUNCH" else 52),"Contribution count records only that player's actual hits")
	await setup()
	a.request_attack("PUNCH")
	b.request_attack("KICK")
	await frames(50)
	check(boss.health == 878 and a.damage_dealt == 8 and b.damage_dealt == 14,"Two players independently damage the same boss")
	check(a.health == 200 and b.health == 200,"Normal attacks never damage teammates")
	await setup()
	a.position.z = 5
	await frames(4)
	a.request_attack("PUNCH")
	await frames(40)
	check(boss.health == 900,"Close screen X but distant 3D depth cannot connect a punch")
	await setup()
	boss.position.y = 3.2
	a.request_attack("PUNCH")
	await frames(40)
	check(boss.health == 900,"A grounded punch cannot hit a boss above its 3D strike height")
	await setup()
	a.request_attack("PUNCH")
	boss.position = Vector3(-3.5,0,0.2)
	await frames(40)
	check(boss.health == 900,"An attack keeps its initial aim and cannot hit behind automatically")
	await setup()
	a.position = Vector3(-3,0,2)
	b.position = Vector3(3,0,2)
	boss.position = Vector3(7,0,-4)
	await frames(3)
	key(KEY_W,true)
	key(KEY_UP,true)
	await frames(20)
	check(a.position.z < 1.0 and b.position.z < 1.0 and a.position.y < 0.1 and b.position.y < 0.1,"W and arrow Up move through depth without jumping")
	key(KEY_W,false)
	key(KEY_UP,false)
	await frames(3)
	key(KEY_SPACE,true)
	key(KEY_ENTER,true)
	await frames(3)
	check(a.position.y > 0.2 and b.position.y > 0.2,"Space and Enter jump independently")
	key(KEY_SPACE,false)
	key(KEY_ENTER,false)
	await setup()
	key(KEY_SPACE,true)
	key(KEY_J,true)
	await frames(3)
	check(a.action == "AIR_PUNCH" and b.action.is_empty(),"Simultaneous keyboard jump+punch becomes an aerial normal")
	await frames(55)
	check(boss.health == 891,"Aerial punch collides with the real boss")
	await setup()
	key(KEY_KP_2,true)
	await frames(3)
	check(b.action == "KICK" and a.action.is_empty(),"P2 keyboard attack owns only ASSJIRO")
	await frames(45)
	check(boss.health == 886,"P2 keyboard kick deals its ordinary fourteen damage")
	await setup()
	key(KEY_U,true)
	key(KEY_I,true)
	await frames(4)
	check(a.action.is_empty() and b.action.is_empty() and boss.health == 900,"Special and ultimate keys are inactive in the basic prototype")
	# Raw stick, buttons and remaps travel through the live manager, for two pads.
	pads.configure_devices([2,5],{2:{"guid":"coop1","name":"Coop1"},5:{"guid":"coop2","name":"Coop2"}})
	for i in range(2):
		await setup()
		pads.waiting_neutral = false
		pads._apply_layout()
		var actor: CharacterBody3D = stage.team[i]
		var other: CharacterBody3D = stage.team[1-i]
		var device: int = 2 if i == 0 else 5
		var before: Vector3 = actor.position
		axis(device,JOY_AXIS_LEFT_Y,0.15)
		await frames(4)
		check(absf(actor.position.z-before.z) < 0.02,"Co-op depth deadzone rejects stick drift for P"+str(i+1))
		axis(device,JOY_AXIS_LEFT_Y,-1)
		await frames(18)
		check(actor.position.z < before.z-0.5 and other.position.z > 0 and actor.position.y < 0.1,"Assigned left-stick Up is 3D movement for P"+str(i+1))
		await setup()
		pads.waiting_neutral = false
		pads._apply_layout()
		button(device,JOY_BUTTON_A,true)
		await frames(3)
		check(actor.position.y > 0.2 and other.position.y < 0.1,"Assigned A jumps only P"+str(i+1))
		await setup()
		pads.waiting_neutral = false
		pads._apply_layout()
		button(device,JOY_BUTTON_X,true)
		await frames(3)
		check(actor.action == "PUNCH" and other.action.is_empty(),"Assigned X attacks only P"+str(i+1))
		await setup()
		Profile.remap(pads.profile.bindings[actor.input_prefix],"punch",Profile.button(JOY_BUTTON_Y))
		Profile.remap(pads.profile.bindings[actor.input_prefix],"jump",Profile.button(JOY_BUTTON_B))
		pads.waiting_neutral = false
		pads._apply_layout()
		button(device,JOY_BUTTON_Y,true)
		await frames(3)
		check(actor.action == "PUNCH" and other.action.is_empty(),"Remapped punch works in co-op for P"+str(i+1))
		await setup()
		pads.waiting_neutral = false
		pads._apply_layout()
		button(device,JOY_BUTTON_B,true)
		await frames(3)
		check(actor.position.y > 0.2 and other.position.y < 0.1,"Remapped jump works in co-op for P"+str(i+1))
		pads.profile.bindings[actor.input_prefix] = Profile.defaults()
	release()
	pads.configure_devices([])
	# Boss area and timing are tested by actual attacks, not only geometry helpers.
	await setup()
	a.position = Vector3(0,0,2.4)
	b.position = Vector3(0,0,-2.4)
	await frames(3)
	boss.start_attack("SWEEP",a.position)
	await frames(15)
	check(a.health == 200 and b.health == 200 and boss.state == "WINDUP","Sweep gives a visible startup before damaging anyone")
	await frames(70)
	check(a.health == 178 and b.health == 200,"Sweep hits the front half-circle once and spares a player behind")
	await setup()
	a.position = Vector3(0,0,2.4)
	b.position = Vector3(-5,0,-4)
	await frames(3)
	boss.start_attack("SWEEP",a.position)
	await frames(40)
	key(KEY_SPACE,true)
	await frames(30)
	check(a.health == 200,"Jump avoids the actual sweeping arm")
	await setup()
	a.position = Vector3(3,0,2)
	b.position = Vector3(-5,0,-4)
	await frames(3)
	boss.start_attack("SLAM",a.position)
	var marked: Vector3 = boss.attack_center
	await frames(18)
	a.position = Vector3(-4,0,2)
	var max_step: float = 0
	var previous: Vector3 = boss.position
	for _i in range(75):
		await frames(1)
		max_step = maxf(max_step,boss.position.distance_to(previous))
		previous = boss.position
	check(boss.attack_center == marked and a.health == 200,"Slam locks its warning position and can be escaped in depth")
	check(max_step < 0.65 and Rules.flat(boss.position-marked).length() < 0.1,"Boss leap travels continuously to its marked landing")
	await setup()
	a.position = Vector3(2.5,0,0)
	b.position = Vector3(-5,0,-4)
	await frames(3)
	boss.start_attack("SLAM",a.position)
	await frames(90)
	check(a.health == 168 and b.health == 200,"Landing inside the slam takes exactly thirty-two damage")
	await setup()
	a.position = Vector3(3,0,0)
	b.position = Vector3(5,0,0)
	await frames(3)
	boss.start_attack("CHARGE",Vector3(8,0,0))
	await frames(110)
	check(a.health == 174 and b.health == 174,"Charge can hit both teammates once each along the actual lane")
	await setup()
	a.position = Vector3(0,0,2.4)
	b.position = Vector3(-5,0,-4)
	await frames(3)
	key(KEY_L,true)
	await frames(15)
	boss.start_attack("SWEEP",a.position)
	await frames(67)
	check(a.health == 198 and a.guard_meter == 76,"Held guard retains chip and consumes guard pressure")
	check(a.shield.visible,"Guard presents a transparent 3D shield")
	await setup()
	a.position = Vector3(0,0,2.4)
	b.position = Vector3(-5,0,-4)
	await frames(3)
	boss.start_attack("SWEEP",a.position)
	await frames(54)
	key(KEY_L,true)
	await frames(8)
	check(a.health == 200 and a.guard_meter == 100,"Well-timed guard absorbs a boss hit without damage or guard loss")
	await setup()
	a.position = Vector3(0,0,2.4)
	b.position = Vector3(-5,0,-4)
	await frames(3)
	key(KEY_L,true)
	await frames(15)
	a.guard_meter = 20
	boss.start_attack("SWEEP",a.position)
	await frames(65)
	check(a.health == 198 and a.guard_break > 0 and not a.guarding,"Empty guard causes stun without adding full hit damage")
	await frames(65)
	check(a.guard_break == 0 and a.guard_meter >= 50,"Guard break restores at least fifty guard after one second")
	await setup()
	Input.action_press("p1_dash")
	await frames(3)
	var dashing: bool = a.dash_remaining > 0
	a.receive_hit(22,boss.position,0)
	check(dashing and a.health == 178,"Movement dash has no unintended invulnerability")
	await setup()
	boss.take_hit(10,140,a)
	check(boss.state == "STAGGERED" and not is_instance_valid(boss.tell),"Pressure creates a real stagger and cancels the tell")
	check(boss.take_hit(10,10,b) == 12,"Both players receive the stagger damage opening")
	await frames(125)
	check(boss.state == "IDLE","Stagger expires after two seconds")
	boss.take_hit(500,0,a)
	check(boss.enraged,"Boss enters phase two below half health")
	await setup()
	boss.position = Vector3(8,0,-4)
	a.position = Vector3(-3,0,2)
	b.position = Vector3(-1.7,0,2)
	await frames(4)
	b.receive_hit(999,a.position,0)
	await frames(35)
	check(b.downed and b.position.y > -0.1 and stage.state == "FIGHT","Downed partner remains on the floor and encounter continues")
	key(KEY_Q,true)
	await frames(45)
	check(b.revive_progress > 0.6 and a.reviving,"Holding Q near the partner begins a timed revive")
	a.receive_hit(8,boss.position,0)
	key(KEY_Q,false)
	await frames(2)
	check(b.revive_progress == 0,"A hit interrupts and resets revive progress")
	await frames(40)
	key(KEY_Q,true)
	await frames(115)
	check(not b.downed and b.health == 70 and b.invulnerability > 0,"Revive restores seventy HP and brief protection")
	await setup()
	a.receive_hit(999,boss.position,0)
	b.receive_hit(999,boss.position,0)
	await frames(2)
	check(stage.state == "DEFEAT","Both teammates down ends the encounter")
	stage.restart()
	await frames(3)
	check(stage.state == "READY" and a.health == 200 and b.health == 200 and boss.health == 900 and not a.downed,"Retry restores the complete team and boss")
	await setup()
	boss.take_hit(9999,0,a)
	await frames(2)
	check(stage.state == "VICTORY" and not a.request_attack("PUNCH"),"Boss defeat ends combat and exposes retry/menu")
	await setup()
	stage.toggle_pause()
	var frozen: float = stage.elapsed
	await frames(12)
	check(stage.paused and stage.elapsed == frozen,"Pause freezes the entire encounter")
	stage.toggle_pause()
	await frames(3)
	check(not stage.paused and stage.elapsed > frozen,"Resume continues after pause")
	pads.open_settings()
	await frames(2)
	check(stage.paused and pads.settings_open,"Controller settings safely pause co-op")
	pads.close_settings()
	stage.toggle_pause()
	await frames(2)
	check(not stage.paused and not pads.settings_open,"Closing settings can resume the existing encounter")
	# The camera must keep feet and boss horns inside the HUD's safe area.
	await setup()
	a.position = Vector3(-9.5,0,5.8)
	b.position = Vector3(9.5,0,-5.8)
	boss.position = Vector3(4,0,1)
	await frames(140)
	var safe: bool = true
	for actor: Node3D in [a,b,boss]:
		for height: float in [0.0,5.7 if actor == boss else 2.9]:
			var screen: Vector2 = stage.camera.unproject_position(actor.position+Vector3(0,height,0))
			safe = safe and screen.x > 15 and screen.x < 1265 and screen.y > 137 and screen.y < 627
	check(safe,"Shared camera keeps separated players and full boss inside the HUD-safe rectangle")
	# Live AI must complete repeated attacks against ordinary human-controlled bodies.
	await setup()
	boss.ai_enabled = true
	for _i in range(6000):
		await frames(1)
		if stage.state == "DEFEAT": break
	check(stage.state == "DEFEAT" and a.downed and b.downed,"Live boss AI can finish the fight without scripted damage")
	check(boss.attack_index >= 3 and boss.health == 900,"AI cycles through its patterns while idle players cannot hurt it")
	release()
	stage.queue_free()
	await frames(3)
	check(pads.context == "VERSUS","Leaving co-op restores the original 2D controller context")
	var clean: bool = true
	for prefix: String in ["p1_","p2_"]:
		for event: InputEvent in InputMap.action_get_events(prefix+"coop_jump"):
			clean = clean and not event is InputEventJoypadButton and not event is InputEventJoypadMotion
	check(clean,"Co-op-only controller aliases do not leak into side-view matches")
	var menu: Control = load("res://scenes/title_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(3)
	key(KEY_F9,true)
	key(KEY_F9,false)
	await frames(5)
	check(current_scene is Node3D and current_scene.name == "CoopBoss3D","New title button opens the actual co-op scene")
	current_scene.return_to_menu()
	await frames(5)
	check(current_scene is Control and current_scene.has_method("start_versus"),"Co-op menu return restores the original title")
	current_scene.queue_free()
	await frames(3)
	print("COOP BOSS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
