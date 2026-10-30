extends CharacterBody2D
class_name PhuzashiCharacter

signal attack_started(action: String)
signal state_changed(state: String)
signal target_struck(damage: int)

const CHARGE_RATE: float = 7.0
const STARTING_MANA: float = 50.0
const SkillBook = preload("res://scripts/combat/skill_book.gd")
const SkillController = preload("res://scripts/combat/skill_controller.gd")
const Reaction = preload("res://scripts/combat/combat_reaction.gd")
const UltimateCutin = preload("res://scripts/ui/ultimate_cutin.gd")
const PERFECT_GUARD_WINDOW: float = 0.12
const GUARD_REGEN_RATE: float = 20.0
const GUARD_REGEN_DELAY: float = 1.0
const GUARD_BREAK_DURATION: float = 1.0
const GUARD_COSTS: Dictionary = {
 "PUNCH":10.0, "PUNCH_2":10.0, "AIR_PUNCH":10.0, "PUNCH_3":20.0,
 "KICK":14.0, "KICK_2":14.0, "AIR_KICK":14.0, "KICK_3":24.0,
 "SPECIAL":20.0, "ULTIMATE":40.0, "CARROT_HEADBUTT":20.0, "CARROT_RUSH":4.0, "CARROT_RUSH_FINISH":12.0
}
const RED_TRANSFORM_COST: float = 70.0
const RED_TRANSFORM_DURATION: float = 3.2
const DASH_DURATION: float = 0.22
const DASH_SPEED: float = 440.0
const DASH_COOLDOWN: float = 0.45
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
const BLINK_COST: float = 5.0
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
	"CHEER": [0.60, 30.0, 0, 0.35, 0.48, 0.0, 0.0],
	"CARROT_HEADBUTT": [0.85, 25.0, 22, 0.20, 0.67, 128.0, 112.0],
	"CARROT_RUSH": [1.28, 30.0, 4, 0.20, 0.80, 155.0, 130.0],
	"DEMON_BIND": [0.62, 25.0, 0, 0.32, 0.48, 620.0, 180.0],
	"SPECIAL": [0.90, 25.0, 24, 0.42, 0.55, 0.0, 0.0],
	"ULTIMATE": [1.80, 60.0, 60, 0.32, 0.80, 128.0, 130.0]
}
const MUAY_ATTACKS: Dictionary = {
 "PUNCH":[0.42,0.0,8,0.34,0.60,128.0,72.0],
 "PUNCH_2":[0.40,0.0,10,0.32,0.57,132.0,78.0],
 "PUNCH_3":[0.52,0.0,18,0.30,0.62,112.0,100.0],
 "KICK":[0.58,0.0,14,0.40,0.65,160.0,86.0],
 "KICK_2":[0.50,0.0,16,0.36,0.62,118.0,104.0],
 "KICK_3":[0.66,0.0,22,0.34,0.65,174.0,150.0]
}
const Pulse = preload("res://scripts/character/dark_pulse.gd")
const Effects = preload("res://scripts/character/combat_effects.gd")
const ShadowBlinkVFX = preload("res://scripts/effects/shadow_blink_vfx.gd")
const PurpleFist = preload("res://scripts/effects/purple_fist.gd")
const PurpleImpact = preload("res://scripts/effects/purple_punch_impact.gd")
const MovementLock = preload("res://scripts/combat/movement_lock.gd")
const CheerAssist = preload("res://scripts/effects/cheer_assist.gd")
const DemonBind = preload("res://scripts/effects/demon_bind.gd")
const ShadowReturn = preload("res://scripts/combat/shadow_return.gd")

@onready var rig: Node2D = $Rig
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
var max_health: float = 100.0
var health: float = 100.0
var energy: float = STARTING_MANA
var pact: Node2D
var status_aura: Node2D
var skills: Node2D
var impact_pause: float = 0
var hit_shake: float = 0
var hit_shake_power: float = 0
var reaction_clock: float = 0
var launched_once: bool = false
var skill_input_modifier: bool = false
var guard_meter: float = 100.0
var guard_break_remaining: float = 0.0
var guard_recovery_delay: float = 0.0
var guard_press_age: float = 999.0
var guard_was_held: bool = false
var perfect_guard_used: bool = false
var charging: bool = false
var last_hit_blocked: bool = false
var defense_feedback: String = ""
var defense_feedback_time: float = 0.0
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
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_direction: int = 1
var guard_impact: float = 0.0
var guard_push_timer: float = 0.0
var blink_timer: float = 0.0
var blink_cooldown: float = 0.0
var blink_origin: float = 0.0
var blink_direction: int = 1
var buff_blink_buffer: int = 0
var shadow_return: Node2D
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
var movement_lock: Node
var demon_spawned: bool = false
var carrot_pulse: int = -1
var headbutt_launched: bool = false
var fino_visual: AnimatedSprite2D
var walk_distance: float = 0.0
var cheer_buff: float = 0.0
var cheer_cooldown: float = 0.0
var cheer_spawned: bool = false
var bind_cast_duration: float = 0.7
var fighter_profile: String = "PHUZASHI"
var display_name: String = "PHUZASHI"
var specials_enabled: bool = true
var red_awakened: bool = false
@export var input_prefix: String = ""
var duel_mode: bool = false
var controls_enabled: bool = true
var spawn_point: Vector2 = SPAWN
var opponent: PhuzashiCharacter
var hurt_area: Area2D
var damage_taken: float = 0.0
var last_received: String = ""

func pressed(command: String) -> bool:
	var binding: String = input_prefix+command
	return controls_enabled and InputMap.has_action(binding) and Input.is_action_pressed(binding)

func just_pressed(command: String) -> bool:
	var binding: String = input_prefix+command
	return controls_enabled and InputMap.has_action(binding) and Input.is_action_just_pressed(binding)

func movement_axis() -> float:
	return float(pressed("move_right"))-float(pressed("move_left"))

func enable_duel(prefix: String, enemy: PhuzashiCharacter, spawn: Vector2) -> void:
	input_prefix = prefix
	duel_mode = true
	opponent = enemy
	spawn_point = spawn
	hurt_area = load("res://scripts/combat/fighter_hurtbox.gd").new()
	hurt_area.name = "FighterHurtbox"
	add_child(hurt_area)

func receive_attack(damage: int, move_name: String, attacker: Node2D) -> int:
	last_hit_blocked = false
	if not duel_mode or not controls_enabled or health <= 0.0 or attack_invulnerable():
		return -1
	return _receive_hit(damage,move_name,attacker)

func can_guard() -> bool:
	return pressed("guard") and is_on_floor() and velocity.y >= 0.0 and action_timer <= 0.0 and blink_timer <= 0.0 and dash_timer <= 0.0 and not is_movement_locked() and guard_meter > 0.0 and guard_break_remaining <= 0.0 and not charging

func _tick_defense(delta: float) -> void:
	if guard_break_remaining > 0:
		guard_break_remaining = maxf(0.0,guard_break_remaining-delta)
		if guard_break_remaining <= 0:
			guard_meter = maxf(50.0,guard_meter)
	guard_impact = maxf(0.0,guard_impact-delta)
	guard_push_timer = maxf(0.0,guard_push_timer-delta)
	defense_feedback_time = maxf(0,defense_feedback_time-delta)
	var held: bool = pressed("guard")
	if held and not guard_was_held:
		guard_press_age = 0.0
		perfect_guard_used = false
	elif held:
		guard_press_age += delta
	else:
		guard_press_age = 999.0
	guard_was_held = held
	if held or guard_break_remaining > 0.0 or action_name == "GUARD_BREAK":
		guard_recovery_delay = GUARD_REGEN_DELAY
		return
	# Consume the waiting time before applying only the remaining regeneration time.
	var recovery: float = maxf(0.0,delta-guard_recovery_delay)
	guard_recovery_delay = maxf(0.0,guard_recovery_delay-delta)
	guard_meter = minf(100.0,guard_meter+GUARD_REGEN_RATE*recovery)

func _defense_flash(kind: String) -> void:
	defense_feedback = kind
	defense_feedback_time = 0.45 if kind == "PERFECT GUARD" else GUARD_BREAK_DURATION
	if is_instance_valid(effects):
		effects.play_defense_sound(kind)

func _receive_hit(damage: int, move_name: String, attacker: Node2D) -> int:
	last_hit_blocked = false
	if is_instance_valid(skills) and skills.incoming(move_name,attacker):
		Reaction.hit(self,attacker,0,move_name,true)
		return 0
	var guarded: bool = can_guard()
	if is_instance_valid(attacker):
		guarded = guarded and (attacker.global_position.x-global_position.x)*facing >= 0.0
	guard_recovery_delay = GUARD_REGEN_DELAY
	last_received = move_name
	if guarded:
		guard_impact = 0.24
		guard_push_timer = 0.09
		last_hit_blocked = true
		# Also recognize a press arriving earlier in this same physics tick.
		var fresh: bool = not guard_was_held or guard_press_age < PERFECT_GUARD_WINDOW
		if fresh and not perfect_guard_used:
			if not guard_was_held:
				guard_press_age = 0.0
			guard_was_held = true
			perfect_guard_used = true
			guard_push_timer = 0.025
			energy = minf(100.0,energy+3.0)
			_defense_flash("PERFECT GUARD")
			announce("PERFECT GUARD / +3 MP")
			Reaction.hit(self,attacker,0,move_name,true)
			return 0
		var costs: Dictionary = {"SHADOW_RETURN":22,"SHADOW_REPRISAL":18,"CARROT_UPROOT":22,"SOY_BOMB":18,"CARROT_SPIN":26,"GORILLA_ELBOW":28,"GORILLA_KNEE":24,"GORILLA_QUAKE":22,"GORILLA_ROAR":12,"GORILLA_KING":5,"GORILLA_KING_FINISH":20}
		var guard_cost: float = float(GUARD_COSTS.get(move_name,costs.get(move_name,14)))
		if skills.guard_buff > 0: guard_cost *= 0.55
		guard_meter = maxf(0.0,guard_meter-guard_cost)
	var was_broken: bool = guard_break_remaining > 0.0
	var break_remaining: float = guard_break_remaining
	var actual: float = float(mini(2,damage) if guarded else damage)
	if fighter_profile == "RED_CAP" and red_awakened:
		actual *= 0.7
	health = maxf(0.0,health-actual)
	damage_taken += actual
	if guarded and guard_meter > 0.0 and health > 0.0:
		effects.play_defense_sound("GUARD")
		announce("GUARD / 2 CHIP")
		Reaction.hit(self,attacker,damage,move_name,true)
		return roundi(actual)
	dash_timer = 0.0
	skills.guard_buff = 0
	charging = false
	_clear_combo()
	purple_fist.clear()
	blink_timer = 0.0
	buff_blink_buffer = 0
	jump_buffer = 0.0
	if (was_broken or (guarded and guard_meter <= 0.0)) and health > 0.0:
		action_name = "GUARD_BREAK"
		action_duration = break_remaining if was_broken else GUARD_BREAK_DURATION
		guard_break_remaining = maxf(guard_break_remaining,action_duration)
		_defense_flash("GUARD BREAK")
		announce("GUARD BREAK / 1 SECOND")
	else:
		action_name = "FALL" if move_name in ["KICK_3","ULTIMATE","GORILLA_KING_FINISH","CAPPED_SHOVE"] or health <= 0 else "HIT"
		action_duration = 1.4 if action_name == "FALL" else 0.48
	action_timer = action_duration
	Reaction.hit(self,attacker,damage,move_name,false)
	_set_state(action_name)
	if is_instance_valid(fino_visual): fino_visual.visible = false
	rig.visible = true
	rig.rotation = 0
	rig.animate("HIT" if action_name == "GUARD_BREAK" else action_name,0,facing,0.15)
	skills.present()
	_update_body_shape()
	return roundi(actual)

func award_normal_hit(move_name: String, blocked: bool) -> void:
	if blocked or move_name not in ["PUNCH","PUNCH_2","PUNCH_3","KICK","KICK_2","KICK_3","AIR_PUNCH","AIR_KICK"]:
		return
	energy = minf(100.0,energy+(5.0 if move_name in ["PUNCH_3","KICK_3"] else 3.0))


func select_fighter(profile: String) -> bool:
	if profile not in ["PHUZASHI","RED_CAP","MUAY_THAI","BLACK_COAT","PHUZASHI_CHILL"]:
		return false
	fighter_profile = profile
	display_name = {"RED_CAP":"ASSJIRO","PHUZASHI":"PHUZASHI","MUAY_THAI":"MUAY THAI","BLACK_COAT":"BLACK COAT","PHUZASHI_CHILL":"PHUZASHI CHILL"}[profile]
	specials_enabled = uses_dark_pulse()
	rig.set_character_profile(profile)
	if is_instance_valid(fino_visual):
		fino_visual.sprite_frames = load("res://assets/characters/"+("phuzashi_chill" if profile == "PHUZASHI_CHILL" else "phuzashi_clear")+"/fino_ultimate_frames.res")
	visited = {"IDLE":true}
	reset_training()
	announce(display_name + (" / NORMAL MOVES + I: BLOOD PACT" if profile == "BLACK_COAT" else (" / SIX GORILLA STAND SKILLS" if profile == "MUAY_THAI" else (" / O: Black soy awakening / 6 skills" if profile == "RED_CAP" else " / SIX DARK PULSE SKILLS"))))
	return true

func _ready() -> void:
	add_to_group("bind_targets")
	movement_lock = MovementLock.new()
	movement_lock.name = "MovementLock"
	add_child(movement_lock)
	effects = Node2D.new()
	effects.set_script(Effects)
	effects.name = "CombatEffects"
	add_child(effects)
	move_child(effects, 0)
	purple_fist = PurpleFist.new()
	purple_fist.name = "PurpleFist"
	add_child(purple_fist)
	fino_visual = AnimatedSprite2D.new()
	fino_visual.sprite_frames = load("res://assets/characters/phuzashi_clear/fino_ultimate_frames.res")
	fino_visual.centered = false
	fino_visual.visible = false
	add_child(fino_visual)
	pact = load("res://scripts/combat/blood_pact.gd").new()
	pact.name = "BloodPact"
	add_child(pact)
	move_child(pact,0)
	status_aura = load("res://scripts/effects/status_aura.gd").new()
	status_aura.name = "StatusAura"
	add_child(status_aura)
	move_child(status_aura,0)
	skills = SkillController.new()
	skills.name = "Skills"
	add_child(skills)
	move_child(skills,0)
	shadow_return = ShadowReturn.new()
	shadow_return.name = "ShadowReturn"
	add_child(shadow_return)
	var aura: Node2D = load("res://scripts/effects/fino_aura.gd").new()
	aura.name = "FinoAura"
	add_child(aura)
	move_child(aura,0)

func _physics_process(delta: float) -> void:
	reaction_clock += delta
	hit_shake = maxf(0,hit_shake-delta)
	rig.position = _reaction_offset()
	if impact_pause > 0:
		impact_pause = maxf(0,impact_pause-delta)
		return
	elapsed += delta
	skills.tick(delta)
	cheer_buff = maxf(0,cheer_buff-delta)
	if cheer_buff <= 0: buff_blink_buffer = 0
	cheer_cooldown = maxf(0,cheer_cooldown-delta)
	var previous_x: float = position.x
	if is_instance_valid(fino_visual):
		fino_visual.visible = false
	rig.visible = true
	rig.rotation = 0.0
	charging = false
	if not duel_mode or (controls_enabled and health > 0):
		_tick_defense(delta)
	rig.position = _reaction_offset()
	dash_cooldown = maxf(0.0,dash_cooldown-delta)
	if duel_mode and health <= 0.0:
		velocity.x = skills.push_velocity if skills.push_remaining > 0 else move_toward(velocity.x,0,ACCELERATION*delta)
		if not is_on_floor():
			velocity.y += GRAVITY*delta
		move_and_slide()
		_set_state("FALL")
		rig.animate("FALL",delta,facing,0.95)
		skills.present()
		_update_body_shape()
		queue_redraw()
		effects.queue_redraw()
		return
	if duel_mode and is_instance_valid(opponent) and action_timer <= 0.0 and blink_timer <= 0.0 and absf(opponent.position.x-position.x) > 2.0:
		facing = 1 if opponent.position.x > position.x else -1
	message_time = maxf(0.0, message_time - delta)
	blink_cooldown = maxf(0.0, blink_cooldown - delta)
	if action_timer <= 0.0 and combo_grace > 0.0:
		combo_grace = maxf(0.0, combo_grace - delta)
		if combo_grace <= 0.0:
			_clear_combo()
	if not duel_mode and just_pressed("reset"):
		reset_training()
		get_tree().call_group("training_target", "reset_target")
		return
	if is_movement_locked():
		skills.present()
		velocity = Vector2.ZERO
		jump_buffer = 0.0
		_set_state("BOUND")
		rig.animate("BOUND",delta,facing,0.4)
		queue_redraw()
		effects.queue_redraw()
		return
	if guard_break_remaining > 0.0 and action_name != "GUARD_BREAK":
		action_name = "GUARD_BREAK"
		action_duration = guard_break_remaining
		action_timer = guard_break_remaining
	if not duel_mode and just_pressed("test_hit"):
		receive_training_hit(false)
	elif not duel_mode and just_pressed("test_fall"):
		receive_training_hit(true)

	var was_grounded: bool = is_on_floor()
	coyote = 0.10 if was_grounded else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if just_pressed("jump"):
		jump_buffer = 0.12
	for command: String in ["move_left", "move_right"]:
		if just_pressed(command):
			var direction: int = -1 if command == "move_left" else 1
			var previous: float = left_tap if direction < 0 else right_tap
			if elapsed - previous < BLINK_WINDOW:
				_start_movement_burst(direction)
			if direction < 0:
				left_tap = elapsed
			else:
				right_tap = elapsed
	if just_pressed("dash"):
		_start_movement_burst(int(signf(movement_axis())) if movement_axis() != 0 else facing)
	if dash_timer > 0.0:
		_step_dash(delta)
		return
	if blink_timer > 0.0:
		_step_blink(delta)
		return
	var axis: float = movement_axis()
	var crouching: bool = pressed("crouch")
	var guarding: bool = can_guard()
	if axis != 0.0 and action_timer <= 0.0 and not duel_mode:
		facing = 1 if axis > 0.0 else -1
	# Resolve jump first, so Space+J/K on the same frame is an aerial attack.
	if jump_buffer > 0.0 and coyote > 0.0 and action_timer <= 0.0 and not crouching and not guarding:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0
		_clear_combo()
	var chord: bool = false
	if crouching:
		jump_buffer = 0
		for binding: String in ["punch","chord_three","chord_four","chord_five"]:
			if just_pressed(binding):
				chord = true
				jump_buffer = 0
				skill_input_modifier = true
				request_skill_slot({"punch":1,"chord_three":2,"chord_four":3,"chord_five":4}[binding])
				skill_input_modifier = false
				break
	if not chord and not crouching and not guarding:
		for binding: String in ["pad_ultimate", "red_ultimate", "ultimate", "special", "kick", "punch"]:
			if binding == "red_ultimate" and fighter_profile != "RED_CAP":
				continue
			if just_pressed(binding):
				var requested: String = binding.to_upper()
				if binding in ["pad_ultimate","red_ultimate"]:
					requested = "ULTIMATE"
				elif binding == "ultimate" and fighter_profile == "RED_CAP" and input_prefix != "p2_":
					requested = "SPECIAL"
				start_action(requested)
				break
	if action_timer <= 0.0 and (crouching or guarding):
		_clear_combo()
	charging = pressed("charge") and action_timer <= 0.0 and was_grounded and velocity.y >= 0.0 and axis == 0.0 and not crouching and not guarding
	if charging:
		energy = minf(100.0,energy+CHARGE_RATE*delta)
		_clear_combo()
	var airborne: bool = not was_grounded or velocity.y < 0.0
	var locked: bool = (action_timer > 0.0 and not is_air_attack()) or charging or (not airborne and (crouching or guarding))
	var speed: float = RUN_SPEED if pressed("run") else WALK_SPEED
	if cheer_buff > 0:
		speed *= 1.1
	var desired: float = 0.0 if locked else axis * (AIR_SPEED if airborne else speed)
	if not airborne and action_name in ["PUNCH_2", "PUNCH_3", "KICK_2", "KICK_3"] and action_progress() >= 0.15 and action_progress() < 0.45:
		desired = facing * (80.0 if combo_step == 3 else 45.0)
	if is_fino_active() and struck.is_empty() and action_progress() >= 0.32 and action_progress() < 0.80:
		desired = facing*650.0
	if action_name == "CARROT_HEADBUTT" and action_timer > 0:
		if action_progress() >= 0.18 and not headbutt_launched:
			velocity.y = -260.0
			headbutt_launched = true
		if action_progress() >= 0.18 and action_progress() < 0.67:
			desired = facing*520.0
	if guarding and guard_push_timer > 0.0:
		desired = -facing*100.0
	desired = skills.movement(desired)
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
		if ATTACKS.has(action_name) or SkillBook.MOVES.has(action_name):
			_process_attack()
		if combo_buffer > 0 and _is_combo_action() and action_progress() >= COMBO_LINK_PHASE:
			combo_buffer -= 1
			combo_step += 1
			_begin_attack(_combo_clip())
		elif action_timer <= 0.0:
			if action_name == "TRANSFORM":
				_finish_red_transform()
			elif action_name == "GUARD_BREAK":
				guard_meter = maxf(guard_meter,50.0)
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
	elif charging:
		next = "CHARGE"
	elif crouching:
		next = "CROUCH"
	elif guarding:
		next = "GUARD"
	elif absf(velocity.x) > 15.0:
		next = "RUN" if pressed("run") else "WALK"
	_set_state(next)
	_update_body_shape()
	var phase: float = -1.0
	if action_timer > 0.0:
		phase = action_progress()
	elif state_name == "JUMP":
		phase = clampf((velocity.y - JUMP_VELOCITY) / (-2.0 * JUMP_VELOCITY), 0.0, 1.0)
	if state_name == "FALL" and launched_once:
		# A ram victim tumbles in flight and stays down after landing, rather
		# than replaying upright startup poses in the air.
		phase = maxf(phase,0.40 if not is_on_floor() else 0.75)
	if state_name == "WALK":
		walk_distance += absf(position.x-previous_x)
		phase = fmod(walk_distance/104.0,1.0)
		if velocity.x*facing < 0:
			phase = 1.0-phase
	var pose: String = "GUARD" if charging else ("HIT" if state_name == "GUARD_BREAK" else state_name)
	if charging or state_name == "GUARD_BREAK":
		phase = 0.8 if charging else 0.35
	if state_name == "CHEER":
		pose = "GUARD"
		phase = 0.65
	if state_name == "CARROT_HEADBUTT":
		pose = "RUN"
		phase = 0.3
	elif state_name == "CARROT_RUSH":
		pose = "PUNCH_3" if carrot_pulse == 6 else ("PUNCH_2" if maxi(0,carrot_pulse)%2 else "PUNCH")
		phase = 0.38 if carrot_pulse >= 0 else 0.15
	rig.rotation = facing*0.25 if state_name == "CARROT_HEADBUTT" and headbutt_launched else 0.0
	var skill_pose: Array = skills.pose(pose,phase)
	rig.animate(skill_pose[0], delta, facing, skill_pose[1])
	_update_fino_visual()
	skills.present()
	if is_on_floor() and action_timer <= 0: launched_once = false
	queue_redraw()
	effects.queue_redraw()

func uses_dark_pulse() -> bool:
	return fighter_profile in ["PHUZASHI","PHUZASHI_CHILL"]

func is_fino_active() -> bool:
	return uses_dark_pulse() and action_name == "ULTIMATE" and action_timer > 0

func _update_fino_visual() -> void:
	if not is_fino_active():
		return
	var factor: float = 188.0/float(fino_visual.sprite_frames.get_meta("source_height"))
	fino_visual.scale = Vector2(factor*facing,factor)
	fino_visual.position = -Vector2(512*facing,960)*factor
	fino_visual.animation = "FINO"
	fino_visual.frame = mini(15,floori(action_progress()*16))
	fino_visual.visible = true
	rig.visible = false

func _start_blink(direction: int) -> bool:
	if duel_mode and (not controls_enabled or health <= 0):
		return false
	if not specials_enabled:
		return false
	if guard_break_remaining > 0.0 or is_movement_locked() or action_timer > 0.0:
		return false
	if not is_on_floor() or pressed("crouch") or pressed("guard"):
		return false
	var free: bool = uses_dark_pulse() and cheer_buff > 0
	if blink_timer > 0:
		if free:
			buff_blink_buffer = direction
			return true
		return false
	if blink_cooldown > 0 and not free: return false
	if energy < BLINK_COST and not free:
		announce("Shadow Blink requires 5 MP")
		return false
	charging = false
	energy -= 0 if free else BLINK_COST
	_clear_combo()
	blink_timer = BLINK_DURATION
	blink_cooldown = 0 if free else BLINK_COOLDOWN
	blink_origin = position.x
	blink_direction = direction
	facing = direction
	velocity = Vector2.ZERO
	jump_buffer = 0.0
	_set_state("BLINK")
	announce("STAND BLINK / FREE" if free else "SHADOW BLINK / 5 MP")
	var blink_effect: Node2D = ShadowBlinkVFX.new()
	blink_effect.configure(self)
	get_parent().add_child(blink_effect)
	# Behind the intact fighter, above the stage art; never follows the actor.
	get_parent().move_child(blink_effect, get_index())
	return true

func _start_movement_burst(direction: int) -> bool:
	return _start_blink(direction) if uses_dark_pulse() else _start_dash(direction)

func _start_dash(direction: int) -> bool:
	if (duel_mode and (not controls_enabled or health <= 0)) or dash_timer > 0 or dash_cooldown > 0 or action_timer > 0 or is_movement_locked() or guard_break_remaining > 0:
		return false
	if not is_on_floor() or velocity.y < 0 or pressed("crouch") or pressed("guard"):
		return false
	dash_direction = direction
	facing = direction
	dash_timer = dash_duration()
	dash_cooldown = DASH_COOLDOWN
	charging = false
	jump_buffer = 0
	_clear_combo()
	announce(display_name+" DASH")
	return true

func _step_dash(delta: float) -> void:
	dash_timer = maxf(0.0,dash_timer-delta)
	var phase: float = clampf(1-dash_timer/dash_duration(),0,1)
	var speed: float = DASH_SPEED*(sin(phase*PI) if fighter_profile == "MUAY_THAI" else 1)
	velocity = Vector2(dash_direction*speed,GRAVITY*delta)
	move_and_slide()
	position.x = clampf(position.x,75,1205)
	_set_state("DASH")
	rig.animate("DASH" if fighter_profile == "MUAY_THAI" else "RUN",delta,facing,phase if fighter_profile == "MUAY_THAI" else -1)
	skills.present()
	queue_redraw()
	effects.queue_redraw()
	if dash_timer <= 0:
		velocity.x = 0

func dash_duration() -> float:
	return 0.32 if fighter_profile == "MUAY_THAI" else DASH_DURATION

func skill_mana_cost(action: String) -> float:
	if fighter_profile == "RED_CAP" and red_awakened and action in SkillBook.ROSTER.RED_CAP.slice(0,5): return 0
	return SkillBook.cost(action)

func blink_progress() -> float:
	return clampf(1.0 - blink_timer / BLINK_DURATION, 0.0, 1.0)

func blink_invulnerable() -> bool:
	return blink_timer > 0.0 and blink_progress() >= 4.0/12.0 and blink_progress() < 8.0/12.0

func cyclone_active() -> bool:
	return fighter_profile == "RED_CAP" and red_awakened and action_name == "CARROT_SPIN" and action_timer > 0

func attack_invulnerable() -> bool:
	return blink_invulnerable() or cyclone_active()

func _reaction_offset() -> Vector2:
	var shield := Vector2(sin(guard_impact*125.0)*2.5,cos(guard_impact*110.0))*(guard_impact/0.24)
	return shield+Vector2(sin(reaction_clock*151),cos(reaction_clock*127)*0.4)*hit_shake_power*hit_shake/0.20

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
		var next: int = buff_blink_buffer
		buff_blink_buffer = 0
		if cheer_buff > 0 and next != 0: _start_blink(next)

func slot_action(index: int) -> String:
	var action: String = SkillBook.ROSTER[fighter_profile][index]
	return "CAPPED_SHOVE" if fighter_profile == "RED_CAP" and not red_awakened and action == "SOY_BOMB" else action

func request_skill_slot(index: int) -> bool:
	if index < 0 or index >= 6: return false
	var action: String = slot_action(index)
	return false if action.is_empty() else start_action(action)

func start_action(action: String) -> bool:
	if fighter_profile == "RED_CAP" and not red_awakened and action == "SOY_BOMB": action = "CAPPED_SHOVE"
	if fighter_profile == "BLACK_COAT":
		if action == "ULTIMATE": action = "BLOOD_PACT"
		if action not in ["PUNCH","KICK","BLOOD_PACT"]: return false
	if fighter_profile == "MUAY_THAI":
		action = {"SPECIAL":"GORILLA_ELBOW","DEMON_BIND":"GORILLA_KNEE","CHEER":"GORILLA_QUAKE","ULTIMATE":"GORILLA_KING"}.get(action,action)
	elif fighter_profile == "RED_CAP" and action == "CHEER":
		action = "CARROT_UPROOT"
	if SkillBook.MOVES.has(action):
		return skills.start(action)
	if fighter_profile == "RED_CAP" and action in ["CARROT_HEADBUTT","CARROT_RUSH"]:
		return _start_red_skill(action)
	if action == "CHEER":
		return _start_cheer()
	if fighter_profile == "RED_CAP" and action in ["SPECIAL","DEMON_BIND"]:
		return _start_red_skill("CARROT_HEADBUTT" if action == "SPECIAL" else "CARROT_RUSH")
	if fighter_profile == "RED_CAP" and action in ["ULTIMATE","TRANSFORM"]:
		return _start_red_transform()
	if duel_mode and (not controls_enabled or health <= 0):
		return false
	if not specials_enabled and action in ["SPECIAL","ULTIMATE","DEMON_BIND"]:
		announce("ASSJIRO / Special skills are not assigned yet")
		return false
	if dash_timer > 0 or guard_break_remaining > 0.0 or is_movement_locked() or blink_timer > 0.0:
		return false
	if not skill_input_modifier and (pressed("guard") or (pressed("crouch") and action != "DEMON_BIND")):
		return false
	if action in ["PUNCH", "KICK"]:
		return _request_normal_attack(action)
	if action not in ["SPECIAL", "ULTIMATE", "DEMON_BIND"] or action_timer > 0.0 or not is_on_floor() or velocity.y < 0.0:
		return false
	var config: Array = attack_config(action)
	if energy < float(config[1]):
		announce("Not enough MP / hold charge or land normal hits")
		return false
	energy -= float(config[1])
	_clear_combo()
	_begin_attack(action)
	return true

func bind_lock_duration() -> float:
	return 1.1 if cheer_buff > 0 else 0.7

func _start_cheer() -> bool:
	if not uses_dark_pulse() or cheer_cooldown > 0 or energy < 30 or action_timer > 0 or dash_timer > 0 or blink_timer > 0 or guard_break_remaining > 0 or is_movement_locked():
		return false
	if (duel_mode and (not controls_enabled or health <= 0)) or not is_on_floor() or velocity.y < 0 or (not skill_input_modifier and (pressed("guard") or pressed("crouch"))):
		return false
	energy -= 30
	cheer_cooldown = 14
	_clear_combo()
	_begin_attack("CHEER")
	announce("CHEER ASSIST / 30 MP")
	return true

func _start_red_skill(action: String) -> bool:
	if not red_awakened:
		announce("ASSJIRO / Transform first to unlock carrot skills")
		return false
	if (duel_mode and (not controls_enabled or health <= 0)) or dash_timer > 0 or action_timer > 0 or is_movement_locked() or blink_timer > 0 or guard_break_remaining > 0:
		return false
	if not is_on_floor() or velocity.y < 0 or (not skill_input_modifier and (pressed("guard") or (action != "CARROT_RUSH" and pressed("crouch")))):
		return false
	if float(skills.cooldowns.get(action,0)) > 0: return false
	var cost: float = skill_mana_cost(action)
	if energy < cost:
		announce("CARROT POWER / Requires %d MP" % cost)
		return false
	energy -= cost
	skills.cooldowns[action] = SkillBook.COOLDOWNS[action]
	_clear_combo()
	_begin_attack(action)
	announce(("CARROT HEADBUTT" if action == "CARROT_HEADBUTT" else "CARROT BARRAGE")+" / FREE AWAKENED SKILL")
	return true

func _start_red_transform() -> bool:
	if dash_timer > 0 or guard_break_remaining > 0.0 or red_awakened or action_timer > 0.0 or is_movement_locked() or blink_timer > 0.0 or health <= 0:
		return false
	if duel_mode and not controls_enabled:
		return false
	if not is_on_floor() or velocity.y < 0 or pressed("crouch") or pressed("guard"):
		return false
	if energy < RED_TRANSFORM_COST:
		announce("CAP OFF / Requires 70 MP")
		return false
	charging = false
	energy -= RED_TRANSFORM_COST
	_clear_combo()
	struck.clear()
	velocity = Vector2.ZERO
	jump_buffer = 0.0
	action_name = "TRANSFORM"
	action_duration = RED_TRANSFORM_DURATION
	action_timer = action_duration
	_set_state("TRANSFORM")
	attack_started.emit("TRANSFORM")
	UltimateCutin.play_for(self)
	announce("CAP OFF / BLACK SOY SAUCE / 70 MP")
	return true

func _finish_red_transform() -> void:
	red_awakened = true
	rig.set_red_awakened(true)
	announce("AWAKENED / BALD & SHIRTLESS")

func red_transform_phase() -> String:
	if action_name != "TRANSFORM" or action_timer <= 0:
		return ""
	var progress: float = action_progress()
	if progress < 5.0/16.0:
		return "CAP OFF"
	if progress < 10.0/16.0:
		return "BLACK SOY SAUCE"
	return "SHIRT OFF"


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
	charging = false
	var config: Array = attack_config(action)
	if action == "DEMON_BIND":
		bind_cast_duration = bind_lock_duration()
	action_name = action
	action_duration = float(config[0])
	action_timer = action_duration
	struck.clear()
	pulse_spawned = false
	demon_spawned = false
	carrot_pulse = -1
	cheer_spawned = false
	headbutt_launched = false
	if is_instance_valid(skills): skills.begin(action)
	if not is_air_attack():
		velocity.x = 0.0
	jump_buffer = 0.0
	_set_state(action)
	attack_started.emit(action)
	if (uses_dark_pulse() and action == "ULTIMATE") or action in ["GORILLA_KING","BLOOD_PACT"]: UltimateCutin.play_for(self)
	if combo_step > 0:
		announce("%s COMBO / %d OF 3" % [combo_family, combo_step])
	elif is_air_attack():
		announce("JUMP " + action.trim_prefix("AIR_"))
	elif action == "DEMON_BIND":
		announce("DEMON BIND / 25 MP")

func is_movement_locked() -> bool:
	return is_instance_valid(movement_lock) and movement_lock.is_locked()

func get_bind_anchor() -> Vector2:
	return global_position+Vector2(0,-78)

func apply_movement_lock(seconds: float) -> bool:
	if duel_mode and health <= 0:
		return false
	if attack_invulnerable():
		return false
	charging = false
	dash_timer = 0.0
	movement_lock.apply(seconds)
	hit_shake = 0.16
	hit_shake_power = 2.5
	velocity = Vector2.ZERO
	action_name = ""
	action_timer = 0.0
	blink_timer = 0.0
	buff_blink_buffer = 0
	jump_buffer = 0.0
	_clear_combo()
	purple_fist.clear()
	_set_state("BOUND")
	_update_body_shape()
	for blink_visual: Node in get_tree().get_nodes_in_group("shadow_blink_effects"):
		if blink_visual.fighter == self:
			blink_visual.queue_free()
	return true

func find_bind_target() -> Node2D:
	var best: Node2D = null
	var distance: float = 621.0
	for candidate: Node in get_tree().get_nodes_in_group("bind_targets"):
		if candidate == self or (candidate is PhuzashiCharacter and candidate.duel_mode and candidate.health <= 0) or not candidate is Node2D or not candidate.has_method("apply_movement_lock") or not candidate.has_method("is_movement_locked"):
			continue
		var aim: Vector2 = candidate.get_bind_anchor() if candidate.has_method("get_bind_anchor") else candidate.global_position
		var forward: float = (aim.x-global_position.x)*facing
		if forward >= 0.0 and forward <= 620.0 and absf(aim.y-global_position.y) <= 180.0 and forward < distance:
			best = candidate
			distance = forward
	return best

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
	if action_name == "TRANSFORM" and action_timer > 0:
		return red_transform_phase()
	if (not ATTACKS.has(action_name) and not SkillBook.MOVES.has(action_name)) or action_timer <= 0.0:
		return "READY"
	var config: Array = attack_config(action_name)
	var phase: float = action_progress()
	return "STARTUP" if phase < float(config[3]) else ("ACTIVE" if phase <= float(config[4]) else "RECOVERY")

func _process_attack() -> void:
	var config: Array = attack_config(action_name)
	var phase: float = action_progress()
	if phase < float(config[3]) or phase > float(config[4]):
		return
	if SkillBook.MOVES.has(action_name):
		skills.process_attack()
		return
	if action_name == "CHEER":
		if not cheer_spawned:
			cheer_spawned = true
			var assist: Node2D = CheerAssist.new()
			assist.configure(self)
			get_parent().add_child(assist)
		return
	if action_name == "DEMON_BIND":
		if not demon_spawned:
			demon_spawned = true
			var demon: Node2D = DemonBind.new()
			var victim: Node2D = find_bind_target()
			demon.configure(self,victim)
			demon.lock_time = bind_cast_duration
			get_parent().add_child(demon)
			if is_instance_valid(victim) and victim.get_parent() == get_parent():
				get_parent().move_child(demon,victim.get_index())
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
	if action_name == "CARROT_RUSH":
		var pulse: int = mini(6,floori((phase-0.20)/0.085))
		if pulse != carrot_pulse:
			carrot_pulse = pulse
			struck.clear()
	attack_shape.shape.size = Vector2(float(config[5]), float(config[6]))
	var strike_y: float = -116.0 if action_name == "PUNCH_3" else (-64.0 if action_name == "AIR_KICK" else (-78.0 if action_name == "AIR_PUNCH" else -82.0))
	if fighter_profile == "MUAY_THAI":
		strike_y = -112.0 if action_name.begins_with("PUNCH") else (-125.0 if action_name == "KICK_3" else -90.0)
	attack_shape.position = Vector2(facing * (float(config[5]) * 0.5 + 18.0), strike_y)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = attack_shape.shape
	query.transform = attack_shape.global_transform
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var target: Object = result.collider
		if (target.has_method("take_hit") or target.has_method("receive_attack")) and not struck.has(target.get_instance_id()):
			var inflicted: int = 8 if action_name == "CARROT_RUSH" and carrot_pulse == 6 else int(config[2])
			inflicted = outgoing_damage(inflicted)
			var hit_move: String = "CARROT_RUSH_FINISH" if action_name == "CARROT_RUSH" and carrot_pulse == 6 else action_name
			if target.has_method("receive_attack"):
				if not target.can_be_hit_by(self):
					continue
				inflicted = target.receive_attack(inflicted,hit_move,self)
				if inflicted < 0:
					continue
			else:
				target.take_hit(inflicted,hit_move,self)
			award_normal_hit(action_name,target.was_last_hit_blocked() if target.has_method("was_last_hit_blocked") else false)
			struck[target.get_instance_id()] = true
			target_struck.emit(inflicted)
			if action_name == "PUNCH_3" and specials_enabled:
				var impact: Node2D = PurpleImpact.new()
				impact.position = target.global_position + Vector2(-facing*12,-30)
				impact.direction = facing
				get_parent().add_child(impact)

func receive_training_hit(knockdown: bool) -> void:
	if attack_invulnerable() or action_name == "FALL":
		return
	_receive_hit(18 if knockdown else 8,"KICK_3" if knockdown else "PUNCH",null)

func outgoing_damage(base: int) -> int:
	return roundi(base*1.30) if is_instance_valid(pact) and pact.buff_remaining > 0 else base

func attack_config(action: String) -> Array:
	if SkillBook.MOVES.has(action): return SkillBook.MOVES[action]
	return MUAY_ATTACKS.get(action,ATTACKS[action]) if fighter_profile == "MUAY_THAI" else ATTACKS[action]

func standing_height() -> float:
	return 168.0 if fighter_profile == "MUAY_THAI" else 144.0

func low_height() -> float:
	return 100.0 if fighter_profile == "MUAY_THAI" else 84.0

func _update_body_shape() -> void:
	var low: bool = state_name in ["CROUCH","FALL"]
	var height: float = low_height() if low else standing_height()
	body_shape.shape.size = Vector2(50.0,height)
	body_shape.position.y = -height*0.5

func _set_state(next: String) -> void:
	if state_name != next:
		state_name = next
		visited[next] = true
		state_changed.emit(next)

func announce(text: String) -> void:
	message = text
	message_time = 3.0

func reset_training() -> void:
	if red_awakened:
		red_awakened = false
		display_name = {"RED_CAP":"ASSJIRO","PHUZASHI":"PHUZASHI","MUAY_THAI":"MUAY THAI","BLACK_COAT":"BLACK COAT","PHUZASHI_CHILL":"PHUZASHI CHILL"}[fighter_profile]
		rig.set_red_awakened(false)
	global_position = spawn_point
	velocity = Vector2.ZERO
	health = max_health
	damage_taken = 0
	last_received = ""
	energy = STARTING_MANA
	impact_pause = 0
	hit_shake = 0
	hit_shake_power = 0
	launched_once = false
	skill_input_modifier = false
	if is_instance_valid(skills): skills.reset()
	if is_instance_valid(shadow_return): shadow_return.reset()
	if is_instance_valid(pact): pact.reset()
	guard_meter = 100.0
	guard_break_remaining = 0.0
	guard_recovery_delay = 0.0
	guard_press_age = 999.0
	guard_was_held = false
	perfect_guard_used = false
	charging = false
	last_hit_blocked = false
	defense_feedback = ""
	defense_feedback_time = 0.0
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
	buff_blink_buffer = 0
	dash_timer = 0.0
	if is_instance_valid(fino_visual):
		fino_visual.visible = false
	rig.visible = true
	walk_distance = 0.0
	dash_cooldown = 0.0
	cheer_buff = 0.0
	cheer_cooldown = 0.0
	cheer_spawned = false
	get_tree().call_group("cheer_assists","queue_free")
	get_tree().call_group("ninja_smoke_effects","queue_free")
	guard_impact = 0.0
	guard_push_timer = 0.0
	rig.position = Vector2.ZERO
	left_tap = -100.0
	right_tap = -100.0
	_clear_combo()
	_set_state("IDLE")
	rig.reset_pose()
	_update_body_shape()
	get_tree().call_group("dark_pulses", "queue_free")
	get_tree().call_group("six_skill_effects", "queue_free")
	get_tree().call_group("ultimate_cutins","clear")
	get_tree().call_group("shadow_blink_effects", "queue_free")
	get_tree().call_group("purple_punch_impacts", "queue_free")
	get_tree().call_group("demon_bind_effects", "queue_free")
	get_tree().call_group("movement_locks", "clear")
	demon_spawned = false
	carrot_pulse = -1
	headbutt_launched = false
	rig.rotation = 0.0
	if is_instance_valid(purple_fist):
		purple_fist.clear()
	if is_instance_valid(status_aura): status_aura.refresh()
	announce("Training reset")

func _draw() -> void:
	var altitude: float = maxf(0.0, FLOOR_Y - position.y)
	draw_set_transform(Vector2(0, altitude + 2), 0, Vector2(1.0, 0.19))
	draw_circle(Vector2.ZERO, maxf(18.0, 44.0 - altitude * 0.08), Color(0.015, 0.03, 0.07, 0.32))
	draw_set_transform(Vector2.ZERO)
	if debug_hitboxes:
		draw_rect(Rect2(body_shape.position - body_shape.shape.size * 0.5, body_shape.shape.size), Color(0.2, 1, 0.8, 0.3), false, 2.0)
		if attack_phase() == "ACTIVE" and action_name not in ["SPECIAL", "DEMON_BIND"]:
			draw_rect(Rect2(attack_shape.position - attack_shape.shape.size * 0.5, attack_shape.shape.size), Color(1, 0.3, 0.4, 0.6), false, 2.0)
