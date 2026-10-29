extends RefCounted
## All successful attacks share physical recoil, hit shake, hit pause and audio.
const Feedback = preload("res://scripts/combat/skill_feedback.gd")

static func direction(victim: Node2D, attacker: Node2D) -> int:
	if is_instance_valid(attacker) and absf(victim.global_position.x-attacker.global_position.x) > 1:
		return 1 if victim.global_position.x > attacker.global_position.x else -1
	return -int(victim.facing)

static func profile(move: String, damage: int, blocked: bool = false) -> Dictionary:
	var force: float = 135
	var duration: float = 0.075
	var shake: float = 2.0
	var pause: float = 0.022
	var camera: float = 0.8
	var sound: String = "LIGHT"
	if move.begins_with("KICK") or move == "AIR_KICK":
		force = 180
		duration = 0.10
		shake = 3
		camera = 1.4
		sound = "KICK"
	if move in ["PUNCH_3","KICK_3"]:
		force = 240 if move == "PUNCH_3" else 290
		duration = 0.13
		shake = 4
		pause = 0.04
		camera = 2.5
		sound = "HEAVY"
	if move in ["SPECIAL","CARROT_HEADBUTT","CARROT_UPROOT","SOY_BOMB","CARROT_SPIN","DARK_RIFT","SHADOW_REPRISAL","GORILLA_ELBOW","GORILLA_KNEE","GORILLA_QUAKE","GORILLA_ROAR"]:
		force = 190+damage*2
		duration = 0.14
		shake = 4.5
		pause = 0.055
		camera = 3.5
		sound = "HEAVY"
	if move == "GORILLA_ROAR":
		force = 420
		duration = 0.18
	if move in ["ULTIMATE","GORILLA_KING_FINISH"]:
		force = 600 if move == "ULTIMATE" else 420
		duration = 0.21
		shake = 6
		pause = 0.085
		camera = 5.5
		sound = "HEAVY"
	if move in ["CARROT_RUSH","GORILLA_KING"]:
		force = 30 if move == "CARROT_RUSH" else 0
		duration = 0.055
		pause = 0.015
		shake = 2
		camera = 0.7
	if move == "CARROT_RUSH_FINISH":
		force = 240
		duration = 0.13
		shake = 4
		camera = 2.5
	if blocked:
		force = 85
		duration = 0.065
		shake = 1.5
		pause = 0.012
		camera = 0.6
	return {"force":force,"duration":duration,"shake":shake,"pause":pause,"camera":camera,"sound":sound}

static func hit(victim: Node2D, attacker: Node2D, damage: int, move: String, blocked: bool) -> void:
	var data: Dictionary = profile(move,damage,blocked)
	victim.hit_shake = 0.20
	victim.hit_shake_power = data.shake
	victim.impact_pause = maxf(victim.impact_pause,data.pause)
	victim.skills.push_velocity = direction(victim,attacker)*data.force
	victim.skills.push_remaining = data.duration
	victim.velocity.x = victim.skills.push_velocity
	if is_instance_valid(attacker) and attacker.has_method("bind_lock_duration"):
		attacker.impact_pause = maxf(attacker.impact_pause,data.pause)
	Feedback.obtain(victim.get_parent()).impact(data.camera,"GUARD" if blocked else data.sound)
	var pads: Node = victim.get_tree().root.get_node_or_null("Gamepads")
	if pads != null and pads.assignments.has(victim.input_prefix):
		var device: int = pads.assignments[victim.input_prefix]
		if device in Input.get_connected_joypads():
			Input.start_joy_vibration(device,minf(0.6,0.1+data.camera*0.08),minf(0.7,data.camera*0.12),0.04 if blocked else 0.10)

static func practice(attacker: Node2D, damage: int, move: String) -> void:
	if not is_instance_valid(attacker) or not attacker.has_method("bind_lock_duration"): return
	var data: Dictionary = profile(move,damage)
	attacker.impact_pause = maxf(attacker.impact_pause,data.pause)
	Feedback.obtain(attacker.get_parent()).impact(data.camera,data.sound)
