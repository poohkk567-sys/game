extends RefCounted
## Named actions also work with remapped keys and automated input tests.

static func install() -> void:
	var bindings: Dictionary = {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT], "jump": [KEY_SPACE], "crouch": [KEY_S, KEY_DOWN],
		"guard": [KEY_L], "punch": [KEY_J], "kick": [KEY_K],
		"special": [KEY_U], "ultimate": [KEY_I], "test_hit": [KEY_H],
		"test_fall": [KEY_N], "reset": [KEY_R], "help": [KEY_F1],
		"showcase": [KEY_F2], "hitboxes": [KEY_F3], "sprite_trial": [KEY_F4], "pause": [KEY_ESCAPE],
		"switch_fighter": [KEY_TAB]
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
