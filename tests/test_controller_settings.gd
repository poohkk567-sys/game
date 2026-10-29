extends SceneTree
const Profile = preload("res://scripts/input/controller_profile.gd")
var checks: int = 0
var failures: int = 0
var pads: Node
var stage: Node2D
var info: Dictionary = {2:{"guid":"alpha","name":"Alpha Pad"},5:{"guid":"beta","name":"Beta Pad"}}

func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS "+label)
	else:
		failures += 1
		push_error("FAIL "+label)
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func send(device: int, code: int, down: bool = true) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	if DisplayServer.get_name() == "headless" and Engine.get_version_info().minor == 2:
		root.push_input(event)
func motion(device: int, code: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = code
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	if DisplayServer.get_name() == "headless" and Engine.get_version_info().minor == 2:
		root.push_input(event)
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	pads._input(event)
func run() -> void:
	pads = root.get_node("Gamepads")
	pads.profile = Profile.new()
	pads.profile.path = "user://controller-settings-integration.cfg"
	pads.manual_devices.clear()
	pads.configure_devices([2,5],info)
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(115)
	check(Profile.validate_map(Profile.defaults()),"Default controller map contains unique valid controls")
	check(not Profile.valid_binding(Profile.button(JOY_BUTTON_RIGHT_STICK)),"R3 is reserved as a settings recovery button")
	check(not Profile.valid_choice({"mode":"pad"}),"Incomplete saved identities are rejected")
	key(KEY_F7)
	await frames(2)
	var ui: CanvasLayer = pads.settings_panel
	check(pads.settings_open and stage.paused and paused,"F7 opens settings and pauses the actual round")
	check(ui.shade.visible and not ui.shortcut.visible,"Modal settings replace the floating settings shortcut")
	check(ui.selectors.p1_.item_count == 4 and ui.selectors.p2_.item_count == 4,"Each player can choose Auto, keyboard or either named pad")
	var clock: float = stage.remaining
	var health: float = stage.p1.health
	await frames(8)
	check(stage.remaining == clock and stage.p1.health == health,"Editing settings preserves the running match")
	ui.choices = {"p1_":pads.device_choice(5),"p2_":pads.device_choice(2)}
	ui._refresh_devices()
	check(not ui.apply_button.disabled,"Independent reversed pad assignments are allowed")
	ui.choices.p2_ = pads.device_choice(5)
	ui._validate()
	check(ui.apply_button.disabled,"Same physical pad cannot be assigned to both players")
	var previous: Dictionary = pads.profile.preferences.duplicate(true)
	check(pads.apply_settings(ui.choices,ui.mappings) == ERR_INVALID_DATA and pads.profile.preferences == previous,"Invalid settings do not change the active profile")
	ui.choices.p2_ = pads.device_choice(2)
	ui.editing = "p1_"
	ui._listen_binding("punch")
	send(2,JOY_BUTTON_B)
	check(ui.listening == "punch","Capture ignores input from the other player's controller")
	send(2,JOY_BUTTON_B,false)
	send(5,JOY_BUTTON_B)
	check(ui.listening.is_empty() and ui.mappings.p1_.punch == [Profile.button(JOY_BUTTON_B)],"Capture binds P1 punch to its own B button")
	check(ui.mappings.p1_.kick == [Profile.button(JOY_BUTTON_X)] and Profile.validate_map(ui.mappings.p1_),"Duplicate button mapping swaps punch/kick without losing an action")
	send(5,JOY_BUTTON_B,false)
	check(ui.mappings.p2_ == Profile.defaults(),"P1 edits do not change P2's bindings")
	ui._listen_binding("charge")
	motion(5,JOY_AXIS_RIGHT_X,0.9)
	check(ui.listening == "charge","Axis capture requires returning the stick to neutral first")
	motion(5,JOY_AXIS_RIGHT_X,0)
	await frames(2)
	motion(5,JOY_AXIS_RIGHT_X,0.9)
	check(ui.listening.is_empty() and ui.mappings.p1_.charge == [Profile.axis(JOY_AXIS_RIGHT_X,1)],"Analog axes can be assigned to keyboard charge")
	motion(5,JOY_AXIS_RIGHT_X,0)

	ui._listen_device("p2_")
	send(2,JOY_BUTTON_A)
	check(ui.choices.p2_.device == 2 and ui.listening.is_empty(),"Press-to-identify selects the actual physical device")
	send(2,JOY_BUTTON_A,false)
	ui.apply()
	check(not pads.settings_open and stage.paused,"Saving returns to paused gameplay without resuming or resetting")
	check(pads.assignments == {"p1_":5,"p2_":2},"Saved manual layout reverses the two controllers")
	var saved = Profile.new()
	saved.path = pads.profile.path
	saved.load_settings()
	check(saved.preferences.p1_.guid == "beta" and saved.preferences.p2_.guid == "alpha","Disk settings contain stable device identities")
	check(not saved.preferences.p1_.has("device"),"Volatile runtime IDs are not persisted")
	check(saved.bindings.p1_.punch == [Profile.button(JOY_BUTTON_B)],"Custom action bindings survive a fresh profile load")
	check(saved.bindings.p1_.charge == [Profile.axis(JOY_AXIS_RIGHT_X,1)],"Analog remaps persist with their direction")
	pads._process(0)
	stage.toggle_pause()
	await frames(2)
	stage.p1.energy = 0
	motion(5,JOY_AXIS_RIGHT_X,0.9)
	await frames(12)
	check(stage.p1.charging and stage.p1.energy > 1 and not stage.p2.charging,"Remapped right stick charges only its assigned fighter")
	motion(5,JOY_AXIS_RIGHT_X,0)
	await frames(2)
	send(5,JOY_BUTTON_B)
	await frames(2)
	check(stage.p1.action_name == "PUNCH" and stage.p2.action_name == "","Remapped B reaches the P1 keyboard punch action in real gameplay")
	send(5,JOY_BUTTON_B,false)
	await frames(35)
	send(2,JOY_BUTTON_B)
	await frames(2)
	check(stage.p2.action_name == "KICK","P2 retains its independently configured kick")
	send(2,JOY_BUTTON_B,false)
	pads.profile = saved
	pads.manual_devices.clear()
	pads.configure_devices([7,9],{7:info[5],9:info[2]})
	check(pads.assignments == {"p1_":7,"p2_":9},"Saved choices reconnect by identity after runtime IDs change")
	pads.configure_devices([9],{9:info[2]})
	check(not pads.assignments.has("p1_") and pads.assignments.get("p2_") == 9,"Disconnecting a manual pad does not steal the other player's pad")
	pads.configure_devices([3,9],{3:info[5],9:info[2]})
	check(pads.assignments == {"p1_":3,"p2_":9},"Replacement device is reassigned to its saved player")
	pads.open_settings()
	await frames(2)
	var old_map: Dictionary = pads.profile.bindings.duplicate(true)
	ui._defaults()
	pads.menu_latches["p1_pad_pause"] = true # A release inside a modal must not leave a stale pause latch.
	pads.close_settings()
	check(pads.profile.bindings == old_map and pads.assignments == {"p1_":3,"p2_":9},"Cancel discards reset/default edits")
	send(3,JOY_BUTTON_START)
	await frames(2)
	check(not stage.paused,"First Start after closing settings resumes even if a pause release occurred inside the modal")
	send(3,JOY_BUTTON_START,false)
	pads.open_settings()
	ui.choices = {"p1_":{"mode":"keyboard"},"p2_":pads.device_choice(9)}
	ui.apply()
	check(not pads.assignments.has("p1_") and pads.assignments.p2_ == 9,"Keyboard-only P1 can coexist with a manually selected P2 pad")
	pads.set_context("TRAINING")
	check(pads.assignments.is_empty(),"Solo training respects the P1 keyboard-only preference")
	pads.profile.preferences.p1_ = {"mode":"auto"}
	pads.configure_devices([3,9],{3:info[5],9:info[2]})
	check(pads.assignments == {"":3},"Solo Auto selects the first available controller")
	pads.set_context("VERSUS")
	pads.profile = Profile.new()
	pads.manual_devices.clear()
	var twins: Dictionary = {2:{"guid":"same","name":"Twin Pad"},5:{"guid":"same","name":"Twin Pad"}}
	pads.configure_devices([2,5],twins)
	pads.profile.path = "user://controller-settings-twins.cfg"
	pads.apply_settings({"p1_":pads.device_choice(2),"p2_":pads.device_choice(5)},pads.profile.bindings)
	pads.configure_devices([5],{5:twins[5]})
	check(not pads.assignments.has("p1_") and pads.assignments.p2_ == 5,"Identical-model pads retain their existing owner's device during hotplug")
	pads.configure_devices([5,7],{5:twins[5],7:twins[2]})
	check(pads.assignments == {"p1_":7,"p2_":5},"A returning identical-model pad fills only the missing player's slot")
	pads.profile = Profile.new()
	pads.manual_devices.clear()
	pads.configure_devices(Input.get_connected_joypads())
	stage.queue_free()
	await frames(3)
	for name: String in ["user://controller-settings-integration.cfg","user://controller-settings-twins.cfg"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(name))
	print("CONTROLLER SETTINGS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
