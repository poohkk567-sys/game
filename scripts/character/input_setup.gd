extends RefCounted
## Named actions also work with remapped keys and automated input tests.

static func install() -> void:
	var bindings: Dictionary = {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"charge": [KEY_Q], "run": [KEY_SHIFT], "jump": [KEY_SPACE], "crouch": [KEY_S, KEY_DOWN],
		"guard": [KEY_L], "punch": [KEY_J], "kick": [KEY_K],
		"special": [KEY_U], "ultimate": [KEY_I], "red_ultimate": [KEY_O], "test_hit": [KEY_H],
		"test_fall": [KEY_N], "reset": [KEY_R], "help": [KEY_F1],
		"showcase": [KEY_F2], "hitboxes": [KEY_F3], "sprite_trial": [KEY_F4], "pause": [KEY_ESCAPE],
		"switch_fighter": [KEY_TAB]
	}
	var players: Dictionary = {
	 "p1_move_left":[KEY_A], "p1_move_right":[KEY_D], "p1_jump":[KEY_SPACE,KEY_W],
	 "p1_charge":[KEY_Q], "p2_charge":[KEY_P], "p2_special":[KEY_KP_4,KEY_APOSTROPHE], "p1_red_ultimate":[KEY_O],
	 "p1_crouch":[KEY_S], "p1_run":[KEY_SHIFT], "p1_guard":[KEY_L],
	 "p1_punch":[KEY_J], "p1_kick":[KEY_K], "p1_special":[KEY_U], "p1_ultimate":[KEY_I],
	 "p2_move_left":[KEY_LEFT], "p2_move_right":[KEY_RIGHT], "p2_jump":[KEY_UP],
	 "p2_crouch":[KEY_DOWN], "p2_run":[KEY_CTRL], "p2_guard":[KEY_KP_3,KEY_SLASH],
	 "p2_punch":[KEY_KP_1,KEY_COMMA], "p2_kick":[KEY_KP_2,KEY_PERIOD],
	 "p2_ultimate":[KEY_KP_5,KEY_SEMICOLON]
	}
	bindings.merge(players)

	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
