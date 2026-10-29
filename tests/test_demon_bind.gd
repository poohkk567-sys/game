extends SceneTree
## Input, real moving-body immobilization, duration, MP and lifecycle regressions.
const Lock = preload("res://scripts/combat/movement_lock.gd")
var checks: int = 0
var failures: int = 0
var stage: Node2D
var actor: PhuzashiCharacter
var target: Area2D
var casts: int = 0

class MovingTarget extends CharacterBody2D:
	var status: Node
	func _ready() -> void:
		add_to_group("bind_targets")
		status = load("res://scripts/combat/movement_lock.gd").new()
		add_child(status)
	func _physics_process(delta: float) -> void:
		# Deliberately ignores the lock: the shared status must still pin this AI.
		velocity = Vector2(70,0)
		position += velocity*delta
	func get_bind_anchor() -> Vector2:
		return global_position+Vector2(0,-78)
	func apply_movement_lock(seconds: float) -> bool:
		status.apply(seconds)
		return true
	func is_movement_locked() -> bool:
		return status.is_locked()

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS "+label)
	else:
		failures += 1
		push_error("FAIL "+label)

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func on_attack(action: String) -> void:
	if action == "DEMON_BIND":
		casts += 1

func reset() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	target.reset_target()
	casts = 0
	await frames(4)

func until_locked(victim: Node) -> bool:
	for _i in range(90):
		await frames(1)
		if victim.is_movement_locked():
			return true
	return false

func chord() -> void:
	Input.action_press("crouch")
	Input.action_press("punch")
	await frames(2)
	Input.action_release("punch")
	Input.action_release("crouch")
	await frames(1)

func run() -> void:
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	actor = stage.get_node("PHUZASHI")
	actor.energy = 100 # Explicit full-mana combat fixture.
	target = stage.get_node("TrainingCrystal")
	actor.attack_started.connect(on_attack)
	await reset()
	check(actor.find_bind_target() == target,"Default training position can select the forward crystal")
	check(actor.start_action("DEMON_BIND") and actor.energy == 75.0,"Cast spends exactly 25 MP once")
	await frames(20)
	check(actor.rig.draft_animation.animation == "DEMON_BIND" and actor.rig.draft_animation.visible,"Cast uses existing complete character art")
	check(not target.is_movement_locked(),"Lock does not begin before the demon reaches its target")
	check(await until_locked(target),"Spirit reaches and immobilizes the target")
	check(target.movement_lock.remaining >= 0.68 and target.movement_lock.remaining <= 0.7,"The full 0.7-second lock starts on arrival")
	check(target.health == 100 and target.hit_count == 0 and target.total_damage == 0,"Control spell does not invent damage or combo hits")
	check(get_nodes_in_group("dark_pulses").is_empty(),"Bind does not accidentally launch the damage projectile")
	check(get_nodes_in_group("demon_bind_effects").size() == 1,"One cast creates one demon")
	var demon: Node2D = get_nodes_in_group("demon_bind_effects")[0]
	check(demon.phase == "HOLD" and demon.caught,"Demon switches to its gripping animation on a real catch")
	var bob: float = target.elapsed
	var anchor: Vector2 = target.global_position
	await frames(20)
	check(target.elapsed == bob and target.global_position == anchor,"Bound crystal stops its normal floating motion")
	check(absf(target.movement_lock.remaining-(0.7-20.0/60.0)) < 0.025,"Status duration advances in physics seconds")
	var remaining: float = target.movement_lock.remaining
	var age: float = demon.age
	paused = true
	for _i in range(8):
		await process_frame
	check(target.movement_lock.remaining == remaining and demon.age == age,"Pause freezes both lock timer and demon animation")
	paused = false
	await frames(20)
	check(target.is_movement_locked(),"Lock still holds shortly before 0.7 seconds")
	await frames(3)
	check(not target.is_movement_locked(),"Lock expires at 0.7 seconds within one physics tick")
	await frames(3)
	check(target.elapsed > bob,"Target animation resumes automatically after release")
	await frames(20)
	check(get_nodes_in_group("demon_bind_effects").is_empty(),"Released demon fades and is deleted")

	await reset()
	Input.action_press("crouch")
	Input.action_press("punch")
	await frames(80)
	Input.action_release("crouch")
	Input.action_release("punch")
	check(casts == 1,"Holding S+J casts once without auto-repeating")
	check(actor.energy == 75,"Holding the chord spends only one 25-MP cost")
	check(target.hit_count == 0,"S+J takes priority over a normal punch")
	await reset()
	Input.action_press("crouch")
	await frames(3)
	Input.action_press("punch")
	await frames(2)
	Input.action_release("punch")
	Input.action_release("crouch")
	check(casts == 1 and actor.action_name == "DEMON_BIND","Holding S then tapping J casts correctly")
	await reset()
	actor.energy = 10
	check(not actor.start_action("DEMON_BIND") and actor.energy == 10,"Insufficient mana rejects cast without spending")
	await chord()
	check(casts == 0 and get_nodes_in_group("demon_bind_effects").is_empty(),"Low-MP chord neither punches nor summons")
	await reset()
	Input.action_press("guard")
	check(not actor.start_action("DEMON_BIND"),"Guard prevents overlapping bind startup")
	Input.action_release("guard")
	actor.start_action("PUNCH")
	check(not actor.start_action("DEMON_BIND"),"An active attack cannot be overwritten by the bind")
	await reset()
	Input.action_press("jump")
	await frames(3)
	Input.action_release("jump")
	check(not actor.start_action("DEMON_BIND") and actor.energy == 100,"Airborne casts are rejected without spending MP")
	await reset()
	actor._start_blink(1)
	check(not actor.start_action("DEMON_BIND"),"Bind cannot overlap Shadow Blink")
	await frames(10)
	check(not actor.apply_movement_lock(0.7),"Blink intangible frames can evade an incoming bind")

	await reset()
	actor.position.x = 1035
	actor.facing = -1
	await chord()
	check(await until_locked(target),"Left-facing S+J catches the target to the left")
	demon = get_nodes_in_group("demon_bind_effects")[0]
	check(demon.direction == -1 and demon.sprite.scale.x < 0,"Training ninja mirrors the casting direction when target has no facing")
	await reset()
	actor.position.x = 1035
	check(actor.find_bind_target() == null,"Targets behind the caster are not selected")
	check(actor.start_action("DEMON_BIND") and actor.energy == 75,"A missed cast still pays its normal mana cost")
	await frames(75)
	check(not target.is_movement_locked() and get_nodes_in_group("demon_bind_effects").is_empty(),"Missed demon cleans itself up without a false lock")
	await reset()
	actor.position.x = 75
	check(actor.find_bind_target() == null,"Targets outside the 620px range are not selected")
	actor.position.x = 360
	target.position.y = 280
	check(actor.find_bind_target() == null,"Large vertical separation cannot be targeted")
	target.position.y = 508

	await reset()
	var moving := MovingTarget.new()
	moving.position = Vector2(700,586)
	stage.add_child(moving)
	await frames(2)
	check(actor.find_bind_target() == moving,"Nearest valid forward actor wins target selection")
	var moving_start: float = moving.position.x
	actor.start_action("DEMON_BIND")
	check(await until_locked(moving),"The demon can catch an actually moving AI body")
	check(moving.position.x > moving_start,"AI continues moving during the spirit's flight")
	anchor = moving.global_position
	await frames(30)
	check(moving.global_position == anchor and moving.velocity == Vector2.ZERO,"Shared lock pins position even when AI tries moving every physics tick")
	Input.action_press("move_left")
	var caster_x: float = actor.position.x
	await frames(7)
	Input.action_release("move_left")
	check(actor.position.x < caster_x and moving.global_position == anchor,"Only the victim is immobilized; caster gameplay continues")
	await frames(8)
	check(not moving.is_movement_locked() and moving.position.x > anchor.x,"AI resumes movement after 0.7 seconds")
	moving.queue_free()
	await frames(2)

	await reset()
	actor.start_action("DEMON_BIND")
	await until_locked(target)
	var first_demon: Node2D = get_nodes_in_group("demon_bind_effects")[0]
	await frames(8)
	check(actor.start_action("DEMON_BIND"),"Recovered caster can use a second paid bind")
	for _i in range(80):
		await frames(1)
		var arrived: bool = false
		for effect: Node in get_nodes_in_group("demon_bind_effects"):
			arrived = arrived or (effect != first_demon and effect.phase == "HOLD")
		if arrived:
			break
	var holders: int = 0
	for effect: Node in get_nodes_in_group("demon_bind_effects"):
		if effect.phase == "HOLD":
			holders += 1
	check(holders == 1 and target.movement_lock.remaining <= 0.7,"Refreshing leaves one holding demon and a fresh 0.7-second status")
	remaining = target.movement_lock.remaining
	target.take_hit(8,"PUNCH")
	check(target.health == 92 and target.movement_lock.remaining == remaining,"Follow-up damage neither cancels nor extends the lock")
	await frames(60)
	check(not target.is_movement_locked() and get_nodes_in_group("demon_bind_effects").is_empty(),"Both replaced and refreshed spirits clean up after the last release")
	await reset()
	actor.start_action("PUNCH")
	actor.start_action("PUNCH")
	check(actor.apply_movement_lock(0.7),"Fighter exposes the same reusable bind interface")
	check(actor.combo_step == 0 and actor.combo_buffer == 0,"Being bound cancels the fighter's queued combo")
	anchor = actor.global_position
	Input.action_press("move_right")
	Input.action_press("run")
	Input.action_press("jump")
	Input.action_press("punch")
	await frames(20)
	check(actor.position == anchor and actor.velocity == Vector2.ZERO and actor.state_name == "BOUND","Bound fighter cannot walk, run, jump or attack")
	check(not actor.start_action("SPECIAL") and not actor._start_blink(1),"Direct action APIs also respect the lock")
	Input.action_release("run")
	Input.action_release("jump")
	Input.action_release("punch")
	await frames(26)
	check(not actor.is_movement_locked() and actor.position.x > anchor.x,"Fighter movement resumes when the status expires")
	check(actor.is_on_floor() and actor.action_name == "","Inputs pressed during a bind are not replayed as jumps or attacks")
	Input.action_release("move_right")
	await reset()
	actor.start_action("DEMON_BIND")
	await frames(20)
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	target.reset_target()
	await frames(70)
	check(not target.is_movement_locked() and get_nodes_in_group("demon_bind_effects").is_empty(),"Reset during flight cancels the impending catch")
	await reset()
	actor.start_action("DEMON_BIND")
	await until_locked(target)
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	await frames(2)
	check(not target.is_movement_locked() and get_nodes_in_group("demon_bind_effects").is_empty(),"Reset while holding clears the lock and visual together")
	await reset()
	moving = MovingTarget.new()
	moving.position = Vector2(700,586)
	stage.add_child(moving)
	await frames(2)
	actor.start_action("DEMON_BIND")
	await frames(20)
	moving.queue_free()
	await frames(70)
	check(get_nodes_in_group("demon_bind_effects").is_empty() and not target.is_movement_locked(),"Removing a target in flight causes a safe miss and cleanup")
	stage.queue_free()
	await frames(2)
	check(get_nodes_in_group("movement_locks").is_empty() and get_nodes_in_group("demon_bind_effects").is_empty(),"Stage exit leaves no status or demon nodes")
	print("DEMON BIND RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
