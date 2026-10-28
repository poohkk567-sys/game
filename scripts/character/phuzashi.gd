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
# duration, energy, damage, active start/end (normalized), reach, height.
const ATTACKS: Dictionary = {
	"PUNCH": [0.42, 0.0, 8, 0.34, 0.60, 112.0, 64.0],
	"KICK": [0.58, 0.0, 14, 0.40, 0.65, 150.0, 78.0],
	"SPECIAL": [0.90, 25.0, 24, 0.42, 0.55, 0.0, 0.0],
	"ULTIMATE": [1.80, 60.0, 60, 0.48, 0.80, 620.0, 180.0]
}
const Pulse = preload("res://scripts/character/dark_pulse.gd")
const Effects = preload("res://scripts/character/combat_effects.gd")

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
var message: String = "Approach the crystal to practice attacks"
var message_time: float = 3.0
var effects: Node2D

func _ready() -> void:
	effects = Node2D.new()
	effects.set_script(Effects)
	effects.name = "CombatEffects"
	add_child(effects)
	move_child(effects, 0)

func _physics_process(delta: float) -> void:
	elapsed += delta
	message_time = maxf(0.0, message_time - delta)
	energy = minf(100.0, energy + delta * 9.0)
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
	var axis: float = Input.get_axis("move_left", "move_right")
	var crouching: bool = Input.is_action_pressed("crouch")
	var guarding: bool = Input.is_action_pressed("guard")
	if axis != 0.0 and action_timer <= 0.0:
		facing = 1 if axis > 0.0 else -1
	if action_timer <= 0.0 and not crouching and not guarding:
		for binding: String in ["ultimate", "special", "kick", "punch"]:
			if Input.is_action_just_pressed(binding):
				start_action(binding.to_upper())
				break
	if jump_buffer > 0.0 and coyote > 0.0 and action_timer <= 0.0 and not crouching and not guarding:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0

	var locked: bool = action_timer > 0.0 or (was_grounded and (crouching or guarding))
	var speed: float = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	var desired: float = 0.0 if locked else axis * (speed if was_grounded else AIR_SPEED)
	velocity.x = move_toward(velocity.x, desired, ACCELERATION * delta)
	if not was_grounded or velocity.y < 0.0:
		velocity.y += GRAVITY * delta
	move_and_slide()
	position.x = clampf(position.x, 75.0, 1205.0)
	if position.y > 800.0:
		reset_training()
		return

	if action_timer > 0.0:
		action_timer = maxf(0.0, action_timer - delta)
		if ATTACKS.has(action_name):
			_process_attack()
		if action_timer <= 0.0:
			action_name = ""
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

func start_action(action: String) -> bool:
	if not ATTACKS.has(action) or action_timer > 0.0 or not is_on_floor():
		return false
	if Input.is_action_pressed("guard") or Input.is_action_pressed("crouch"):
		return false
	var config: Array = ATTACKS[action]
	if energy < float(config[1]):
		announce("Not enough MP — wait for regeneration or press R")
		return false
	energy -= float(config[1])
	action_name = action
	action_duration = float(config[0])
	action_timer = action_duration
	struck.clear()
	pulse_spawned = false
	velocity.x = 0.0
	jump_buffer = 0.0
	_set_state(action)
	attack_started.emit(action)
	return true

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
	attack_shape.position = Vector2(facing * (float(config[5]) * 0.5 + 18.0), -82.0)
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

func receive_training_hit(knockdown: bool) -> void:
	if action_name == "FALL":
		return
	var blocked: bool = Input.is_action_pressed("guard") and is_on_floor() and action_timer <= 0.0
	health = maxf(0.0, health - (2.0 if blocked else (18.0 if knockdown else 8.0)))
	if blocked:
		announce("GUARD — impact absorbed (2 chip damage)")
		return
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
	_set_state("IDLE")
	rig.reset_pose()
	_update_body_shape()
	get_tree().call_group("dark_pulses", "queue_free")
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
