extends Node
## Device-specific InputMap bindings: keyboards remain available alongside pads.
## One pad defaults to P2 in versus; F5 swaps its side. Two pads are independent.
signal layout_changed
signal pause_requested
signal help_requested
signal device_changed
const Setup = preload("res://scripts/character/input_setup.gd")
const Profile = preload("res://scripts/input/controller_profile.gd")
const Settings = preload("res://scripts/ui/controller_settings.gd")
const DEADZONE: float = 0.28
const COMMANDS: Array[String] = ["move_left","move_right","jump","crouch","run","guard","punch","kick","charge","special","ultimate","red_ultimate","pad_ultimate","dash","pad_pause","pad_help","cheer","skill_four","skill_five"]
var profile = Profile.new()
var device_info: Dictionary = {}
var manual_devices: Dictionary = {}
var settings_open: bool = false
var settings_panel: CanvasLayer
var menu_latches: Dictionary = {}
var context: String = "VERSUS"
var devices: Array[int] = []
var assignments: Dictionary = {}
var single_pad_player: int = 2
var waiting_neutral: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Setup.install()
	Input.joy_connection_changed.connect(_connection_changed)
	profile.load_settings()
	configure_devices(Input.get_connected_joypads())
	settings_panel = Settings.new()
	settings_panel.manager = self
	add_child(settings_panel)

func set_context(value: String) -> void:
	if context != value:
		context = value
		configure_devices(devices)

func configure_devices(connected: Array, descriptions: Dictionary = {}) -> void:
	menu_latches.clear()
	var previous: Array[int] = devices.duplicate()
	devices.assign(connected)
	devices.sort()
	var remembered: Dictionary = device_info.duplicate(true)
	device_info.clear()
	var instances: Dictionary = {}
	for device: int in devices:
		var data: Dictionary = descriptions.get(device,remembered.get(device,{"guid":"","name":"Gamepad"})).duplicate()
		if device in Input.get_connected_joypads():
			data = {"guid":Input.get_joy_guid(device),"name":Input.get_joy_name(device)}
		if str(data.get("name","")).is_empty():
			data["name"] = "Gamepad"
		var key: String = str(data.get("guid",""))+str(data.name)
		data["instance"] = int(instances.get(key,0))
		instances[key] = data.instance+1
		device_info[device] = data
	_resolve_assignments(previous)
	_apply_layout()
	layout_changed.emit()

func device_choice(device: int) -> Dictionary:
	var result: Dictionary = device_info[device].duplicate()
	result["mode"] = "pad"
	result["device"] = device
	return result

func matches(choice: Dictionary, device: int) -> bool:
	return device_info.has(device) and choice.get("guid","") == device_info[device].get("guid","") and choice.get("name","") == device_info[device].get("name","")

func _resolve_assignments(previous: Array[int]) -> void:
	var resolved: Dictionary = {}
	var used: Array[int] = []
	for prefix: String in ["p1_","p2_"]:
		var choice: Dictionary = profile.preferences[prefix]
		var old: int = int(manual_devices.get(prefix,-1))
		if choice.mode == "pad" and old in devices and matches(choice,old):
			resolved[prefix] = old
			used.append(old)
	for prefix: String in ["p1_","p2_"]:
		var choice: Dictionary = profile.preferences[prefix]
		if choice.mode != "pad" or resolved.has(prefix):
			continue
		var candidates: Array[int] = []
		for device: int in devices:
			if device not in used and matches(choice,device) and (not manual_devices.has(prefix) or device not in previous):
				candidates.append(device)
		if not candidates.is_empty():
			var index: int = mini(int(choice.get("instance",0)),candidates.size()-1)
			resolved[prefix] = candidates[index]
			used.append(candidates[index])
		manual_devices[prefix] = int(resolved.get(prefix,-1))
	var available: Array[int] = []
	for device: int in devices:
		if device not in used:
			available.append(device)
	var both_auto: bool = profile.preferences.p1_.mode == "auto" and profile.preferences.p2_.mode == "auto"
	for prefix: String in ["p1_","p2_"]:
		if profile.preferences[prefix].mode != "auto" or available.is_empty():
			continue
		if both_auto and devices.size() == 1 and prefix != "p%d_" % single_pad_player:
			continue
		resolved[prefix] = available.pop_front()
	assignments = resolved
	if context == "TRAINING":
		assignments = {}
		if profile.preferences.p1_.mode == "auto" and not devices.is_empty():
			assignments[""] = devices[0]
		elif profile.preferences.p1_.mode == "pad" and resolved.has("p1_"):
			assignments[""] = resolved.p1_

func pending_choices() -> Dictionary:
	var result: Dictionary = profile.preferences.duplicate(true)
	for prefix: String in ["p1_","p2_"]:
		if result[prefix].mode == "pad" and int(manual_devices.get(prefix,-1)) in devices:
			result[prefix]["device"] = manual_devices[prefix]
	return result

func validate_choices(choices: Dictionary) -> bool:
	if not Profile.valid_choice(choices.get("p1_")) or not Profile.valid_choice(choices.get("p2_")):
		return false
	if choices.p1_.mode == "pad" and choices.p2_.mode == "pad":
		if choices.p1_.get("device",-1) >= 0 and choices.p1_.get("device") == choices.p2_.get("device"):
			return false
		return not (choices.p1_.get("guid") == choices.p2_.get("guid") and choices.p1_.get("name") == choices.p2_.get("name") and choices.p1_.get("instance") == choices.p2_.get("instance"))
	return true

func apply_settings(choices: Dictionary, mappings: Dictionary) -> Error:
	if not validate_choices(choices):
		return ERR_INVALID_DATA
	var error: Error = profile.save_settings(choices,mappings)
	if error != OK:
		return error
	manual_devices.clear()
	for prefix: String in ["p1_","p2_"]:
		if choices[prefix].mode == "pad":
			manual_devices[prefix] = int(choices[prefix].get("device",-1))
	_resolve_assignments([])
	suspend_until_neutral()
	layout_changed.emit()
	return OK

func open_settings() -> void:
	if settings_open:
		return
	settings_open = true
	suspend_until_neutral()
	device_changed.emit()
	get_tree().paused = true
	settings_panel.open()

func close_settings() -> void:
	menu_latches.clear()
	settings_open = false
	settings_panel.close()
	suspend_until_neutral()

func _connection_changed(_id: int, _connected: bool) -> void:
	configure_devices(Input.get_connected_joypads())
	suspend_until_neutral()
	device_changed.emit()

func swap_single_pad() -> void:
	if settings_open or devices.size() != 1 or context != "VERSUS":
		return
	if profile.preferences.p1_.mode != "auto" or profile.preferences.p2_.mode != "auto":
		open_settings()
		return
	single_pad_player = 1 if single_pad_player == 2 else 2
	profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	manual_devices.clear()
	configure_devices(devices,device_info.duplicate(true))
	suspend_until_neutral()
	device_changed.emit()

func _erase_joy(action: String) -> void:
	if not InputMap.has_action(action):
		return
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(action,event)
	Input.action_release(action)

func _apply_layout() -> void:
	for prefix: String in ["","p1_","p2_"]:
		for command: String in COMMANDS:
			var action: String = prefix+command
			if not InputMap.has_action(action):
				InputMap.add_action(action,DEADZONE)
			InputMap.action_set_deadzone(action,DEADZONE)
			_erase_joy(action)
	for prefix: String in assignments:
		var device: int = assignments[prefix]
		var player: String = "p1_" if prefix.is_empty() else prefix
		for command: String in Profile.COMMANDS:
			if settings_open or (waiting_neutral and command not in ["pad_pause","pad_help"]):
				continue
			for binding: Dictionary in profile.bindings[player][command]:
				if binding.type == "button":
					_button(prefix+command,device,binding.code)
				else:
					_axis(prefix+command,device,binding.code,float(binding.sign))

func _button(action: String, device: int, code: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = code
	InputMap.action_add_event(action,event)

func _axis(action: String, device: int, code: int, direction: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = code
	event.axis_value = direction
	InputMap.action_add_event(action,event)

func suspend_until_neutral() -> void:
	waiting_neutral = not assignments.is_empty()
	_apply_layout()

func _is_neutral() -> bool:
	for device: int in assignments.values():
		for code: int in range(JOY_BUTTON_MAX):
			if Input.is_joy_button_pressed(device,code):
				return false
		for axis: int in range(JOY_AXIS_MAX):
			if absf(Input.get_joy_axis(device,axis)) > DEADZONE:
				return false
	return true

func _process(_delta: float) -> void:
	if not settings_open and waiting_neutral and _is_neutral():
		waiting_neutral = false
		_apply_layout()

func _input(event: InputEvent) -> void:
	if settings_open:
		settings_panel.handle_event(event)
		return
	var shortcut: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F7
	shortcut = shortcut or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_STICK and event.device in devices)
	if shortcut:
		open_settings()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F5:
		swap_single_pad()
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		for prefix: String in assignments:
			if event.device != assignments[prefix]:
				continue
			for command: String in ["pad_pause","pad_help"]:
				var action: String = prefix+command
				if event.is_action(action):
					var down: bool = event.is_action_pressed(action)
					var fresh: bool = down and not menu_latches.get(action,false)
					menu_latches[action] = down
					if fresh:
						if command == "pad_pause":
							pause_requested.emit()
						else:
							help_requested.emit()

func source_label(prefix: String) -> String:
	if not assignments.has(prefix):
		return "KEYBOARD"
	return "PAD %d + KEYS" % (devices.find(assignments[prefix])+1)
