extends CanvasLayer
## A modal, pause-safe controller assignment and action-binding screen.
const Profile = preload("res://scripts/input/controller_profile.gd")
var manager: Node
var shade: Control
var shortcut: Button
var tabs: TabContainer
var selectors: Dictionary = {}
var live: Dictionary = {}
var binding_buttons: Dictionary = {}
var player_selector: OptionButton
var apply_button: Button
var status: Label
var choices: Dictionary = {}
var mappings: Dictionary = {}
var editing: String = "p1_"
var listening: String = ""
var axis_armed: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var theme := Theme.new()
	var font: Font = load("res://assets/fonts/NotoSansThai-Regular.ttf").duplicate()
	font.fallbacks = [ThemeDB.fallback_font]
	theme.default_font = font
	theme.default_font_size = 18
	for kind: String in ["Button","OptionButton"]:
		for state: String in ["normal","hover","pressed","focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("28324b") if state == "normal" else Color("4f416d")
			style.border_color = Color("bb85ff") if state == "focus" else Color("61718c")
			style.set_border_width_all(2)
			style.set_corner_radius_all(5)
			style.content_margin_left = 12
			style.content_margin_right = 12
			style.content_margin_top = 7
			style.content_margin_bottom = 7
			theme.set_stylebox(state,kind,style)
	var root := Control.new()
	root.theme = theme
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shortcut = _button("ตั้งค่าจอย / F7",manager.open_settings)
	root.add_child(shortcut)
	shortcut.position = Vector2(1034,172)
	shortcut.size = Vector2(222,39)
	shade = Control.new()
	root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.022,0.04,0.94)
	shade.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.position = Vector2(140,64)
	panel.size = Vector2(1000,602)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101828")
	style.border_color = Color("b989f4")
	style.set_border_width_all(2)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel",style)
	shade.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	column.add_child(_label("ตั้งค่าจอย  /  CONTROLLERS",30))
	column.add_child(_label("เลือกจอยของแต่ละคน แล้วผูกปุ่มจอยกับคำสั่งบนคีย์บอร์ด",17))
	tabs = TabContainer.new()
	tabs.tab_changed.connect(func(_tab: int) -> void: call_deferred("_trap_focus"))
	tabs.custom_minimum_size = Vector2(950,370)
	column.add_child(tabs)
	var devices_tab := VBoxContainer.new()
	devices_tab.name = "จอย P1 / P2"
	devices_tab.add_theme_constant_override("separation",15)
	tabs.add_child(devices_tab)
	for prefix: String in ["p1_","p2_"]:
		var row := VBoxContainer.new()
		devices_tab.add_child(row)
		row.add_child(_label("ผู้เล่น 1 / P1" if prefix == "p1_" else "ผู้เล่น 2 / P2",21))
		var bar := HBoxContainer.new()
		row.add_child(bar)
		var select := OptionButton.new()
		select.custom_minimum_size = Vector2(600,46)
		select.item_selected.connect(func(index: int) -> void: _select_device(prefix,index))
		bar.add_child(select)
		selectors[prefix] = select
		bar.add_child(_button("กดปุ่มบนจอยเพื่อเลือก",func() -> void: _listen_device(prefix)))
		var feedback := _label("",16)
		row.add_child(feedback)
		live[prefix] = feedback
	devices_tab.add_child(_label("Auto: จอยเดียวเริ่มที่ P2 / สองจอยแยก P1 และ P2\nคีย์บอร์ดยังใช้ร่วมได้ • สนามฝึกใช้ค่าของ P1\nจอยรุ่นเดียวกันให้กดปุ่มบนจอยเพื่อระบุอันที่ต้องการ",16))
	var mapping_tab := VBoxContainer.new()
	mapping_tab.name = "ผูกปุ่มจอย"
	mapping_tab.add_theme_constant_override("separation",7)
	tabs.add_child(mapping_tab)
	player_selector = OptionButton.new()
	player_selector.add_item("แก้ปุ่มของ P1")
	player_selector.add_item("แก้ปุ่มของ P2")
	player_selector.item_selected.connect(func(index: int) -> void:
		editing = "p1_" if index == 0 else "p2_"
		listening = ""
		_refresh_bindings())
	mapping_tab.add_child(player_selector)
	mapping_tab.add_child(_label("คลิกคำสั่ง แล้วกดปุ่มหรือขยับแกนจอย • ปุ่มซ้ำจะสลับกัน • R3 เปิดตั้งค่าเสมอ",15))
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.custom_minimum_size = Vector2(920,262)
	mapping_tab.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for command: String in Profile.COMMANDS:
		var button := _button("",func() -> void: _listen_binding(command))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		rows.add_child(button)
		binding_buttons[command] = button
	status = _label("",16)
	status.custom_minimum_size.y = 30
	column.add_child(status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",14)
	column.add_child(actions)
	actions.add_child(_button("คืนค่าเริ่มต้น",_defaults))
	actions.add_child(_button("หน้าแรก",_home))
	actions.add_child(_button("ยกเลิก / Esc",manager.close_settings))
	apply_button = _button("บันทึก / Start",apply)
	actions.add_child(apply_button)
	column.add_child(_label("LB/RB เปลี่ยนแท็บ • Y สลับผู้เล่น • A เลือก • B กลับ • Start บันทึก • R3 ยกเลิกจับปุ่ม",15))
	manager.layout_changed.connect(_layout_changed)
	shade.hide()

func _trap_focus() -> void:
	var focusable: Array[Control] = []
	_collect_focus(shade,focusable)
	for i in range(focusable.size()):
		focusable[i].focus_next = focusable[i].get_path_to(focusable[(i+1)%focusable.size()])
		focusable[i].focus_previous = focusable[i].get_path_to(focusable[(i-1+focusable.size())%focusable.size()])

func _collect_focus(node: Node, found: Array[Control]) -> void:
	if node is Control and node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL and not (node is BaseButton and node.disabled):
		found.append(node)
	for child: Node in node.get_children():
		_collect_focus(child,found)

func _label(line: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = line
	result.add_theme_font_size_override("font_size",font_size)
	return result

func _button(line: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = line
	result.pressed.connect(callback)
	return result

func open() -> void:
	choices = manager.pending_choices()
	mappings = manager.profile.bindings.duplicate(true)
	listening = ""
	status.text = ""
	shade.show()
	shortcut.hide()
	_refresh_devices()
	_refresh_bindings()
	selectors.p1_.grab_focus()
	call_deferred("_trap_focus")

func close() -> void:
	shade.hide()
	shortcut.show()
	listening = ""
	get_viewport().gui_release_focus()

func _layout_changed() -> void:
	if manager.settings_open:
		listening = ""
		_refresh_devices()
		status.text = "รายการจอยเปลี่ยนแล้ว ตรวจชื่อจอยก่อนบันทึก"

func _refresh_devices() -> void:
	for prefix: String in ["p1_","p2_"]:
		var select: OptionButton = selectors[prefix]
		select.clear()
		var entries: Array = [{"mode":"auto"},{"mode":"keyboard"}]
		for device: int in manager.devices:
			entries.append(manager.device_choice(device))
		if choices[prefix].mode == "pad" and not manager.devices.has(int(choices[prefix].get("device",-1))):
			entries.append(choices[prefix])
		for entry: Dictionary in entries:
			var text: String = "อัตโนมัติ / Auto" if entry.mode == "auto" else "คีย์บอร์ดอย่างเดียว / Keyboard"
			if entry.mode == "pad":
				var device: int = int(entry.get("device",-1))
				text = "จอย %d — %s" % [manager.devices.find(device)+1,entry.name] if device in manager.devices else "ไม่ได้เชื่อมต่อ — "+str(entry.name)
			select.add_item(text)
			var index: int = select.item_count-1
			select.set_item_metadata(index,entry)
			if _same_choice(entry,choices[prefix]):
				select.select(index)
	_validate()

func _same_choice(a: Dictionary, b: Dictionary) -> bool:
	return a.mode == b.mode and (a.mode != "pad" or (a.get("guid") == b.get("guid") and a.get("name") == b.get("name") and a.get("instance") == b.get("instance")))

func _select_device(prefix: String, index: int) -> void:
	choices[prefix] = selectors[prefix].get_item_metadata(index).duplicate(true)
	listening = ""
	_validate()

func _validate() -> void:
	apply_button.disabled = not manager.validate_choices(choices)
	if apply_button.disabled:
		status.text = "จอยหนึ่งอันควบคุมได้หนึ่งผู้เล่น กรุณาเลือกจอยต่างกัน"
	elif not listening.is_empty():
		return
	else:
		status.text = "บันทึกแล้วจะกลับไปหน้าเกมที่พักอยู่"

func _listen_device(prefix: String) -> void:
	listening = "device:"+prefix
	status.text = "กดปุ่มบนจอยที่ต้องการให้ "+prefix.trim_suffix("_").to_upper()+" ใช้ (Esc ยกเลิก)"

func _listen_binding(command: String) -> void:
	var choice: Dictionary = choices[editing]
	var device: int = int(choice.get("device",manager.assignments.get(editing,-1)))
	if manager.context == "TRAINING" and editing == "p1_" and choice.mode == "auto":
		device = int(manager.assignments.get("",-1))
	if device not in manager.devices or choice.mode == "keyboard":
		status.text = "เลือกจอยของผู้เล่นนี้ในแท็บแรกก่อน"
		return
	listening = command
	axis_armed = false
	status.text = "ปล่อยสติ๊ก/ทริกเกอร์ แล้วกดปุ่มจอยสำหรับ "+Profile.NAMES[command]+" (Esc ยกเลิก)"

func _refresh_bindings() -> void:
	var keys: Dictionary = {"move_left":"←","move_right":"→","jump":"↑","crouch":"↓","run":"Ctrl","guard":"Num3 / /","punch":"Num1 / ,","kick":"Num2 / .","charge":"P","special":"Num4 / '","pad_ultimate":"Num5 / ;","dash":"Num0 / \\","pad_pause":"Esc","pad_help":"F1","cheer":"["}
	for command: String in Profile.COMMANDS:
		var line: String = Profile.NAMES[command]
		if editing == "p2_":
			line = line.get_slice(" / ",0)+" / "+str(keys[command])
		binding_buttons[command].text = line+"     →     "+Profile.mapping_label(mappings[editing][command])

func _defaults() -> void:
	choices = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	mappings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	listening = ""
	_refresh_devices()
	_refresh_bindings()

func _home() -> void:
	manager.close_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_menu.tscn")

func apply() -> void:
	if not manager.validate_choices(choices):
		_validate()
		return
	var error: Error = manager.apply_settings(choices,mappings)
	if error != OK:
		status.text = "บันทึกไม่สำเร็จ กรุณาตรวจสิทธิ์โฟลเดอร์ข้อมูลเกม"
		return
	manager.close_settings()

func handle_event(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE,KEY_F7]:
		if not listening.is_empty():
			listening = ""
			_validate()
		else:
			manager.close_settings()
		get_viewport().set_input_as_handled()
		return
	if not listening.is_empty():
		var captured: Dictionary = {}
		if event is InputEventJoypadButton and event.pressed:
			if event.button_index == JOY_BUTTON_RIGHT_STICK:
				listening = ""
				_validate()
				get_viewport().set_input_as_handled()
				return
			captured = Profile.button(event.button_index)
		elif event is InputEventJoypadMotion and axis_armed and absf(event.axis_value) >= 0.65:
			captured = Profile.axis(event.axis,1 if event.axis_value > 0 else -1)
		if captured.is_empty() or event.device not in manager.devices:
			return
		if listening.begins_with("device:"):
			choices[listening.trim_prefix("device:")] = manager.device_choice(event.device)
			listening = ""
			_refresh_devices()
		else:
			var expected: int = int(choices[editing].get("device",manager.assignments.get("" if manager.context == "TRAINING" else editing,-1)))
			if event.device != expected:
				status.text = "ปุ่มนี้มาจากอีกจอย กรุณาใช้จอยของผู้เล่นที่กำลังแก้"
				return
			Profile.remap(mappings[editing],listening,captured)
			listening = ""
			_refresh_bindings()
			_validate()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_Y]:
			for selector: OptionButton in selectors.values():
				selector.get_popup().hide()
			player_selector.get_popup().hide()
			if event.button_index == JOY_BUTTON_Y:
				editing = "p2_" if editing == "p1_" else "p1_"
				player_selector.select(1 if editing == "p2_" else 0)
				_refresh_bindings()
			else:
				tabs.current_tab = 1-tabs.current_tab
			if tabs.current_tab == 0:
				selectors[editing].grab_focus()
			else:
				binding_buttons.move_left.grab_focus()
			get_viewport().set_input_as_handled()
			return
		if event.button_index in [JOY_BUTTON_B,JOY_BUTTON_BACK,JOY_BUTTON_RIGHT_STICK]:
			manager.close_settings()
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_START:
			apply()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not manager.settings_open:
		return
	var neutral: bool = true
	for device: int in manager.devices:
		for axis: int in range(JOY_AXIS_MAX):
			if absf(Input.get_joy_axis(device,axis)) > 0.28:
				neutral = false
	if neutral:
		axis_armed = true
	for prefix: String in ["p1_","p2_"]:
		var device: int = int(choices[prefix].get("device",manager.assignments.get(prefix,-1)))
		live[prefix].text = "ไม่มีจอยที่เลือกเชื่อมต่ออยู่"
		if device in manager.devices:
			var pressed := PackedStringArray()
			for code: int in range(JOY_BUTTON_MAX):
				if Input.is_joy_button_pressed(device,code):
					pressed.append(Profile.binding_label(Profile.button(code)))
			live[prefix].text = "ทดสอบ: "+(" • ".join(pressed) if not pressed.is_empty() else "พร้อม")+"   Stick %.2f   LT %.2f   RT %.2f" % [Input.get_joy_axis(device,JOY_AXIS_LEFT_X),Input.get_joy_axis(device,JOY_AXIS_TRIGGER_LEFT),Input.get_joy_axis(device,JOY_AXIS_TRIGGER_RIGHT)]
