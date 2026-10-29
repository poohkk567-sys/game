extends RefCounted
## Portable player preferences; runtime device IDs are deliberately not saved.
const COMMANDS: Array[String] = ["move_left","move_right","jump","crouch","run","guard","punch","kick","charge","special","pad_ultimate","dash","pad_pause","pad_help"]
const NAMES: Dictionary = {
 "move_left":"เดินซ้าย / A", "move_right":"เดินขวา / D", "jump":"กระโดด / Space",
 "crouch":"หมอบ / S", "run":"วิ่ง / Shift", "guard":"ป้องกัน / L",
 "punch":"ต่อย / J", "kick":"เตะ / K", "charge":"ชาร์จ / Q",
 "special":"สกิล / U (Assjiro: I)", "pad_ultimate":"อัลติ / I (Assjiro: O)",
 "dash":"แดช / E", "cheer":"สกิล 3 / T", "skill_four":"สกิล 4 / Y", "skill_five":"สกิล 5 / F", "pad_pause":"พักเกม / Esc", "pad_help":"รายการปุ่ม / F1"
}
var path: String = "user://controllers.cfg"
var preferences: Dictionary = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
var bindings: Dictionary = {}

static func button(code: int) -> Dictionary:
	return {"type":"button","code":code}

static func axis(code: int, sign_value: int) -> Dictionary:
	return {"type":"axis","code":code,"sign":sign_value}

static func defaults() -> Dictionary:
	return {
		 "move_left":[button(JOY_BUTTON_DPAD_LEFT),axis(JOY_AXIS_LEFT_X,-1)],
	 "move_right":[button(JOY_BUTTON_DPAD_RIGHT),axis(JOY_AXIS_LEFT_X,1)],
	 "jump":[button(JOY_BUTTON_A)],
	 "crouch":[button(JOY_BUTTON_DPAD_DOWN),axis(JOY_AXIS_LEFT_Y,1)],
	 "run":[button(JOY_BUTTON_RIGHT_SHOULDER)], "guard":[button(JOY_BUTTON_LEFT_SHOULDER)],
	 "punch":[button(JOY_BUTTON_X)], "kick":[button(JOY_BUTTON_B)],
	 "charge":[axis(JOY_AXIS_TRIGGER_LEFT,1)], "special":[axis(JOY_AXIS_TRIGGER_RIGHT,1)],
	 "pad_ultimate":[button(JOY_BUTTON_Y)], "dash":[button(JOY_BUTTON_LEFT_STICK)],
	 "pad_pause":[button(JOY_BUTTON_START)], "pad_help":[button(JOY_BUTTON_BACK)]
	}

func _init() -> void:
	bindings = {"p1_":defaults(),"p2_":defaults()}

static func valid_binding(value: Variant) -> bool:
	if not value is Dictionary or not value.get("code") is int:
		return false
	if value.get("type") == "button":
		return value.code >= 0 and value.code < JOY_BUTTON_MAX and value.code != JOY_BUTTON_RIGHT_STICK
	return value.get("type") == "axis" and value.code >= 0 and value.code < JOY_AXIS_MAX and value.get("sign") in [-1,1]

static func binding_key(value: Dictionary) -> String:
	return "%s:%d:%d" % [value.get("type",""),value.get("code",-1),value.get("sign",0)]

static func validate_map(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var seen: Dictionary = {}
	for command: String in COMMANDS:
		if not value.get(command) is Array or value[command].is_empty():
			return false
		for entry: Variant in value[command]:
			if not valid_binding(entry) or seen.has(binding_key(entry)):
				return false
			seen[binding_key(entry)] = true
	return true

static func valid_choice(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if value.get("mode") in ["auto","keyboard"]:
		return true
	return value.get("mode") == "pad" and value.get("guid") is String and value.get("name") is String and value.get("instance") is int and value.instance >= 0

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for prefix: String in ["p1_","p2_"]:
		var choice: Variant = config.get_value(prefix,"device",{})
		if valid_choice(choice):
			preferences[prefix] = choice.duplicate(true)
		var mapping: Variant = config.get_value(prefix,"bindings",{})
		if mapping is Dictionary:
			mapping = upgrade_map(mapping)
		if validate_map(mapping):
			bindings[prefix] = mapping.duplicate(true)
	# A malformed file cannot assign the same saved pad to two players.
	if preferences.p1_.get("mode") == "pad" and preferences.p1_ == preferences.p2_:
		preferences.p2_ = {"mode":"auto"}

static func upgrade_map(mapping: Dictionary) -> Dictionary:
	# Chords inherit the saved normal buttons; obsolete direct skill buttons retire.
	var result: Dictionary = mapping.duplicate(true)
	for command: String in ["cheer","skill_four","skill_five"]: result.erase(command)
	return result

func save_settings(choices: Dictionary, mappings: Dictionary) -> Error:
	var config := ConfigFile.new()
	for prefix: String in ["p1_","p2_"]:
		if not valid_choice(choices.get(prefix)) or not validate_map(mappings.get(prefix)):
			return ERR_INVALID_DATA
		var choice: Dictionary = choices[prefix].duplicate(true)
		choice.erase("device")
		config.set_value(prefix,"device",choice)
		config.set_value(prefix,"bindings",mappings[prefix])
	var error: Error = config.save(path)
	if error == OK:
		for prefix: String in ["p1_","p2_"]:
			preferences[prefix] = config.get_value(prefix,"device")
			bindings[prefix] = mappings[prefix].duplicate(true)
	return error

static func remap(mapping: Dictionary, command: String, entry: Dictionary) -> void:
	var previous: Array = mapping[command].duplicate(true)
	var key: String = binding_key(entry)
	if previous.any(func(item: Dictionary) -> bool: return binding_key(item) == key):
		return
	for other: String in COMMANDS:
		if other != command and mapping[other].any(func(item: Dictionary) -> bool: return binding_key(item) == key):
			mapping[other] = previous
			break
	mapping[command] = [entry.duplicate()]

static func binding_label(entry: Dictionary) -> String:
	if entry.type == "button":
		var names: Dictionary = {0:"A / Cross",1:"B / Circle",2:"X / Square",3:"Y / Triangle",4:"Back / Share",6:"Start / Options",7:"L3",9:"LB / L1",10:"RB / R1",11:"D-pad ↑",12:"D-pad ↓",13:"D-pad ←",14:"D-pad →"}
		return names.get(entry.code,"Button %d" % entry.code)
	var names: Dictionary = {0:"Stick X",1:"Stick Y",2:"Right X",3:"Right Y",4:"LT / L2",5:"RT / R2"}
	return str(names.get(entry.code,"Axis %d" % entry.code))+(" −" if entry.sign < 0 else " +")

static func mapping_label(entries: Array) -> String:
	var parts := PackedStringArray()
	for entry: Dictionary in entries:
		parts.append(binding_label(entry))
	return " / ".join(parts)
