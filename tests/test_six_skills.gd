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
func setup(profile: String = "PHUZASHI", left: bool = false, distance: float = 110) -> void:
	for command: StringName in InputMap.get_actions(): Input.action_release(command)
	stage.restart_match()
	stage.phase = "FIGHT"
	a.select_fighter(profile)
	b.select_fighter("PHUZASHI")
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 750 if left else 480
	b.position.x = a.position.x+(-distance if left else distance)
	a.energy = 100 # Explicit combat fixture; production opening tested separately.
	b.energy = 100
	if profile == "RED_CAP":
		a.red_awakened = true
		a.rig.set_red_awakened(true)
	await frames(6)
	# General skill fixtures begin with a confirmed mark; gate behavior is
	# exercised separately with actual shuriken collisions and guards.
	if a.uses_dark_pulse(): a.shadow_return.confirm(b.hurt_area)
	if b.uses_dark_pulse(): b.shadow_return.confirm(a.hurt_area)
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	check(a.energy == 50 and b.energy == 50,"Both versus players open at 50/100 MP")
	for profile: String in Book.ROSTER:
		a.select_fighter(profile)
		check(a.energy == 50 and Book.ROSTER[profile].size() == 6,"Exactly six slots and a 50-MP opening: "+profile)
		check(not a.request_skill_slot(5) and a.energy == 50,"Opening mana cannot immediately buy the ultimate: "+profile)
	stage.phase = "FIGHT"
	a.select_fighter("PHUZASHI")
	a.controls_enabled = true
	Input.action_press("p1_charge")
	await frames(60)
	check(absf(a.energy-57) < 0.2,"Charging still grants seven MP per second from 50")
	Input.action_release("p1_charge")
	stage.start_round()
	check(a.energy == 50 and b.energy == 50,"Every new round resets both sides to 50 MP")
	var mapping: Dictionary = Profile.defaults()
	check(Profile.validate_map(mapping),"Expanded controller defaults have no duplicate inputs")
	var legacy: Dictionary = mapping.duplicate(true)
	legacy.erase("skill_four")
	legacy.erase("skill_five")
	Profile.remap(mapping,"special",Profile.axis(JOY_AXIS_RIGHT_Y,-1))
	legacy = mapping.duplicate(true)
	legacy.erase("skill_four")
	legacy.erase("skill_five")
	var upgraded: Dictionary = Profile.upgrade_map(legacy)
	check(Profile.validate_map(upgraded) and upgraded.special == legacy.special,"Old custom pad profiles acquire free new bindings without losing remaps")
	for left: bool in [false,true]:
		for spec: Array in [["PHUZASHI","SHADOW_RETURN",26,215],["RED_CAP","CARROT_UPROOT",24,100],["RED_CAP","SOY_BOMB",22,300],["RED_CAP","CARROT_SPIN",30,100],["MUAY_THAI","GORILLA_ELBOW",30,110],["MUAY_THAI","GORILLA_KNEE",26,100],["MUAY_THAI","GORILLA_QUAKE",24,230],["MUAY_THAI","GORILLA_ROAR",10,150],["MUAY_THAI","GORILLA_KING",60,105]]:
			await setup(spec[0],left,spec[3])
			check(a.start_action(spec[1]),"Cast "+spec[1]+" left="+str(left))
			check(a.energy == 100-a.skill_mana_cost(spec[1]),"Mana deducted exactly once: "+spec[1])
			await frames(200)
			check(is_equal_approx(b.damage_taken,spec[2]),"Actual hit damage %d for %s left=%s, got %.1f" % [spec[2],spec[1],str(left),b.damage_taken])
			check(a.energy == 100-a.skill_mana_cost(spec[1]),"Skills never award normal-hit mana: "+spec[1])
	await setup("PHUZASHI",false,215)
	var origin: Vector2 = a.position
	a.start_action("SHADOW_RETURN")
	await frames(32)
	Input.action_press("p2_jump")
	await frames(2)
	Input.action_release("p2_jump")
	await frames(95)
	check(a.position.distance_to(origin) < 0.1 and not a.shadow_return.active,"Shadow Return comes home after an opponent's jump without a floor hazard")
	await setup("PHUZASHI")
	a.start_action("SHADOW_RETURN")
	await frames(100)
	var before: float = a.energy
	check(not a.start_action("SHADOW_RETURN") and a.energy == before,"Cooldown rejects recasting without charging mana again")
	await setup("PHUZASHI")
	a.start_action("SHADOW_COUNTER")
	await frames(10)
	b.start_action("PUNCH")
	await frames(55)
	check(a.damage_taken == 0 and b.damage_taken == 20 and a.energy == 70,"Timed shadow counter absorbs melee and confirms one retaliation")
	await setup("PHUZASHI")
	a.start_action("SHADOW_COUNTER")
	await frames(12)
	a.receive_attack(24,"SPECIAL",b)
	check(a.health == 176,"Shadow counter does not absorb projectiles")
	await setup("PHUZASHI")
	a.start_action("SHADOW_COUNTER")
	await frames(28)
	a.receive_attack(8,"PUNCH",b)
	check(a.health == 192,"Counter recovery remains punishable")
	await setup("RED_CAP")
	a.start_action("CARROT_UPROOT")
	await frames(27)
	check(b.launched_once and b.velocity.y < 0 and b.position.y < 586,"Uproot launches the actual opponent body for an aerial follow-up")
	await setup("PHUZASHI")
	a.start_action("SHADOW_RETURN")
	a.receive_attack(8,"PUNCH",b)
	await frames(70)
	check(get_nodes_in_group("six_skill_effects").is_empty() and a.energy == 70,"Interrupting startup cancels the unreleased effect without refunding mana")
	await setup("RED_CAP")
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	for slot in range(5):
		if slot == 3: continue
		check(not a.request_skill_slot(slot) and a.energy == 100,"Capped Assjiro rejects attack slot "+str(slot+1))
	check(a.request_skill_slot(3) and a.action_name == "CAPPED_SHOVE" and a.energy == 70,"Capped Assjiro can use the shared bottle slot as a palm shove")
	await setup("RED_CAP")
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	check(a.request_skill_slot(5),"Full mana still starts the soy awakening")
	await frames(75)
	check(a.red_transform_phase() == "BLACK SOY SAUCE","Transformation phase explicitly identifies black soy sauce")
	await frames(130)
	check(a.red_awakened and a.energy == 30,"Black soy transformation finishes at exactly 70 MP")
	await setup("MUAY_THAI")
	a.start_action("GORILLA_GUARD")
	await frames(45)
	check(a.skills.guard_buff > 3 and a.energy == 75,"Gorilla embrace grants a timed guard benefit")
	Input.action_press("p1_guard")
	await frames(12)
	a.receive_attack(8,"PUNCH",b)
	check(is_equal_approx(a.guard_meter,94.5) and a.health == 198,"Embrace reduces guard cost by 45 percent while retaining chip damage")
	check(a.skills.stand.visible,"Brown gorilla is visible while the empowered guard is held")
	Input.action_release("p1_guard")
	await frames(260)
	check(a.skills.guard_buff == 0 and not a.skills.stand.visible,"Guard spirit and benefit expire cleanly")
	await setup("MUAY_THAI")
	a.start_action("GORILLA_KING")
	Input.action_press("p2_guard")
	await frames(160)
	check(b.damage_taken <= 2 and not a.skills.king_connected,"Blocking the ultimate opener prevents automatic follow-up hits")
	await setup("MUAY_THAI",false,400)
	a.start_action("GORILLA_KING")
	await frames(160)
	check(b.damage_taken == 0,"Gorilla ultimate cannot auto-connect from across the arena")
	await setup("PHUZASHI")
	Input.action_press("p1_crouch")
	Input.action_press("p1_chord_four")
	await frames(2)
	Input.action_release("p1_chord_four")
	Input.action_release("p1_crouch")
	check(a.action_name == "SHADOW_RETURN","New slot four input starts its assigned real skill")
	await frames(22)
	check(a.shadow_return.active and a.shadow_return.seal.visible,"Real hand-seal drawing is visible before teleport")
	stage.start_round()
	await frames(2)
	check(get_nodes_in_group("six_skill_effects").is_empty() and a.skills.cooldowns.is_empty(),"Round reset clears projectiles, cooldowns and temporary effects")
	await setup("PHUZASHI")
	var pads: Node = root.get_node("Gamepads")
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.configure_devices([2,5],{2:{"guid":"six-1","name":"Pad 1"},5:{"guid":"six-2","name":"Pad 2"}})
	pads.waiting_neutral = false
	pads._apply_layout()
	for device: int in [2,5]:
		var down := InputEventJoypadButton.new()
		down.device = device
		down.button_index = JOY_BUTTON_DPAD_DOWN
		down.pressed = true
		Input.parse_input_event(down)
	Input.flush_buffered_events()
	await frames(2)
	for spec: Array in [[2,JOY_BUTTON_LEFT_SHOULDER],[5,JOY_BUTTON_RIGHT_SHOULDER]]:
		var event := InputEventJoypadButton.new()
		event.device = spec[0]
		event.button_index = spec[1]
		event.pressed = true
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(2)
	check(a.action_name == "SHADOW_RETURN" and b.action_name == "SHADOW_COUNTER","Two pad crouch chords independently trigger slots four and five")
	check(a.energy == 70 and b.energy == 70,"Each assigned controller spends only its own fighter's mana")
	for device: int in [2,5]:
		for code: int in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
			var event := InputEventJoypadButton.new()
			event.device = device
			event.button_index = code
			event.pressed = false
			Input.parse_input_event(event)
	Input.flush_buffered_events()
	pads.configure_devices([])
	paused = false
	stage.paused = false
	await setup("PHUZASHI")
	for code: int in [KEY_DOWN,KEY_SLASH]:
		var key := InputEventKey.new()
		key.physical_keycode = code
		key.keycode = code
		key.pressed = true
		Input.parse_input_event(key)
	Input.flush_buffered_events()
	await frames(2)
	check(b.action_name == "SHADOW_RETURN" and a.action_name == "","P2 down+slash keyboard chord fires its own fourth skill")
	for code: int in [KEY_DOWN,KEY_SLASH]:
		var key := InputEventKey.new()
		key.physical_keycode = code
		key.keycode = code
		key.pressed = false
		Input.parse_input_event(key)
	Input.flush_buffered_events()
	stage.queue_free()
	await frames(3)
	set_meta("clear_training",true)
	var training: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(training)
	await frames(6)
	check(training.phuzashi.energy == 50,"Solo training also starts at 50 MP")
	training.queue_free()
	await frames(3)
	print("SIX SKILLS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
