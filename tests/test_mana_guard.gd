extends SceneTree
## Exercise the real fighters, collision queries, resource clocks and round gates.
var checks: int = 0
var failures: int = 0
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS "+label)
	else:
		failures += 1
		push_error("FAIL "+label)

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func release() -> void:
	for command: StringName in InputMap.get_actions():
		Input.action_release(command)

func setup(close: bool = false) -> void:
	release()
	stage.restart_match()
	stage.phase = "FIGHT"
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 640 if close else 300
	b.position.x = 750 if close else 980
	await frames(5)

func held_guard() -> void:
	Input.action_press("p2_guard")
	await frames(12)

func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	stage.round_health = 100 # Original damage/KO fixture; production defaults are covered separately.
	root.add_child(stage)
	await frames(5)
	a = stage.p1
	b = stage.p2
	for prefix: String in ["","p1_","p2_"]:
		check(InputMap.has_action(prefix+"charge"),"Charge action installed: "+prefix)
	a.energy = 0
	Input.action_press("p1_charge")
	await frames(30)
	check(a.energy == 0 and not a.charging,"Ready countdown cannot charge MP")
	await setup()
	a.energy = 10
	b.energy = 20
	await frames(90)
	check(a.energy == 10 and b.energy == 20,"Both fighters have no passive mana regeneration")
	Input.action_press("p1_charge")
	var before: float = a.elapsed
	await frames(60)
	check(absf(a.energy-10-(a.elapsed-before)*7) < 0.001,"P1 charges exactly 7 mana per simulated second")
	check(a.charging and a.state_name == "CHARGE" and a.velocity == Vector2.ZERO,"Charging uses grounded braced pose and locks movement")
	check(b.energy == 20 and not b.charging,"P1 charge never fills P2 mana")
	Input.action_press("p2_charge")
	before = b.elapsed
	await frames(60)
	check(absf(b.energy-20-(b.elapsed-before)*7) < 0.001,"P2 charges independently at the same 7/s rate")
	check(a.charging and b.charging,"Two humans can charge simultaneously")
	a.energy = 99.9
	await frames(10)
	check(a.energy == 100,"Charge clamps MP at 100")
	Input.action_release("p1_charge")
	Input.action_release("p2_charge")
	await frames(2)
	check(not a.charging and not b.charging,"Releasing charge ends both charge poses")
	for command: String in ["move_left","jump","crouch","guard"]:
		await setup()
		a.energy = 0
		Input.action_press("p1_charge")
		Input.action_press("p1_"+command)
		await frames(6)
		check(a.energy == 0 and not a.charging,"Charge cannot overlap "+command)
	await setup()
	a.energy = 0
	a.start_action("PUNCH")
	Input.action_press("p1_charge")
	await frames(12)
	check(not a.charging and a.energy == 0,"Normal attack startup cannot simultaneously charge")
	await setup()
	a.energy = 50
	check(a._start_blink(1),"Blink is still available with sufficient mana")
	Input.action_press("p1_charge")
	await frames(10)
	check(a.energy == 35 and not a.charging,"Blink cannot simultaneously charge or refund its cost")
	await setup()
	a.energy = 0
	a.apply_movement_lock(0.7)
	Input.action_press("p1_charge")
	await frames(25)
	check(a.energy == 0 and not a.charging,"Demon movement lock prevents charge")
	await setup(true)
	b.energy = 0
	Input.action_press("p2_charge")
	await frames(5)
	a.start_action("PUNCH")
	await frames(12)
	check(b.health == 92 and not b.charging and b.action_name == "HIT","Real punch interrupts charging")
	var mana: float = b.energy
	await frames(10)
	check(b.energy == mana,"Hit stun cannot charge while trigger remains held")
	await setup()
	b.energy = 100
	b.start_action("ULTIMATE")
	Input.action_press("p2_charge")
	await frames(60)
	check(b.energy == 0 and not b.charging,"Cap removal transformation cannot charge during its animation")
	await setup(true)
	a.energy = 0
	a.start_action("PUNCH")
	await frames(18)
	check(a.energy == 3 and b.damage_taken == 8,"Actual unguarded punch awards 3 MP")
	await frames(20)
	check(a.energy == 3,"One hit cannot repeatedly award mana throughout its active window")
	await setup()
	a.energy = 0
	a.start_action("KICK")
	await frames(45)
	check(a.energy == 0,"Whiffed kick awards no mana")
	for family: String in ["PUNCH","KICK"]:
		await setup(true)
		a.energy = 0
		for _i in range(3):
			a.start_action(family)
		await frames(100)
		check(a.energy == 11,"Full real three-stage "+family+" combo awards 3+3+5 MP")
		check(b.damage_taken == (34 if family == "PUNCH" else 52),"Mana reward preserves "+family+" combo damage")
	for move: String in ["AIR_PUNCH","AIR_KICK"]:
		await setup(true)
		a.energy = 0
		a.velocity.y = a.JUMP_VELOCITY
		a.start_action(move.trim_prefix("AIR_"))
		await frames(18)
		check(a.energy == 3,"Real aerial normal awards 3 MP: "+move)
	await setup(true)
	a.energy = 30
	a.start_action("SPECIAL")
	await frames(65)
	check(a.energy == 5 and b.damage_taken == 24,"Projectile damage never refunds skill mana")
	await setup(true)
	a.energy = 70
	a.start_action("ULTIMATE")
	await frames(100)
	check(a.energy == 10 and b.damage_taken == 60,"Dragon damage never refunds skill mana")
	await setup(true)
	a.energy = 30
	a.start_action("DEMON_BIND")
	await frames(60)
	check(a.energy == 5,"Demon Bind does not generate mana")
	await setup(true)
	a.energy = 0
	await held_guard()
	a.start_action("PUNCH")
	await frames(35)
	check(a.energy == 0 and b.health == 98 and b.guard_meter == 90,"Blocked punch gives chip and costs 10 guard, no attacker MP")
	var meter: float = b.guard_meter
	await frames(90)
	check(b.guard_meter == meter,"Holding guard does not drain it by itself or regenerate it")
	Input.action_release("p2_guard")
	await frames(30)
	check(b.guard_meter == meter,"Released guard waits a full second before regeneration")
	await frames(60)
	check(is_equal_approx(b.guard_meter,100),"Released guard regenerates 20/s capped at 100")
	for move: String in a.GUARD_COSTS:
		await setup(true)
		await held_guard()
		b.receive_attack(8,move,a)
		check(b.guard_meter == 100-float(a.GUARD_COSTS[move]),"Guard cost for "+move)
	await setup(true)
	a.energy = 0
	b.energy = 0
	a.start_action("PUNCH")
	await frames(7)
	Input.action_press("p2_guard")
	await frames(12)
	check(b.health == 100 and b.guard_meter == 100 and b.energy == 3,"A real collision-timed perfect guard awards defender MP and prevents damage")
	check(a.energy == 0,"Attacker gains no normal-hit mana from a real perfect guard")
	await setup(true)
	await held_guard()
	b.guard_meter = 10
	var blocked_damage: int = b.receive_attack(8,"PUNCH",a)
	check(blocked_damage == 2 and b.guard_meter == 0 and b.action_name == "GUARD_BREAK","Last block breaks guard once and applies only 2 chip")
	check(b.defense_feedback == "GUARD BREAK" and b.action_timer == 1,"Break gives a visible one-second stun")
	check(not b.start_action("PUNCH") and not b.start_action("ULTIMATE"),"Guard break prevents normals and transformation")
	var x: float = b.position.x
	Input.action_press("p2_move_left")
	Input.action_press("p2_jump")
	Input.action_press("p2_charge")
	await frames(20)
	check(b.is_on_floor() and absf(b.position.x-x) < 3 and absf(b.velocity.x) < 1 and not b.charging,"Guard break prevents walking, jumping and charging")
	var remaining_stun: float = b.action_timer
	b.receive_attack(8,"PUNCH",a)
	check(b.health == 90 and b.action_timer <= remaining_stun+0.001,"A follow-up is unblocked and does not shorten or reset guard-break stun")
	await frames(42)
	check(b.guard_meter == 50 and b.action_timer <= 0,"Guard break restores 50 guard after the one-second stun")
	await setup(true)
	await held_guard()
	b.guard_meter = 10
	b.receive_attack(8,"PUNCH",a)
	await frames(6)
	b.apply_movement_lock(0.3)
	check(not b.start_action("PUNCH") and not b.start_action("ULTIMATE"),"A bind cannot cancel guard-break attack restrictions")
	await frames(20)
	Input.action_release("p2_guard")
	Input.action_press("p2_charge")
	Input.action_press("p2_move_left")
	await frames(2)
	check(b.action_name == "GUARD_BREAK" and not b.charging and b.guard_meter == 0,"Break stun resumes for its remaining time after a shorter overlapping bind")
	release()
	await frames(38)
	check(b.guard_meter >= 50 and b.action_timer == 0,"Overlapping bind does not permanently strand the guard meter at zero")
	await setup(true)
	b.energy = 20
	Input.action_press("p2_guard")
	await frames(2)
	check(b.receive_attack(60,"ULTIMATE",a) == 0 and b.health == 100,"Timed perfect guard prevents all HP damage")
	check(b.guard_meter == 100 and b.energy == 23,"Perfect guard consumes zero guard and awards 3 MP")
	check(b.defense_feedback == "PERFECT GUARD" and a.action_timer == 0,"Perfect guard has feedback and no automatic attacker stun")
	b.receive_attack(8,"PUNCH",a)
	check(b.health == 98 and b.energy == 23 and b.guard_meter == 90,"One guard press cannot parry repeated simultaneous attacks")
	await frames(10)
	b.receive_attack(8,"PUNCH",a)
	check(b.health == 96 and b.guard_meter == 80,"Held guard loses its perfect window after 0.12 seconds")
	await setup(true)
	Input.action_press("p2_guard")
	await frames(1)
	a.position.x = b.position.x+60
	b.facing = -1
	check(b.receive_attack(8,"PUNCH",a) == 8 and not b.last_hit_blocked,"Guard and perfect guard cannot block an attack from behind")
	await setup(true)
	await held_guard()
	b.receive_attack(8,"PUNCH",a)
	Input.action_release("p2_guard")
	await frames(40)
	b.receive_attack(8,"PUNCH",a)
	await frames(35)
	check(b.guard_meter == 90,"Taking unguarded damage restarts guard regeneration delay")
	await setup()
	a.energy = 10
	a.guard_meter = 30
	Input.action_press("p1_charge")
	await frames(5)
	stage.toggle_pause()
	var mana_before: float = a.energy
	var guard_before: float = a.guard_meter
	for _i in range(15):
		await process_frame
	check(a.energy == mana_before and a.guard_meter == guard_before,"Pause freezes mana and guard clocks")
	stage.toggle_pause()
	await setup()
	a.health = 0
	Input.action_press("p1_charge")
	await frames(5)
	check(not a.charging and stage.phase == "ROUND_OVER","KO stops charging and settles round")
	stage.restart_match()
	check(a.guard_meter == 100 and b.guard_meter == 100 and a.energy == 100,"Round reset restores MP/guard and clears broken state")
	stage.queue_free()
	await frames(3)
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(5)
	a = stage.phuzashi
	a.energy = 0
	a.position.x = 820
	await frames(3)
	a.start_action("PUNCH")
	await frames(30)
	check(a.energy == 3 and stage.target.hit_count == 1,"Training crystal also awards normal-hit mana once")
	a.energy = 0
	Input.action_press("charge")
	await frames(30)
	check(a.charging and a.energy > 3 and a.energy < 4,"Solo training supports the same 7/s charge")
	release()
	stage.queue_free()
	await frames(3)
	print("MANA GUARD RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
