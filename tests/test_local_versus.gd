extends SceneTree
## Actual independent inputs, damage queries, status/VFX and round settlement.
var checks: int = 0
var failures: int = 0
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter

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

func release() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func setup(left: bool = false, close: bool = true) -> void:
	release()
	stage.restart_match()
	stage.phase = "FIGHT"
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = (750 if left else 640) if close else 300
	b.position.x = (640 if left else 750) if close else 980
	await frames(5)

func event(code: int) -> void:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.keycode = code
	key.pressed = true
	stage._input(key)
	await frames(2)

func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	check(stage.phase == "READY" and not a.controls_enabled and not b.controls_enabled,"Ready countdown gates both players")
	check(a.duel_mode and b.duel_mode and a.input_prefix == "p1_" and b.input_prefix == "p2_","Independent human input channels")
	check(a.opponent == b and b.opponent == a and b.fighter_profile == "RED_CAP","Both characters exist together as opponents")
	check(a.rig.use_clear_model and a.rig.draft_animation.visible and not a.rig.skin.visible,"Approved new PHUZASHI model is active")
	var sprite: AnimatedSprite2D = a.rig.draft_animation
	var count: int = 0
	for clip: StringName in sprite.CLEAR_FRAMES.get_animation_names():
		var valid: bool = sprite.CLEAR_FRAMES.get_frame_count(clip) == 8
		for index in range(8):
			var atlas: AtlasTexture = sprite.CLEAR_FRAMES.get_frame_texture(clip,index)
			var source: String = atlas.get_meta("original_source",atlas.atlas.resource_path)
			valid = valid and source.contains("/phuzashi_clear/")
			valid = valid and is_equal_approx(atlas.margin.position.y+atlas.region.size.y,960)
			count += 1
		check(valid,"Own complete new body drawings: "+clip)
	var falling: Array = []
	for index in [0,2,4,6]:
		var atlas: AtlasTexture = sprite.CLEAR_FRAMES.get_frame_texture("FALL",index)
		falling.append(atlas.region.size.y)
	check(falling[0] > falling[1] and falling[1] > falling[2] and falling[2] > falling[3],"Fall source ordering progresses from standing through crouch to lying")
	check(count == 128,"All sixteen source clips total 128 new complete drawings")
	check(sprite.sprite_frames.get_frame_count("BLINK") == 12 and sprite.sprite_frames.has_animation("DEMON_BIND"),"Original Blink and Demon Bind poses use the new body")
	for clip: String in ["PUNCH","KICK","AIR_PUNCH","AIR_KICK"]:
		var config: Array = a.ATTACKS[clip]
		check(sprite.frame_at_progress(clip,float(config[3])+0.02) == 3 and sprite.frame_at_progress(clip,float(config[4])-0.02) == 3,"Extended new strike stays aligned to original active window: "+clip)
	check(a.hurt_area.collision_layer == 4 and b.hurt_area.collision_layer == 4,"Both fighters expose real combat hurtboxes")
	await frames(115)
	check(stage.phase == "FIGHT" and a.controls_enabled and b.controls_enabled,"Countdown releases both players")
	await setup(false,false)
	var bx: float = b.position.x
	Input.action_press("p1_move_right")
	await frames(16)
	check(a.velocity.x > 180 and is_equal_approx(b.position.x,bx),"P1 movement does not move P2")
	Input.action_press("p2_move_left")
	await frames(16)
	check(a.velocity.x > 180 and b.velocity.x < -180,"Both players can move simultaneously in opposite directions")
	release()
	await frames(8)
	await tap("p2_jump")
	check(b.velocity.y < 0 and a.is_on_floor(),"P2 jump leaves P1 grounded")
	await frames(50)
	await tap("p1_jump")
	check(a.velocity.y < 0 and b.is_on_floor(),"P1 jump leaves P2 grounded")
	await setup(false,false)
	b.position.x = 850
	await frames(3)
	Input.action_press("p1_crouch")
	Input.action_press("p2_guard")
	await frames(25)
	check(a.state_name == "CROUCH" and b.state_name == "GUARD","Independent crouch and guard at the same time")
	check(a.hurt_area.shape.shape.size.y == 84 and b.hurt_area.shape.shape.size.y == 144,"Real hurtboxes follow each actor's pose")
	for left: bool in [false,true]:
		for attacker: int in [0,1]:
			await setup(left)
			var source: PhuzashiCharacter = a if attacker == 0 else b
			var victim: PhuzashiCharacter = b if attacker == 0 else a
			await tap(source.input_prefix+"punch")
			await frames(35)
			check(victim.health == 92 and source.health == 100,"Punch hurts opponent only, P%d left=%s" % [attacker+1,left])
			check(victim.last_received == "PUNCH" and victim.damage_taken == 8,"One damage event per punch")
			await setup(left)
			await tap(source.input_prefix+"kick")
			await frames(45)
			check(victim.health == 86 and source.health == 100,"Kick hurts opponent only, P%d left=%s" % [attacker+1,left])
			await setup(left)
			Input.action_press(victim.input_prefix+"guard")
			await frames(4)
			await tap(source.input_prefix+"punch")
			await frames(35)
			check(victim.health == 98 and victim.state_name == "GUARD","Facing guard absorbs a real punch")
			await setup(left)
			for _i in range(3):
				await tap(source.input_prefix+"punch")
			await frames(100)
			check(victim.damage_taken == 34 and victim.health == 66,"Three-stage punch combo retains 34 damage")
			await setup(left)
			for _i in range(3):
				await tap(source.input_prefix+"kick")
			await frames(100)
			check(victim.damage_taken == 52 and victim.health == 48,"Three-stage kick combo retains 52 damage")
	await setup()
	await tap("p1_jump")
	await tap("p1_punch")
	await frames(13)
	check(b.damage_taken == 9 and a.is_air_attack(),"New body aerial punch damages the other player")
	await setup()
	await tap("p2_jump")
	await tap("p2_kick")
	await frames(13)
	check(a.damage_taken == 15 and b.is_air_attack(),"Red Cap aerial kick damages the other player")
	await setup(false,false)
	check(a.start_action("SPECIAL"),"Original projectile skill is available")
	check(is_equal_approx(a.energy,75),"Original Dark Pulse costs 25 MP")
	await frames(110)
	check(b.health == 76 and a.health == 100 and b.damage_taken == 24,"Projectile hits the real opponent exactly once and ignores its owner")
	await setup()
	check(a.start_action("ULTIMATE") and is_equal_approx(a.energy,40),"Original dragon ultimate costs 60 MP")
	await frames(100)
	check(b.health == 40 and a.health == 100,"Original ultimate hits opponent once for 60 damage")
	await setup(false,false)
	b.position.x = 850
	await frames(3)
	Input.action_press("p1_crouch")
	await tap("p1_punch")
	Input.action_release("p1_crouch")
	check(a.action_name == "DEMON_BIND" and a.energy < 77,"P1 S+J activates original 25-MP Demon Bind")
	await frames(35)
	check(b.is_movement_locked() and not a.is_movement_locked(),"Demon locks P2 rather than its caster")
	var pinned: Vector2 = b.position
	Input.action_press("p2_move_left")
	Input.action_press("p2_jump")
	Input.action_press("p2_punch")
	await frames(12)
	check(b.position.distance_to(pinned) < 0.1 and b.state_name == "BOUND" and b.action_timer == 0,"Locked P2 cannot move, jump or attack")
	release()
	await frames(40)
	check(not b.is_movement_locked() and b.health == 100,"Bind expires automatically and adds no damage")
	Input.action_press("p2_move_left")
	await frames(3)
	check(b.velocity.x < 0 and b.position.x < pinned.x,"P2 input resumes after the 0.7-second lock")
	Input.action_release("p2_move_left")
	await setup()
	check(a._start_blink(1),"P1 keeps original Shadow Blink")
	await frames(14)
	check(a.blink_invulnerable(),"Blink keeps its original invulnerable window")
	check(a.receive_attack(14,"KICK",b) < 0 and a.health == 100,"Opponent cannot damage an invulnerable Blink")
	check(not b._start_blink(-1) and not b.specials_enabled,"Red Cap cannot borrow PHUZASHI blink or purple effects")
	await setup()
	for _i in range(3):
		a.start_action("PUNCH")
	for _i in range(80):
		await frames(1)
		if a.action_name == "PUNCH_3" and a.action_progress() >= 0.36:
			break
	check(a.purple_fist.active and sprite.animation == "PUNCH_3","Original purple fist activates on the new uppercut")
	check(a.purple_fist.to_global(a.purple_fist.hand).distance_to(sprite.combo_fist_global_position()) < 1,"Purple fist follows the new body's fist marker")
	await event(KEY_ESCAPE)
	var timer: float = stage.remaining
	var attack_timer: float = a.action_timer
	await frames(8)
	check(stage.remaining == timer and a.action_timer == attack_timer,"Pause freezes round clock and both fighters")
	await event(KEY_ESCAPE)
	await setup()
	stage.remaining = 0.01
	a.health = 70
	b.health = 50
	await frames(4)
	check(stage.phase == "ROUND_OVER" and stage.scores == [1,0] and stage.winner == 0,"Timeout awards the round to higher remaining HP")
	check(not a.start_action("PUNCH") and not b.start_action("KICK"),"Round results block both players' attacks")
	await frames(185)
	check(stage.phase == "READY" and stage.round_number == 2 and a.health == 100 and b.health == 100,"Next round resets bodies and preserves match score")
	stage.phase = "FIGHT"
	a.controls_enabled = true
	b.controls_enabled = true
	b.health = 0
	await frames(4)
	check(stage.phase == "MATCH_OVER" and stage.scores == [2,0],"First to two wins settles the match")
	await frames(100)
	check(stage.scores == [2,0] and b.state_name == "FALL","KO stays down and cannot award duplicate rounds")
	await event(KEY_R)
	check(stage.phase == "READY" and stage.scores == [0,0] and stage.round_number == 1,"R starts a fresh match")
	await setup()
	a.health = 0
	b.health = 0
	await frames(4)
	check(stage.winner == -1 and stage.scores == [0,0] and stage.result == "DRAW","Simultaneous KO is a draw")
	await setup()
	Input.action_press("p1_move_right")
	Input.action_press("p2_move_left")
	stage._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames(3)
	check(stage.paused and not Input.is_action_pressed("p1_move_right") and not Input.is_action_pressed("p2_move_left"),"Focus loss pauses and releases both players' held keys")
	await event(KEY_R)
	stage.queue_free()
	await frames(2)
	check(get_nodes_in_group("bind_targets").is_empty() and get_nodes_in_group("dark_pulses").is_empty(),"Scene exit frees both fighters and all projectiles")
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(5)
	await event(KEY_F6)
	await frames(6)
	var training: Node2D = current_scene
	check(training.name == "TrainingGround","F6 opens solo training")
	check(training.phuzashi.rig.use_clear_model,"Training entered from versus uses the new approved model")
	var navigation := InputEventKey.new()
	navigation.physical_keycode = KEY_F6
	navigation.pressed = true
	training._input(navigation)
	await frames(8)
	stage = current_scene
	check(stage.name == "SchoolVersus" and stage.p1.rig.use_clear_model and stage.p2.fighter_profile == "RED_CAP","F6 returns to the school with both correct characters")
	stage.queue_free()
	await frames(3)
	check(get_nodes_in_group("bind_targets").is_empty(),"Navigation does not leave old fighters behind")
	print("LOCAL VERSUS RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
