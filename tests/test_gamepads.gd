extends SceneTree
## Synthetic JoypadButton/Motion events travel through Godot's real InputMap.
## This validates routing and gameplay without claiming a physical-pad test.
var checks: int = 0
var failures: int = 0
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter
var pads: Node

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

func button(device: int, code: int, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	# Godot 4.2's headless DisplayServer updates Input but has no window dispatcher.
	# Feed the same event to the root viewport to exercise _input callbacks too.
	if DisplayServer.get_name() == "headless" and Engine.get_version_info().minor == 2:
		root.push_input(event)

func axis(device: int, code: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = code
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	# Godot 4.2's headless DisplayServer updates Input but has no window dispatcher.
	# Feed the same event to the root viewport to exercise _input callbacks too.
	if DisplayServer.get_name() == "headless" and Engine.get_version_info().minor == 2:
		root.push_input(event)

func neutral() -> void:
	for device: int in [2,5,7]:
		for code: int in range(JOY_BUTTON_MAX):
			button(device,code,false)
		for code: int in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
			axis(device,code,0)
	await frames(3)

func setup() -> void:
	await neutral()
	stage.restart_match()
	stage.p1.energy = 100
	stage.p2.energy = 100
	pads._process(0)
	stage.phase = "FIGHT"
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 300
	b.position.x = 980
	await frames(4)

func run() -> void:
	pads = root.get_node("Gamepads")
	pads.set_process(false)
	stage = load("res://scenes/versus_school.tscn").instantiate()
	stage.round_health = 100 # Original damage/KO fixture; production defaults are covered separately.
	root.add_child(stage)
	await frames(5)
	a = stage.p1
	b = stage.p2
	pads.configure_devices([])
	check(pads.assignments.is_empty(),"No pad leaves both keyboard channels intact")
	pads.configure_devices([5])
	check(pads.assignments == {"p2_":5},"One pad automatically controls P2, including a nonzero device ID")
	check(pads.source_label("p1_") == "KEYBOARD" and pads.source_label("p2_") == "PAD 1 + KEYS","HUD identifies each player's actual input source")
	await setup()
	button(5,JOY_BUTTON_DPAD_LEFT,true)
	await frames(12)
	check(b.velocity.x < -180 and a.velocity.x == 0,"Single-pad D-pad moves only P2")
	button(5,JOY_BUTTON_DPAD_LEFT,false)
	Input.action_press("p1_move_right")
	button(5,JOY_BUTTON_DPAD_LEFT,true)
	await frames(12)
	check(a.velocity.x > 180 and b.velocity.x < -180,"Keyboard P1 and pad P2 can move simultaneously")
	Input.action_release("p1_move_right")
	await setup()
	axis(5,JOY_AXIS_LEFT_X,0.15)
	await frames(8)
	check(b.velocity.x == 0,"Analog deadzone rejects small stick drift")
	axis(5,JOY_AXIS_LEFT_X,-0.85)
	await frames(10)
	check(b.velocity.x < -180 and a.velocity.x == 0,"Left analog stick routes to the assigned player")
	await setup()
	button(5,JOY_BUTTON_A,true)
	await frames(2)
	check(b.velocity.y < 0 and a.is_on_floor(),"A / Cross jumps only the assigned fighter")
	button(5,JOY_BUTTON_A,false)
	button(5,JOY_BUTTON_X,true)
	await frames(2)
	check(b.action_name == "AIR_PUNCH","Pad can jump-punch using real button events")
	await setup()
	button(5,JOY_BUTTON_X,true)
	await frames(3)
	check(b.action_name == "PUNCH" and a.action_name == "","X / Square punches only P2")
	await frames(100)
	check(b.action_name == "" and b.combo_step == 0,"Holding a pad attack does not auto-repeat or generate combo taps")
	await setup()
	button(5,JOY_BUTTON_B,true)
	await frames(3)
	check(b.action_name == "KICK","B / Circle starts a kick")
	await setup()
	button(5,JOY_BUTTON_DPAD_RIGHT,true)
	button(5,JOY_BUTTON_RIGHT_SHOULDER,true)
	await frames(12)
	check(b.velocity.x > 330 and b.state_name == "RUN","RB / R1 runs with the D-pad")
	await setup()
	axis(5,JOY_AXIS_LEFT_Y,0.8)
	await frames(3)
	check(b.state_name == "CROUCH" and a.state_name == "IDLE","Stick down crouches only P2")
	await setup()
	button(5,JOY_BUTTON_DPAD_DOWN,true)
	await frames(3)
	check(b.state_name == "CROUCH","D-pad down also crouches")
	await setup()
	button(5,JOY_BUTTON_LEFT_SHOULDER,true)
	await frames(12)
	check(b.state_name == "GUARD" and b.can_guard(),"LB / L1 holds guard")
	b.receive_attack(8,"PUNCH",a)
	check(b.guard_meter == 90 and b.health == 98,"Pad guard uses the same meter and chip rules")
	await setup()
	b.energy = 0
	axis(5,JOY_AXIS_TRIGGER_LEFT,0.2)
	await frames(3)
	check(b.energy == 0,"Light trigger noise cannot charge")
	axis(5,JOY_AXIS_TRIGGER_LEFT,1)
	var time_before: float = b.elapsed
	await frames(60)
	check(absf(b.energy-(b.elapsed-time_before)*7) < 0.001 and b.charging,"LT / L2 charges at exactly 7 mana per second")
	axis(5,JOY_AXIS_TRIGGER_LEFT,0)
	await frames(3)
	check(not b.charging,"Releasing LT immediately ends charging")
	await setup()
	b.red_awakened = true
	b.rig.set_red_awakened(true)
	axis(5,JOY_AXIS_TRIGGER_RIGHT,1)
	await frames(3)
	check(b.action_name == "CARROT_HEADBUTT" and b.energy == 75,"P2 RT / R2 activates the new orange headbutt")
	await setup()
	b.red_awakened = true
	b.rig.set_red_awakened(true)
	button(5,JOY_BUTTON_DPAD_DOWN,true)
	button(5,JOY_BUTTON_X,true)
	await frames(3)
	check(b.action_name == "CARROT_RUSH" and b.energy == 70,"P2 Down + X / Square activates orange barrage")
	await setup()
	button(5,JOY_BUTTON_Y,true)
	await frames(3)
	check(b.action_name == "TRANSFORM" and b.energy == 0,"Y / Triangle activates Red Cap's 100-MP transformation")
	await frames(200)
	check(b.red_awakened,"Controller ultimate reaches the correct awakened form")
	await neutral()
	pads.swap_single_pad()
	check(pads.assignments == {"p1_":5} and stage.paused,"F5 swap changes the single pad to P1 and pauses for confirmation")
	pads._process(0)
	await setup()
	button(5,JOY_BUTTON_Y,true)
	await frames(3)
	check(a.action_name == "ULTIMATE" and a.energy == 40,"P1 Y / Triangle keeps PHUZASHI's original dragon ultimate")
	await setup()
	axis(5,JOY_AXIS_TRIGGER_RIGHT,1)
	await frames(3)
	check(a.action_name == "SPECIAL" and a.energy == 75 and b.action_name == "","RT / R2 activates PHUZASHI's skill without touching P2")
	await setup()
	button(5,JOY_BUTTON_DPAD_DOWN,true)
	button(5,JOY_BUTTON_X,true)
	await frames(3)
	check(a.action_name == "DEMON_BIND" and a.energy == 75,"Down + X / Square triggers the original Demon Bind")
	await setup()
	button(5,JOY_BUTTON_DPAD_RIGHT,true)
	await frames(2)
	button(5,JOY_BUTTON_DPAD_RIGHT,false)
	await frames(2)
	button(5,JOY_BUTTON_DPAD_RIGHT,true)
	await frames(2)
	check(a.blink_timer > 0 and a.energy == 85,"Double-tap D-pad direction activates the original Blink")
	await setup()
	pads.configure_devices([5,2])
	check(pads.assignments == {"p1_":2,"p2_":5},"Two pads map in sorted device order, never wildcard device -1")
	for prefix: String in ["p1_","p2_"]:
		var valid: bool = true
		var count: int = 0
		for command: String in pads.COMMANDS:
			for event: InputEvent in InputMap.action_get_events(prefix+command):
				if event is InputEventJoypadMotion or event is InputEventJoypadButton:
					valid = valid and event.device == int(pads.assignments[prefix])
					count += 1
		check(valid and count == 20,"Every gameplay pad binding, including new right-stick skills, has the correct explicit device: "+prefix)
	button(2,JOY_BUTTON_X,true)
	button(5,JOY_BUTTON_B,true)
	await frames(3)
	check(a.action_name == "PUNCH" and b.action_name == "KICK","Two separate pad buttons operate two different fighters in the same frame")
	await setup()
	axis(2,JOY_AXIS_LEFT_X,1)
	axis(5,JOY_AXIS_LEFT_X,-1)
	await frames(12)
	check(a.velocity.x > 180 and b.velocity.x < -180,"Two analog sticks move their own fighters independently")
	await setup()
	a.energy = 0
	b.energy = 0
	axis(2,JOY_AXIS_TRIGGER_LEFT,1)
	axis(5,JOY_AXIS_TRIGGER_LEFT,1)
	await frames(15)
	check(a.charging and b.charging and is_equal_approx(a.energy,b.energy),"Two controllers can charge independently and simultaneously")
	button(2,JOY_BUTTON_START,true)
	await frames(2)
	check(stage.paused,"Start pauses the match from either assigned controller")
	var energy_before: float = a.energy
	await frames(10)
	check(a.energy == energy_before,"Gamepad pause freezes resource clocks")
	button(2,JOY_BUTTON_START,false)
	button(2,JOY_BUTTON_START,true)
	await frames(2)
	check(not stage.paused and pads.waiting_neutral,"Start resumes, while held trigger input remains gated")
	check(not pads._is_neutral(),"Raw joystick state detects held triggers during neutral rearm")
	pads._process(0)
	check(pads.waiting_neutral,"Neutral polling cannot rearm a controller whose trigger is still held")
	await frames(3)
	check(not a.charging and not b.charging,"Held charge cannot leak through pause into resumed combat")
	await neutral()
	pads._process(0)
	check(not pads.waiting_neutral,"Releasing controls rearms gamepad gameplay")
	axis(5,JOY_AXIS_TRIGGER_LEFT,1)
	await frames(3)
	check(b.charging and not a.charging,"New trigger input works after neutral rearm")
	button(5,JOY_BUTTON_BACK,true)
	await frames(2)
	check(stage.show_help,"Back / Select opens the controls panel")
	button(5,JOY_BUTTON_BACK,false)
	await neutral()
	pads.configure_devices([7])
	pads.single_pad_player = 2
	pads.configure_devices([7])
	await setup()
	b.energy = 0
	axis(7,JOY_AXIS_TRIGGER_LEFT,1)
	await frames(3)
	check(b.charging,"Replacement device ID is usable after remapping")
	pads._connection_changed(7,false)
	await frames(3)
	check(stage.paused and pads.assignments.is_empty() and not Input.is_action_pressed("p2_charge"),"Disconnect handler pauses and releases the old held controller actions")
	check(stage.pause_reason.contains("CONTROLLER"),"Disconnected controller has a clear pause message")
	await neutral()
	pads.configure_devices([5])
	pads.device_changed.emit()
	check(stage.paused and pads.assignments == {"p2_":5},"A replacement pad can reconnect on a different ID without restarting")
	button(5,JOY_BUTTON_Y,true)
	await frames(3)
	check(stage.phase == "READY" and not stage.paused and stage.scores == [0,0],"Paused Y / Triangle starts a fresh match entirely from the pad")
	await neutral()
	pads._process(0)
	stage.phase = "MATCH_OVER"
	stage.scores.assign([2,0])
	button(5,JOY_BUTTON_START,true)
	await frames(2)
	check(stage.phase == "READY" and stage.scores == [0,0],"Start rematches a completed match without the keyboard")
	await neutral()
	pads._process(0)
	stage.queue_free()
	await frames(3)
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(5)
	pads._process(0)
	check(pads.context == "TRAINING" and pads.assignments == {"":5},"Solo training routes the first pad to the solo fighter")
	button(5,JOY_BUTTON_X,true)
	await frames(3)
	check(stage.phuzashi.action_name == "PUNCH","Solo training accepts controller normals")
	await neutral()
	stage.phuzashi.reset_training()
	stage.phuzashi.energy = 100 # Explicit full-mana combat fixture.
	await frames(4)
	stage.phuzashi.energy = 0
	axis(5,JOY_AXIS_TRIGGER_LEFT,1)
	await frames(10)
	check(stage.phuzashi.charging and stage.phuzashi.energy > 1,"Solo training accepts controller charging")
	await neutral()
	stage.queue_free()
	await frames(3)
	pads.configure_devices(Input.get_connected_joypads())
	pads.set_process(true)
	check(get_nodes_in_group("bind_targets").is_empty(),"Controller tests leave no fighters or stale scene connections")
	print("GAMEPAD RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
