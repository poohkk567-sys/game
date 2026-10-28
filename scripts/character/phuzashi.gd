extends CharacterBody2D
class_name PhuzashiCharacter

signal attack_started(action: String)
signal state_changed(state: String)
signal target_struck(damage: int)

const WALK_SPEED: float = 190.0
const RUN_SPEED: float = 340.0
const AIR_SPEED: float = 220.0
const JUMP_VELOCITY: float = -565.0
const GRAVITY: float = 1500.0
const ACCELERATION: float = 2300.0
const FLOOR_Y: float = 586.0
const SPAWN := Vector2(360, FLOOR_Y)
const BLINK_DURATION: float = 0.4
const BLINK_DISTANCE: float = 130.0
const BLINK_COST: float = 15.0
const BLINK_WINDOW: float = 0.28
const BLINK_COOLDOWN: float = 0.5
const COMBO_LINK_PHASE: float = 0.72
const COMBO_GRACE: float = 0.22
# duration, energy, damage, active start/end (normalized), reach, height.
const ATTACKS: Dictionary = {
	"PUNCH": [0.42, 0.0, 8, 0.34, 0.60, 112.0, 64.0],
	"KICK": [0.58, 0.0, 14, 0.40, 0.65, 150.0, 78.0],
	"PUNCH_2": [0.36, 0.0, 10, 0.32, 0.57, 118.0, 70.0],
	"PUNCH_3": [0.50, 0.0, 16, 0.30, 0.62, 138.0, 140.0],
	"KICK_2": [0.50, 0.0, 16, 0.36, 0.62, 158.0, 86.0],
	"KICK_3": [0.64, 0.0, 22, 0.34, 0.65, 174.0, 92.0],
	"AIR_PUNCH": [0.32, 0.0, 9, 0.24, 0.60, 104.0, 76.0],
	"AIR_KICK": [0.42, 0.0, 15, 0.30, 0.66, 146.0, 88.0],
	"SPECIAL": [0.90, 25.0, 24, 0.42, 0.55, 0.0, 0.0],
	"ULTIMATE": [1.80, 60.0, 60, 0.48, 0.80, 620.0, 180.0]
}
const Pulse = preload("res://scripts/character/dark_pulse.gd")
const Effects = preload("res://scripts/character/combat_effects.gd")
const ShadowBlinkVFX = preload("res://scripts/effects/shadow_blink_vfx.gd")
const PurpleFist = preload("res://scripts/effects/purple_fist.gd")
const PurpleImpact = preload("res://scripts/effects/purple_punch_impact.gd")

@onready var rig: Node2D = $Rig
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
var health: float = 100.0
var energy: float = 100.0
var facing: int = 1
var state_name: String = "IDLE"
var action_name: String = ""
var action_timer: float = 0.0
var action_duration: float = 1.0
var elapsed: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var debug_hitboxes: bool = false
var visited: Dictionary = {"IDLE": true}
var struck: Dictionary = {}
var pulse_spawned: bool = false
var blink_timer: float = 0.0
var blink_cooldown: float = 0.0
var blink_origin: float = 0.0
var blink_direction: int = 1
var left_tap: float = -100.0
var right_tap: float = -100.0
var combo_family: String = ""
var combo_step: int = 0
var combo_buffer: int = 0
var combo_grace: float = 0.0
var message: String = "Approach the crystal to practice attacks"
var message_time: float = 3.0
var effects: Node2D
var purple_fist: Node2D

func _ready() -> void:
	effects = Node2D.new()
	effects.set_script(Effects)
	effects.name = "CombatEffects"
	add_child(effects)
	move_child(effects, 0)
	purple_fist = PurpleFist.new()
	purple_fist.name = "PurpleFist"
	add_child(purple_fist)

func _physics_process(delta: float) -> void:
	elapsed += delta
	message_time = maxf(0.0, message_time - delta)
	energy = minf(100.0, energy + delta * 9.0)
	blink_cooldown = maxf(0.0, blink_cooldown - delta)
	if action_timer <= 0.0 and combo_grace > 0.0:
		combo_grace = maxf(0.0, combo_grace - delta)
		if combo_grace <= 0.0:
			_clear_combo()
	if Input.is_action_just_pressed("reset"):
		reset_training()
		get_tree().call_group("training_target", "reset_target")
		return
	if Input.is_action_just_pressed("test_hit"):
		receive_training_hit(false)
	elif Input.is_action_just_pressed("test_fall"):
		receive_training_hit(true)

	var was_grounded: bool = is_on_floor()
	coyote = 0.10 if was_grounded else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	for command: String in ["move_left", "move_right"]:
		if Input.is_action_just_pressed(command):
			var direction: int = -1 if command == "move_left" else 1
			var previous: float = left_tap if direction < 0 else right_tap
			if elapsed - previous < BLINK_WINDOW:
				_start_blink(direction)
			if direction < 0:
				left_tap = elapsed
			else:
				right_tap = elapsed
	if blink_timer > 0.0:
		_step_blink(delta)
		return
	var axis: float = Input.get_axis("move_left", "move_right")
	var crouching: bool = Input.is_action_pressed("crouch")
	var guarding: bool = Input.is_action_pressed("guard")
	if axis != 0.0 and action_timer <= 0.0:
		facing = 1 if axis > 0.0 else -1
	# Resolve jump first, so Space+J/K on the same frame is an aerial attack.
	if jump_buffer > 0.0 and coyote > 0.0 and action_timer <= 0.0 and not crouching and not guarding:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0
		_clear_combo()
	if not crouching and not guarding:
		for binding: String in ["ultimate", "special", "kick", "punch"]:
			if Input.is_action_just_pressed(binding):
				start_action(binding.to_upper())
				break
	if action_timer <= 0.0 and (crouching or guarding):
		_clear_combo()
	var airborne: bool = not was_grounded or velocity.y < 0.0
	var locked: bool = (action_timer > 0.0 and not is_air_attack()) or (not airborne and (crouching or guarding))
	var speed: float = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	var desired: float = 0.0 if locked else axis * (AIR_SPEED if airborne else speed)
	if not airborne and action_name in ["PUNCH_2", "PUNCH_3", "KICK_2", "KICK_3"] and action_progress() >= 0.15 and action_progress() < 0.45:
		desired = facing * (80.0 if combo_step == 3 else 45.0)
	velocity.x = move_toward(velocity.x, desired, ACCELERATION * delta)
	if not was_grounded or velocity.y < 0.0:
		velocity.y += GRAVITY * delta
	move_and_slide()
	position.x = clampf(position.x, 75.0, 1205.0)
	if position.y > 800.0:
		reset_training()
		return
	if is_air_attack() and is_on_floor():
		# Landing immediately releases the aerial pose/hitbox and buffered inputs.
		action_timer = 0.0
		action_name = ""
		_clear_combo()

	if action_timer > 0.0:
		action_timer = maxf(0.0, action_timer - delta)
		if ATTACKS.has(action_name):
			_process_attack()
		if combo_buffer > 0 and _is_combo_action() and action_progress() >= COMBO_LINK_PHASE:
			combo_buffer -= 1
			combo_step += 1
			_begin_attack(_combo_clip())
		elif action_timer <= 0.0:
			action_name = ""
			if combo_step > 0 and combo_step < 3:
				combo_grace = COMBO_GRACE
			else:
				_clear_combo()
	var next: String = "IDLE"
	if action_timer > 0.0:
		next = action_name
	elif not is_on_floor():
		next = "JUMP"
	elif crouching:
		next = "CROUCH"
	elif guarding:
		next = "GUARD"
	elif absf(velocity.x) > 15.0:
		next = "RUN" if Input.is_action_pressed("run") else "WALK"
	_set_state(next)
	_update_body_shape()
	var phase: float = -1.0
	if action_timer > 0.0:
		phase = action_progress()
	elif state_name == "JUMP":
		phase = clampf((velocity.y - JUMP_VELOCITY) / (-2.0 * JUMP_VELOCITY), 0.0, 1.0)
	rig.animate(state_name, delta, facing, phase)
	queue_redraw()
	effects.queue_redraw()

func _start_blink(direction: int) -> bool:
	if blink_timer > 0.0 or blink_cooldown > 0.0 or action_timer > 0.0:
		return false
	if not is_on_floor() or Input.is_action_pressed("crouch") or Input.is_action_pressed("guard"):
		return false
	if energy < BLINK_COST:
		announce("Shadow Blink requires 15 MP")
		return false
	energy -= BLINK_COST
	_clear_combo()
	blink_timer = BLINK_DURATION
	blink_cooldown = BLINK_COOLDOWN
	blink_origin = position.x
	blink_direction = direction
	facing = direction
	velocity = Vector2.ZERO
	jump_buffer = 0.0
	_set_state("BLINK")
	announce("SHADOW BLINK / 15 MP")
	var blink_effect: Node2D = ShadowBlinkVFX.new()
	blink_effect.configure(self)
	get_parent().add_child(blink_effect)
	# Behind the intact fighter, above the stage art; never follows the actor.
	get_parent().move_child(blink_effect, get_index())
	return true

func blink_progress() -> float:
	return clampf(1.0 - blink_timer / BLINK_DURATION, 0.0, 1.0)

func blink_invulnerable() -> bool:
	return blink_timer > 0.0 and blink_progress() >= 4.0/12.0 and blink_progress() < 8.0/12.0

func _step_blink(delta: float) -> void:
	blink_timer = maxf(0.0, blink_timer - delta)
	var progress: float = blink_progress()
	var fraction: float = clampf((progress - 0.24) / 0.49, 0.0, 1.0)
	fraction = fraction * fraction * (3.0 - 2.0 * fraction)
	velocity = Vector2(0.0, GRAVITY * delta)
	move_and_slide()
	position.x = clampf(blink_origin + float(blink_direction) * BLINK_DISTANCE * fraction, 75.0, 1205.0)
	_set_state("BLINK")
	rig.animate("BLINK", delta, facing, progress)
	queue_redraw()
	effects.queue_redraw()
	if blink_timer <= 0.0:
		_set_state("IDLE")

func start_action(action: String) -> bool:
	if blink_timer > 0.0:
		return false
	if Input.is_action_pressed("guard") or Input.is_action_pressed("crouch"):
		return false
	if action in ["PUNCH", "KICK"]:
		return _request_normal_attack(action)
	if action not in ["SPECIAL", "ULTIMATE"] or action_timer > 0.0 or not is_on_floor() or velocity.y < 0.0:
		return false
	var config: Array = ATTACKS[action]
	if energy < float(config[1]):
		announce("Not enough MP — wait for regeneration or press R")
		return false
	energy -= float(config[1])
	_clear_combo()
	_begin_attack(action)
	return true

func _request_normal_attack(family: String) -> bool:
	if action_timer > 0.0:
		# Store up to the remaining two taps; holding a button never adds inputs.
		if _is_combo_action() and combo_family == family and combo_step + combo_buffer < 3:
			combo_buffer += 1
			return true
		return false
	if not is_on_floor() or velocity.y < 0.0:
		_clear_combo()
		_begin_attack("AIR_" + family)
		return true
	if combo_family != family or combo_grace <= 0.0 or combo_step >= 3:
		_clear_combo()
		combo_family = family
		combo_step = 1
	else:
		combo_step += 1
	combo_grace = 0.0
	_begin_attack(_combo_clip())
	return true

func _begin_attack(action: String) -> void:
	var config: Array = ATTACKS[action]
	action_name = action
	action_duration = float(config[0])
	action_timer = action_duration
	struck.clear()
	pulse_spawned = false
	if not is_air_attack():
		velocity.x = 0.0
	jump_buffer = 0.0
	_set_state(action)
	attack_started.emit(action)
	if combo_step > 0:
		announce("%s COMBO / %d OF 3" % [combo_family, combo_step])
	elif is_air_attack():
		announce("JUMP " + action.trim_prefix("AIR_"))

func _combo_clip() -> String:
	return combo_family if combo_step <= 1 else "%s_%d" % [combo_family, combo_step]

func _is_combo_action() -> bool:
	return combo_step > 0 and not combo_family.is_empty() and action_name == _combo_clip()

func is_air_attack() -> bool:
	return action_timer > 0.0 and action_name in ["AIR_PUNCH", "AIR_KICK"]

func _clear_combo() -> void:
	combo_family = ""
	combo_step = 0
	combo_buffer = 0
	combo_grace = 0.0

func action_progress() -> float:
	return 1.0 - action_timer / maxf(action_duration, 0.001)

func attack_phase() -> String:
	if not ATTACKS.has(action_name) or action_timer <= 0.0:
		return "READY"
	var config: Array = ATTACKS[action_name]
	var phase: float = action_progress()
	return "STARTUP" if phase < float(config[3]) else ("ACTIVE" if phase <= float(config[4]) else "RECOVERY")

func _process_attack() -> void:
	var config: Array = ATTACKS[action_name]
	var phase: float = action_progress()
	if phase < float(config[3]) or phase > float(config[4]):
		return
	if action_name == "SPECIAL":
		if not pulse_spawned:
			pulse_spawned = true
			var pulse := Area2D.new()
			pulse.set_script(Pulse)
			pulse.direction = facing
			pulse.source = self
			pulse.position = global_position + Vector2(facing * 85.0, -84.0)
			get_parent().add_child(pulse)
		return
	attack_shape.shape.size = Vector2(float(config[5]), float(config[6]))
	var strike_y: float = -116.0 if action_name == "PUNCH_3" else (-64.0 if action_name == "AIR_KICK" else (-78.0 if action_name == "AIR_PUNCH" else -82.0))
	attack_shape.position = Vector2(facing * (float(config[5]) * 0.5 + 18.0), strike_y)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = attack_shape.shape
	query.transform = attack_shape.global_transform
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var target: Object = result.collider
		if target.has_method("take_hit") and not struck.has(target.get_instance_id()):
			struck[target.get_instance_id()] = true
			target.take_hit(int(config[2]), action_name)
			target_struck.emit(int(config[2]))
			if action_name == "PUNCH_3":
				var impact: Node2D = PurpleImpact.new()
				impact.position = target.global_position + Vector2(-facing*12,-30)
				impact.direction = facing
				get_parent().add_child(impact)

func receive_training_hit(knockdown: bool) -> void:
	if blink_invulnerable():
		announce("SHADOW BLINK / attack avoided")
		return
	if action_name == "FALL":
		return
	var blocked: bool = Input.is_action_pressed("guard") and is_on_floor() and action_timer <= 0.0
	health = maxf(0.0, health - (2.0 if blocked else (18.0 if knockdown else 8.0)))
	if blocked:
		announce("GUARD — impact absorbed (2 chip damage)")
		return
	_clear_combo()
	if is_instance_valid(purple_fist):
		purple_fist.clear()
	action_name = "FALL" if knockdown else "HIT"
	action_duration = 1.4 if knockdown else 0.48
	action_timer = action_duration
	struck.clear()
	jump_buffer = 0.0
	velocity.x = -facing * (140.0 if knockdown else 70.0)
	_set_state(action_name)
	announce("KNOCKDOWN / automatic recovery" if knockdown else "HIT / recovery")

func _update_body_shape() -> void:
	var low: bool = state_name == "CROUCH" or state_name == "FALL"
	body_shape.shape.size = Vector2(50.0, 84.0 if low else 144.0)
	body_shape.position.y = -42.0 if low else -72.0

func _set_state(next: String) -> void:
	if state_name != next:
		state_name = next
		visited[next] = true
		state_changed.emit(next)

func announce(text: String) -> void:
	message = text
	message_time = 3.0

func reset_training() -> void:
	global_position = SPAWN
	velocity = Vector2.ZERO
	health = 100.0
	energy = 100.0
	facing = 1
	action_name = ""
	action_timer = 0.0
	action_duration = 1.0
	coyote = 0.0
	jump_buffer = 0.0
	struck.clear()
	pulse_spawned = false
	blink_timer = 0.0
	blink_cooldown = 0.0
	left_tap = -100.0
	right_tap = -100.0
	_clear_combo()
	_set_state("IDLE")
	rig.reset_pose()
	_update_body_shape()
	get_tree().call_group("dark_pulses", "queue_free")
	get_tree().call_group("shadow_blink_effects", "queue_free")
	get_tree().call_group("purple_punch_impacts", "queue_free")
	if is_instance_valid(purple_fist):
		purple_fist.clear()
	announce("Training reset")

func _draw() -> void:
	var altitude: float = maxf(0.0, FLOOR_Y - position.y)
	draw_set_transform(Vector2(0, altitude + 2), 0, Vector2(1.0, 0.19))
	draw_circle(Vector2.ZERO, maxf(18.0, 44.0 - altitude * 0.08), Color(0.015, 0.03, 0.07, 0.32))
	draw_set_transform(Vector2.ZERO)
	if debug_hitboxes:
		draw_rect(Rect2(body_shape.position - body_shape.shape.size * 0.5, body_shape.shape.size), Color(0.2, 1, 0.8, 0.3), false, 2.0)
		if attack_phase() == "ACTIVE" and action_name != "SPECIAL":
			draw_rect(Rect2(attack_shape.position - attack_shape.shape.size * 0.5, attack_shape.shape.size), Color(1, 0.3, 0.4, 0.6), false, 2.0)
