extends Node
## Device-specific InputMap bindings: keyboards remain available alongside pads.
## One pad defaults to P2 in versus; F5 swaps its side. Two pads are independent.
signal layout_changed
signal pause_requested
signal help_requested
signal device_changed
const Setup = preload("res://scripts/character/input_setup.gd")
const DEADZONE: float = 0.28
const COMMANDS: Array[String] = ["move_left","move_right","jump","crouch","run","guard","punch","kick","charge","special","ultimate","red_ultimate","pad_ultimate"]
const BUTTONS: Dictionary = {
 "jump":JOY_BUTTON_A, "punch":JOY_BUTTON_X, "kick":JOY_BUTTON_B,
 "guard":JOY_BUTTON_LEFT_SHOULDER, "run":JOY_BUTTON_RIGHT_SHOULDER
}
var context: String = "VERSUS"
var devices: Array[int] = []
var assignments: Dictionary = {}
var single_pad_player: int = 2
var waiting_neutral: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Setup.install()
	Input.joy_connection_changed.connect(_connection_changed)
	configure_devices(Input.get_connected_joypads())

func set_context(value: String) -> void:
	if context != value:
		context = value
		configure_devices(devices)

func configure_devices(connected: Array) -> void:
	devices.assign(connected)
	devices.sort()
	assignments.clear()
	if not devices.is_empty():
		if context == "TRAINING":
			assignments[""] = devices[0]
		elif devices.size() == 1:
			assignments["p%d_" % single_pad_player] = devices[0]
		else:
			assignments["p1_"] = devices[0]
			assignments["p2_"] = devices[1]
	_apply_layout()
	layout_changed.emit()

func _connection_changed(_id: int, _connected: bool) -> void:
	configure_devices(Input.get_connected_joypads())
	suspend_until_neutral()
	device_changed.emit()

func swap_single_pad() -> void:
	if devices.size() != 1 or context != "VERSUS":
		return
	single_pad_player = 1 if single_pad_player == 2 else 2
	configure_devices(devices)
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
	if waiting_neutral:
		return
	for prefix: String in assignments:
		var device: int = assignments[prefix]
		# A separate pad action keeps Y ultimate while Red Cap keyboard I is headbutt.
		_button(prefix+"pad_ultimate",device,JOY_BUTTON_Y)
		for command: String in BUTTONS:
			_button(prefix+command,device,BUTTONS[command])
		_button(prefix+"move_left",device,JOY_BUTTON_DPAD_LEFT)
		_button(prefix+"move_right",device,JOY_BUTTON_DPAD_RIGHT)
		_button(prefix+"jump",device,JOY_BUTTON_DPAD_UP)
		_button(prefix+"crouch",device,JOY_BUTTON_DPAD_DOWN)
		_axis(prefix+"move_left",device,JOY_AXIS_LEFT_X,-1.0)
		_axis(prefix+"move_right",device,JOY_AXIS_LEFT_X,1.0)
		_axis(prefix+"crouch",device,JOY_AXIS_LEFT_Y,1.0)
		_axis(prefix+"charge",device,JOY_AXIS_TRIGGER_LEFT,1.0)
		_axis(prefix+"special",device,JOY_AXIS_TRIGGER_RIGHT,1.0)

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
			if code not in [JOY_BUTTON_START,JOY_BUTTON_BACK] and Input.is_joy_button_pressed(device,code):
				return false
		for axis: int in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]:
			if absf(Input.get_joy_axis(device,axis)) > DEADZONE:
				return false
	return true

func _process(_delta: float) -> void:
	if waiting_neutral and _is_neutral():
		waiting_neutral = false
		_apply_layout()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F5:
		swap_single_pad()
	if event is InputEventJoypadButton and event.pressed and event.device in assignments.values():
		if event.button_index == JOY_BUTTON_START:
			pause_requested.emit()
		elif event.button_index == JOY_BUTTON_BACK:
			help_requested.emit()

func source_label(prefix: String) -> String:
	if not assignments.has(prefix):
		return "KEYBOARD"
	return "PAD %d + KEYS" % (devices.find(assignments[prefix])+1)
