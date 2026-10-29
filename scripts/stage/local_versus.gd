extends Node2D
## Two independent human-controlled bodies; a 99-second first-to-two match.
const InputSetup = preload("res://scripts/character/input_setup.gd")
@export var round_health: float = 200.0
const SPAWNS: Array[Vector2] = [Vector2(410,586),Vector2(870,586)]
@onready var p1: PhuzashiCharacter = $Player1
@onready var p2: PhuzashiCharacter = $Player2
var phase: String = "READY"
var phase_time: float = 0.0
var remaining: float = 99.0
var scores: Array[int] = [0,0]
var round_number: int = 1
var winner: int = -1
var result: String = ""
var show_help: bool = false
var paused: bool = false
var pause_reason: String = ""

func _enter_tree() -> void:
	InputSetup.install()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	for child: Node in get_children():
		child.process_mode = Node.PROCESS_MODE_PAUSABLE
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS
	var fighters: Array = get_tree().get_meta("fighter_choices",["PHUZASHI","RED_CAP"])
	p1.select_fighter(fighters[0])
	p2.select_fighter(fighters[1])
	p1.rig.set_clear_enabled(true)
	p1.enable_duel("p1_",p2,SPAWNS[0])
	p2.enable_duel("p2_",p1,SPAWNS[1])
	Gamepads.set_context("VERSUS")
	Gamepads.pause_requested.connect(toggle_pause)
	Gamepads.help_requested.connect(toggle_help)
	Gamepads.device_changed.connect(controller_changed)
	start_round()

func toggle_help() -> void:
	if Gamepads.settings_open:
		return
	show_help = not show_help

func toggle_pause() -> void:
	if Gamepads.settings_open:
		return
	if phase == "MATCH_OVER" and not paused:
		restart_match()
		return
	paused = not paused
	pause_reason = ""
	Gamepads.suspend_until_neutral()
	get_tree().paused = paused

func controller_changed() -> void:
	paused = true
	pause_reason = "CONTROLLER CHANGED / CHECK P1 & P2"
	_release_inputs()
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if Gamepads.settings_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F8:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/title_menu.tscn")
		return
	if event is InputEventJoypadButton and event.pressed and event.device in Gamepads.assignments.values() and paused and event.button_index == JOY_BUTTON_Y:
		restart_match()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			toggle_pause()
		elif event.physical_keycode == KEY_F1:
			show_help = not show_help
		elif event.physical_keycode == KEY_F3:
			p1.debug_hitboxes = not p1.debug_hitboxes
			p2.debug_hitboxes = p1.debug_hitboxes
		elif event.physical_keycode == KEY_R:
			restart_match()
		elif event.physical_keycode == KEY_F6:
			get_tree().paused = false
			get_tree().set_meta("clear_training",true)
			get_tree().change_scene_to_file("res://scenes/main.tscn")

func _physics_process(delta: float) -> void:
	if paused:
		return
	phase_time += delta
	if phase == "READY" and phase_time >= 1.8:
		phase = "FIGHT"
		phase_time = 0
		p1.controls_enabled = true
		p2.controls_enabled = true
	elif phase == "FIGHT":
		remaining = maxf(0,remaining-delta)
		_separate_fighters()
		if p1.health <= 0 or p2.health <= 0 or remaining <= 0:
			finish_round()
	elif phase == "ROUND_OVER" and phase_time >= 3.0:
		round_number += 1
		start_round()

func _separate_fighters() -> void:
	# Gentle pushboxes on the ground; jumping and Blink can cross sides.
	if p1.is_fino_active() or p2.is_fino_active() or p1.blink_timer > 0 or p2.blink_timer > 0 or not p1.is_on_floor() or not p2.is_on_floor():
		return
	var distance: float = absf(p2.position.x-p1.position.x)
	if distance >= 54:
		return
	var sign_x: float = 1.0 if p2.position.x >= p1.position.x else -1.0
	var correction: float = (54-distance)*0.5
	if not p1.is_movement_locked() and not p2.is_movement_locked():
		p1.position.x = clampf(p1.position.x-sign_x*correction,75,1205)
		p2.position.x = clampf(p2.position.x+sign_x*correction,75,1205)
	elif p1.is_movement_locked():
		p2.position.x = clampf(p1.position.x+sign_x*54,75,1205)
	else:
		p1.position.x = clampf(p2.position.x-sign_x*54,75,1205)

func _release_inputs() -> void:
	for command: StringName in InputMap.get_actions():
		Input.action_release(command)

func start_round() -> void:
	_release_inputs()
	p1.max_health = round_health
	p2.max_health = round_health
	p1.reset_training()
	p2.reset_training()
	p1.position = SPAWNS[0]
	p2.position = SPAWNS[1]
	p1.facing = 1
	p2.facing = -1
	p1.controls_enabled = false
	p2.controls_enabled = false
	phase = "READY"
	phase_time = 0
	remaining = 99
	winner = -1
	result = "ROUND %d" % round_number

func finish_round() -> void:
	# Defer settlement to the end of the frame so a simultaneous KO is a draw.
	if phase != "FIGHT":
		return
	phase = "SETTLING"
	call_deferred("_settle_round")

func _settle_round() -> void:
	winner = -1 if is_equal_approx(p1.health,p2.health) else (0 if p1.health > p2.health else 1)
	if winner >= 0:
		scores[winner] += 1
	result = "DRAW" if winner < 0 else ([p1,p2][winner].display_name+" WINS")
	phase = "MATCH_OVER" if winner >= 0 and scores[winner] >= 2 else "ROUND_OVER"
	phase_time = 0
	p1.controls_enabled = false
	p2.controls_enabled = false
	# Resolve the round once; no projectiles can change HP during the result card.
	for group: String in ["cheer_assists","dark_pulses","demon_bind_effects","shadow_blink_effects","purple_punch_impacts"]:
		get_tree().call_group(group,"queue_free")
	for fighter: PhuzashiCharacter in [p1,p2]:
		fighter.cheer_buff = 0.0
		fighter.charging = false
		fighter.action_timer = 0
		fighter.action_name = ""
		fighter.dash_timer = 0
		fighter.blink_timer = 0
		fighter._clear_combo()
		fighter.movement_lock.clear()
		fighter.purple_fist.clear()

func restart_match() -> void:
	paused = false
	pause_reason = ""
	Gamepads.suspend_until_neutral()
	get_tree().paused = false
	scores = [0,0]
	round_number = 1
	start_round()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		_release_inputs()
		Gamepads.suspend_until_neutral()
		pause_reason = "WINDOW LOST FOCUS"
		paused = true
		get_tree().paused = true

func _exit_tree() -> void:
	_release_inputs()
	get_tree().paused = false
