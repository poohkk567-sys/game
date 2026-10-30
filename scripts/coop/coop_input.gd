extends RefCounted
## These keys exist only as separate actions; 2D W/Up jump bindings stay intact.
static func install() -> void:
	var bindings := {
		"p1_coop_forward":[KEY_W], "p1_coop_back":[KEY_S], "p1_coop_jump":[KEY_SPACE], "p1_coop_revive":[KEY_Q],
		"p2_coop_forward":[KEY_UP], "p2_coop_back":[KEY_DOWN], "p2_coop_jump":[KEY_ENTER,KEY_KP_ENTER], "p2_coop_revive":[KEY_P]
	}
	for action: String in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action,0.28)
		for code: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
