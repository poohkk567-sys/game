extends Node2D
## Stage orchestration; F2 demonstrates every move without adding a fighter.
const InputSetup = preload("res://scripts/character/input_setup.gd")
const PHUZASHI_SEQUENCE: Array[String] = ["IDLE", "WALK", "RUN", "JUMP", "CROUCH", "GUARD", "PUNCH", "KICK", "HIT", "FALL", "SPECIAL", "ULTIMATE", "AIR_PUNCH", "AIR_KICK", "PUNCH_COMBO", "KICK_COMBO", "BLINK", "DEMON_BIND"]
const NORMAL_SEQUENCE: Array[String] = ["IDLE", "WALK", "RUN", "JUMP", "CROUCH", "GUARD", "PUNCH", "KICK", "HIT", "FALL", "AIR_PUNCH", "AIR_KICK", "PUNCH_COMBO", "KICK_COMBO"]
var SEQUENCE: Array[String] = PHUZASHI_SEQUENCE.duplicate()
@onready var phuzashi: PhuzashiCharacter = $PHUZASHI
@onready var target: Area2D = $TrainingCrystal
var show_help: bool = false
var showcase: bool = false
var showcase_index: int = -1
var showcase_clock: float = 0.0
var paused: bool = false
var demo_held: Array[String] = []

func _enter_tree() -> void:
	InputSetup.install()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	if get_tree().get_meta("clear_training",false):
		phuzashi.rig.set_clear_enabled(true)
	# Children pause normally; the orchestrator remains available for Esc.
	for child: Node in get_children():
		child.process_mode = Node.PROCESS_MODE_PAUSABLE
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F6:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/versus_school.tscn")
		return
	if event.is_action_pressed("switch_fighter") and not event.is_echo() and not paused:
		switch_fighter()
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		paused = not paused
		get_tree().paused = paused
	if event.is_action_pressed("help") and not event.is_echo():
		show_help = not show_help
	if event.is_action_pressed("hitboxes") and not event.is_echo():
		phuzashi.debug_hitboxes = not phuzashi.debug_hitboxes
	if event.is_action_pressed("sprite_trial") and not event.is_echo():
		phuzashi.rig.set_draft_enabled(not phuzashi.rig.use_draft_spritesheet)
		phuzashi.announce("RED CAP / Whole-body sprites" if not phuzashi.specials_enabled else ("SPRITESHEET: ALL 12 MOVES" if phuzashi.rig.use_draft_spritesheet else "Original master animation"))
	if event.is_action_pressed("showcase") and not event.is_echo():
		set_showcase(not showcase)
	elif showcase and event is InputEventKey and event.pressed and not event.echo and not event.is_action("pause") and not event.is_action("help") and not event.is_action("hitboxes") and not event.is_action("sprite_trial"):
		set_showcase(false)

func switch_fighter() -> void:
	set_showcase(false)
	_release_demo()
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	phuzashi.select_fighter("RED_CAP" if phuzashi.fighter_profile == "PHUZASHI" else "PHUZASHI")
	target.reset_target()
	SEQUENCE = PHUZASHI_SEQUENCE.duplicate() if phuzashi.specials_enabled else NORMAL_SEQUENCE.duplicate()

func _physics_process(delta: float) -> void:
	if paused or not showcase:
		return
	showcase_clock -= delta
	if showcase_clock <= 0.0:
		_release_demo()
		showcase_index = (showcase_index + 1) % SEQUENCE.size()
		phuzashi.reset_training()
		phuzashi.position.x = 800.0
		showcase_clock = 2.4
		# Wait a physics frame after reset so grounding/contact are established.
		phuzashi.announce("SHOWCASE / " + SEQUENCE[showcase_index] + " — F2 to return")
		call_deferred("_demonstrate", SEQUENCE[showcase_index])

func set_showcase(enabled: bool) -> void:
	showcase = enabled
	showcase_clock = 0.0
	showcase_index = -1
	_release_demo()
	phuzashi.reset_training()
	phuzashi.announce("SHOWCASE — moves and combos; F2 or any movement key exits" if enabled else "Manual training")

func _demonstrate(move_name: String) -> void:
	if not showcase:
		return
	match move_name:
		"WALK":
			phuzashi.position.x = 270.0
			_hold_demo("move_right")
		"RUN":
			phuzashi.position.x = 160.0
			_hold_demo("move_right")
			_hold_demo("run")
		"JUMP":
			phuzashi.velocity.y = phuzashi.JUMP_VELOCITY
		"CROUCH": _hold_demo("crouch")
		"GUARD": _hold_demo("guard")
		"HIT": phuzashi.receive_training_hit(false)
		"FALL": phuzashi.receive_training_hit(true)
		"AIR_PUNCH", "AIR_KICK":
			phuzashi.velocity.y = phuzashi.JUMP_VELOCITY
			phuzashi.start_action(move_name.trim_prefix("AIR_"))
		"PUNCH_COMBO", "KICK_COMBO":
			var family: String = move_name.trim_suffix("_COMBO")
			for _i in range(3):
				phuzashi.start_action(family)
		"BLINK":
			phuzashi.position.x = 500
			phuzashi._start_blink(1)
		"PUNCH", "KICK", "SPECIAL", "ULTIMATE", "DEMON_BIND":
			phuzashi.position.x = 800.0
			phuzashi.start_action(move_name)

func _hold_demo(action: String) -> void:
	Input.action_press(action)
	demo_held.append(action)

func _release_demo() -> void:
	for action: String in demo_held:
		Input.action_release(action)
	demo_held.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		if showcase:
			set_showcase(false)
		for action: StringName in InputMap.get_actions():
			Input.action_release(action)

func _exit_tree() -> void:
	_release_demo()
	get_tree().paused = false
