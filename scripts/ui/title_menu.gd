extends Control
const Rig = preload("res://scripts/character/phuzashi_rig.gd")
const PROFILES: Array[String] = ["PHUZASHI","RED_CAP","MUAY_THAI","BLACK_COAT","PHUZASHI_CHILL"]
var selectors: Array[OptionButton] = []
var rigs: Array[Node2D] = []
var solo_player: OptionButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	var theme := Theme.new()
	var font: Font = load("res://assets/fonts/NotoSansThai-Regular.ttf").duplicate()
	font.fallbacks = [ThemeDB.fallback_font]
	theme.default_font = font
	theme.default_font_size = 20
	self.theme = theme
	var background := TextureRect.new()
	background.texture = load("res://assets/stages/school_gate.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.025,0.05,0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label("PHUZASHI",Vector2(0,38),Vector2(1280,65),48,Color("eee4ff"))
	_label("D A R K   P U L S E",Vector2(0,106),Vector2(1280,35),23,Color("bd8af8"))
	_label("เลือกตัวละคร แล้วเข้าประลอง",Vector2(0,155),Vector2(1280,36),23,Color("ead2a1"))
	var selected: Array = get_tree().get_meta("fighter_choices",PROFILES)
	for player in range(2):
		var x: float = 238+player*420
		var card := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.04,0.06,0.10,0.92)
		style.border_color = Color("b58cea") if player == 0 else Color("e5bd76")
		style.set_border_width_all(2)
		card.add_theme_stylebox_override("panel",style)
		card.position = Vector2(x,220)
		card.size = Vector2(384,340)
		add_child(card)
		_label("ผู้เล่น %d / P%d" % [player+1,player+1],Vector2(x,236),Vector2(384,40),25,style.border_color)
		var rig := Node2D.new()
		rig.set_script(Rig)
		add_child(rig)
		rig.position = Vector2(x+192,480)
		rig.set_clear_enabled(true)
		rigs.append(rig)
		var select := OptionButton.new()
		select.position = Vector2(x+32,503)
		select.size = Vector2(320,43)
		select.add_item("PHUZASHI")
		select.add_item("ASSJIRO")
		select.add_item("MUAY THAI")
		select.add_item("BLACK COAT")
		select.add_item("PHUZASHI CHILL")
		select.select(PROFILES.find(selected[player]))
		add_child(select)
		selectors.append(select)
		select.item_selected.connect(func(_index: int) -> void: _refresh_character(player))
		_refresh_character(player)
	_button("เริ่มต่อสู้ 2 ผู้เล่น",Vector2(238,582),Vector2(256,49),start_versus)
	_button("สนามฝึกเดี่ยว",Vector2(507,582),Vector2(256,49),start_training)
	_button("ตั้งค่าจอย / F7",Vector2(776,582),Vector2(266,49),Gamepads.open_settings)
	_label("LB เปลี่ยน P1 • RB เปลี่ยน P2 • Start ต่อสู้ • X ฝึก P1 • R3 ตั้งค่า",Vector2(100,647),Vector2(1080,35),17,Color("d3cbde"))
	selectors[0].grab_focus()

func _refresh_character(player: int) -> void:
	rigs[player].set_character_profile(PROFILES[selectors[player].selected])

func _label(line: String, point: Vector2, dimensions: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = line
	label.position = point
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	add_child(label)

func _button(line: String, point: Vector2, dimensions: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = line
	button.position = point
	button.size = dimensions
	button.pressed.connect(callback)
	add_child(button)

func start_versus() -> void:
	if Gamepads.settings_open:
		return
	get_tree().set_meta("fighter_choices",[PROFILES[selectors[0].selected],PROFILES[selectors[1].selected]])
	get_tree().paused = false
	Gamepads.suspend_until_neutral()
	get_tree().change_scene_to_file("res://scenes/versus_school.tscn")

func start_training() -> void:
	if Gamepads.settings_open:
		return
	get_tree().set_meta("solo_fighter",PROFILES[selectors[0].selected])
	get_tree().set_meta("clear_training",true)
	get_tree().paused = false
	Gamepads.suspend_until_neutral()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event: InputEvent) -> void:
	if Gamepads.settings_open or not (event is InputEventJoypadButton and event.pressed):
		return
	if event.button_index == JOY_BUTTON_START:
		start_versus()
	elif event.button_index == JOY_BUTTON_X:
		start_training()
	elif event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
		var player: int = 0 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1
		selectors[player].select((selectors[player].selected+1)%PROFILES.size())
		_refresh_character(player)
	else:
		return
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	for rig: Node2D in rigs:
		rig.animate("IDLE",delta,1)
