extends SceneTree
var checks: int = 0
var failures: int = 0
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter
var starts: Array[String] = []

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

func tap(command: String) -> void:
	Input.action_press(command)
	await frames(2)
	Input.action_release(command)
	await frames(2)

func setup() -> void:
	for command: StringName in InputMap.get_actions():
		Input.action_release(command)
	stage.restart_match()
	stage.p1.energy = 100
	stage.p2.energy = 100
	stage.phase = "FIGHT"
	a.controls_enabled = true
	b.controls_enabled = true
	starts.clear()
	await frames(5)

func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	stage.round_health = 100 # Original damage/KO fixture; production defaults are covered separately.
	root.add_child(stage)
	await frames(6)
	a = stage.p1
	b = stage.p2
	b.attack_started.connect(func(action: String) -> void: starts.append(action))
	check(not b.red_awakened and not b.start_action("ULTIMATE"),"Ready countdown rejects Red Cap ultimate")
	await setup()
	var keys: Array[int] = []
	for binding: InputEvent in InputMap.action_get_events("p2_ultimate"):
		if binding is InputEventKey:
			keys.append(binding.physical_keycode)
	check(KEY_KP_5 in keys and KEY_SEMICOLON in keys,"P2 has numpad5 and semicolon ultimate keys")
	check(not b.specials_enabled and not b._start_blink(-1),"Capped form does not borrow PHUZASHI special powers")
	for mp: float in [0.0,25.0,69.0,69.9]:
		b.energy = mp
		check(not b.start_action("ULTIMATE") and b.energy == mp and not b.red_awakened,"Requires 70 MP: "+str(mp))
	await setup()
	Input.action_press("p2_guard")
	check(not b.start_action("ULTIMATE") and b.energy == 100,"Guard blocks transformation without MP loss")
	Input.action_release("p2_guard")
	Input.action_press("p2_crouch")
	check(not b.start_action("ULTIMATE") and b.energy == 100,"Crouch blocks transformation without MP loss")
	Input.action_release("p2_crouch")
	await tap("p2_jump")
	check(not b.start_action("ULTIMATE") and b.energy == 100,"Airborne transformation is rejected")
	await setup()
	b.apply_movement_lock(0.7)
	check(not b.start_action("ULTIMATE") and b.energy == 100,"Movement lock blocks transformation")
	await setup()
	b.start_action("PUNCH")
	check(not b.start_action("ULTIMATE") and b.energy == 100,"Active normal attack cannot be replaced by transformation")
	await setup()
	Input.action_press("p2_ultimate")
	await frames(2)
	check(b.action_name == "TRANSFORM" and not b.red_awakened and b.energy == 30,"P2 ultimate input starts transformation and charges exactly 70 MP")
	check(starts == ["TRANSFORM"] and b.action_duration == 3.2,"One transformation action uses the full authored sequence")
	check(b.red_transform_phase() == "CAP OFF","Animation starts by removing the cap")
	check(b.rig.draft_animation.animation == "TRANSFORM" and b.rig.draft_animation.sprite_frames.get_frame_count("TRANSFORM") == 16,"Sixteen transformation drawings are used in gameplay")
	var origin: Vector2 = b.position
	Input.action_press("p2_move_left")
	Input.action_press("p2_jump")
	Input.action_press("p2_punch")
	await frames(70)
	check(b.red_transform_phase() == "BLACK SOY SAUCE" and b.rig.draft_animation.frame in [5,6,7,8,9],"Hat removal is followed by the visible black-soy-bottle phase")
	check(b.position.distance_to(origin) < 0.1 and starts == ["TRANSFORM"],"Transformation locks movement, jump and normal attack buffering")
	check(b.energy == 30,"Mana regeneration waits until the sequence finishes")
	Input.action_release("p2_move_left")
	Input.action_release("p2_jump")
	Input.action_release("p2_punch")
	stage.paused = true
	paused = true
	var frozen: float = b.action_timer
	var frozen_frame: int = b.rig.draft_animation.frame
	for _i in range(8):
		await process_frame
	check(b.action_timer == frozen and b.rig.draft_animation.frame == frozen_frame,"Pause freezes transformation and its visible drawing")
	paused = false
	stage.paused = false
	await frames(65)
	check(b.red_transform_phase() == "SHIRT OFF" and not b.red_awakened,"Sauce is followed by shirt removal before form commit")
	check(a.health == 100 and a.energy == 100,"Transformation neither damages nor spends the other player's MP")
	await frames(70)
	Input.action_release("p2_ultimate")
	check(b.red_awakened and b.rig.red_awakened and b.action_timer == 0,"Completion switches to the bald shirtless body")
	check(starts == ["TRANSFORM"] and b.energy == 30,"Holding ultimate cannot trigger it twice")
	check(not b.specials_enabled and not b.purple_fist.active,"New form does not borrow PHUZASHI powers")
	var sprite: AnimatedSprite2D = b.rig.draft_animation
	var count: int = 0
	for clip: StringName in sprite.AWAKENED_FRAMES.get_animation_names():
		var valid: bool = sprite.AWAKENED_FRAMES.get_frame_count(clip) == 8
		for index in range(8):
			var atlas: AtlasTexture = sprite.AWAKENED_FRAMES.get_frame_texture(clip,index)
			valid = valid and str(atlas.get_meta("original_source",atlas.atlas.resource_path)).contains("/red_awakened/")
			count += 1
		check(valid,"Own complete awakened drawings: "+clip)
	check(count == 112,"Completed form has 112 unique full-body normal drawings")
	for clip: String in ["AIR_PUNCH","AIR_KICK","BOUND"]:
		var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(clip,4)
		check(str(atlas.get_meta("original_source",atlas.atlas.resource_path)).contains("/red_awakened/"),"Awakened artwork also persists for "+clip)
	b.energy = 100
	check(not b.start_action("ULTIMATE") and b.energy == 100,"Already-awakened form cannot consume another 70 MP")
	b.position.x = 750
	a.position.x = 640
	await frames(5)
	for _i in range(3):
		await tap("p2_punch")
	await frames(110)
	check(a.damage_taken == 34 and b.red_awakened,"Awakened punch combo keeps all three stages and 34 damage")
	a.reset_training()
	a.energy = 100 # Explicit full-mana combat fixture.
	a.position.x = 640
	b.position.x = 750
	await frames(5)
	for _i in range(3):
		await tap("p2_kick")
	await frames(110)
	check(a.damage_taken == 52 and b.red_awakened,"Awakened kick combo keeps all three stages and 52 damage")
	check(get_nodes_in_group("purple_punch_impacts").is_empty(),"Awakened normal finishers create no PHUZASHI purple impacts")
	a.reset_training()
	a.energy = 100 # Explicit full-mana combat fixture.
	a.position.x = 640
	b.position.x = 750
	await frames(5)
	await tap("p2_jump")
	await tap("p2_kick")
	await frames(13)
	check(a.damage_taken == 15 and sprite.animation == "AIR_KICK" and b.red_awakened,"New form can jump-kick with its own body")
	await frames(50)
	check(b.is_on_floor() and b.red_awakened,"Landing preserves the completed form")
	b.receive_attack(8,"PUNCH",a)
	await frames(4)
	check(sprite.animation == "HIT" and b.red_awakened,"Getting hit after completion preserves bald shirtless form")
	await frames(35)
	b.apply_movement_lock(0.7)
	await frames(4)
	check(sprite.animation == "BOUND" and b.red_awakened,"Being bound after completion keeps the new body")
	await frames(45)
	b.health = 0
	await frames(4)
	check(b.red_awakened and sprite.animation == "FALL","KO uses the shirtless fallen body until the round resets")
	await setup()
	check(not b.red_awakened and not b.rig.red_awakened and b.energy == 100,"Next round restores cap, shirt and full MP")
	b.start_action("ULTIMATE")
	await frames(30)
	a.position.x = b.position.x-110
	await frames(3)
	a.start_action("PUNCH")
	await frames(18)
	check(b.health == 92 and b.action_name == "HIT" and not b.red_awakened,"A real opponent punch can interrupt the transformation")
	await frames(210)
	check(not b.red_awakened and b.energy < 100 and b.rig.draft_animation.sprite_frames.has_animation("TRANSFORM"),"Interrupted transformation never commits or refunds the spent mana")
	await setup()
	b.start_action("ULTIMATE")
	await frames(90)
	b.apply_movement_lock(0.7)
	await frames(210)
	check(not b.red_awakened and b.action_name != "TRANSFORM","Demon-style immobilization cancels the unfinished transformation")
	await setup()
	b.start_action("ULTIMATE")
	await frames(90)
	stage.restart_match()
	stage.p1.energy = 100
	stage.p2.energy = 100
	await frames(210)
	check(not b.red_awakened and b.energy == 100 and b.action_name != "TRANSFORM","R/reset cancels pending transformation and clears its body state")
	await setup()
	b.start_action("ULTIMATE")
	await frames(90)
	a.health = 0
	await frames(4)
	check(stage.phase == "ROUND_OVER" and not b.red_awakened,"Round settlement cannot complete a partly finished transformation")
	await frames(210)
	check(not b.red_awakened and b.energy == 50,"Automatic next round starts capped with 50 MP")
	stage.queue_free()
	await frames(3)
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	b = stage.phuzashi
	b.select_fighter("RED_CAP")
	b.energy = 100 # Explicit solo transformation fixture.
	await frames(5)
	await tap("red_ultimate")
	check(b.action_name == "TRANSFORM","Solo training O key uses Red Cap's own ultimate")
	await frames(210)
	check(b.red_awakened,"Solo training completes the same transformation")
	b.select_fighter("PHUZASHI")
	await frames(5)
	check(not b.red_awakened and not b.rig.red_awakened and b.display_name == "PHUZASHI" and b.specials_enabled,"Switching fighters resets the form without corrupting PHUZASHI")
	b.energy = 100 # Explicit Fino cost fixture.
	check(b.start_action("ULTIMATE") and is_equal_approx(b.energy,40),"PHUZASHI retains the 60-MP Fino ultimate")
	stage.queue_free()
	await frames(3)
	check(get_nodes_in_group("bind_targets").is_empty(),"Scene exit frees all form actors")
	print("RED TRANSFORM RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
