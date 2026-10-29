extends SceneTree
## Real physics/input verifies profile isolation, normal combat and switching.
var checks: int = 0
var failures: int = 0
var stage: Node2D
var actor: PhuzashiCharacter
var target: Area2D
var started: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS " + label)
	else:
		failures += 1
		push_error("FAIL " + label)

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	# Godot 4.2 headless does not dispatch parsed key events into Viewport._input.
	if DisplayServer.get_name() == "headless":
		stage._input(event)
	else:
		Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	if DisplayServer.get_name() == "headless":
		stage._input(event)
	else:
		Input.parse_input_event(event)
	await frames(2)

func reset(left: bool = false) -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	actor.reset_training()
	target.reset_target()
	actor.position.x = 1035.0 if left else 820.0
	actor.facing = -1 if left else 1
	started.clear()
	await frames(4)

func run() -> void:
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	actor = stage.get_node("PHUZASHI")
	target = stage.get_node("TrainingCrystal")
	actor.attack_started.connect(func(action: String) -> void: started.append(action))
	check(actor.specials_enabled and actor.fighter_profile == "PHUZASHI","Original fighter remains default")
	await key(KEY_TAB)
	check(actor.fighter_profile == "RED_CAP" and actor.display_name == "ASSJIRO" and not actor.specials_enabled,"Tab selects the Red Cap normal-moves profile")
	check(stage.SEQUENCE == stage.NORMAL_SEQUENCE,"Red Cap demo excludes all special skills")
	var bodies: int = 0
	for child: Node in stage.get_children():
		if child is CharacterBody2D:
			bodies += 1
	check(bodies == 1,"Selection retains exactly one playable fighter")
	var sprite: AnimatedSprite2D = actor.rig.draft_animation
	var drawings: int = 0
	for clip: StringName in sprite.RED_FRAMES.get_animation_names():
		var valid: bool = sprite.RED_FRAMES.get_frame_count(clip) == 8
		for index in range(8):
			var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(clip,index)
			valid = valid and atlas.atlas.resource_path.begins_with("res://assets/characters/red_cap/")
			valid = valid and atlas.region.size.x > 50 and atlas.region.size.y > 50
			valid = valid and is_equal_approx(atlas.margin.position.y+atlas.region.size.y,960.0)
			drawings += 1
		check(valid,"Own eight complete drawings and common floor pivot: "+clip)
	check(drawings == 112,"Fourteen ordinary clips contain 112 new drawings")
	for clip: String in ["AIR_PUNCH","AIR_KICK","BOUND"]:
		var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(clip,4)
		check(sprite.sprite_frames.get_frame_count(clip) == 8 and atlas.atlas.resource_path.contains("/red_cap/"),"Own artwork also used by "+clip)
	for clip: String in ["SPECIAL","ULTIMATE","DEMON_BIND","BLINK"]:
		check(not sprite.sprite_frames.has_animation(clip),"No borrowed special animation: "+clip)
	actor.rig.set_draft_enabled(false)
	await frames(2)
	check(actor.rig.use_draft_spritesheet and sprite.visible and not actor.rig.skin.visible,"F4 cannot reveal the PHUZASHI master on Red Cap")
	await key(KEY_F4)
	check(sprite.visible and not actor.rig.skin.visible,"Actual F4 key keeps Red Cap intact")
	await reset()
	actor.position.x = 500
	Input.action_press("move_left")
	await frames(18)
	check(actor.state_name == "WALK" and actor.facing == -1 and actor.velocity.x < -180,"Walk and facing use normal controls")
	Input.action_press("run")
	await frames(14)
	check(actor.state_name == "RUN" and actor.velocity.x < -330,"Shift enables normal run speed")
	await reset()
	Input.action_press("crouch")
	await frames(35)
	check(actor.state_name == "CROUCH" and actor.body_shape.shape.size.y == 84,"Crouch lowers the physical hurtbox")
	check(sprite.animation == "CROUCH" and sprite.frame == 7,"Crouch holds the low final drawing")
	await reset()
	Input.action_press("guard")
	await frames(35)
	actor.receive_training_hit(false)
	check(actor.health == 98 and sprite.animation == "GUARD" and sprite.frame == 7,"Guard holds its pose and absorbs a hit")
	await reset()
	actor.receive_training_hit(false)
	await frames(3)
	check(sprite.animation == "HIT" and actor.health == 92,"Hit reaction plays own artwork")
	await frames(35)
	check(actor.state_name == "IDLE","Light hit recovers normally")
	actor.receive_training_hit(true)
	await frames(60)
	check(sprite.animation == "FALL" and actor.health == 74,"Knockdown plays own full-body fall")
	await frames(35)
	check(actor.state_name == "IDLE","Knockdown recovers without sticking")
	for left: bool in [false,true]:
		for family: String in ["PUNCH","KICK"]:
			await reset(left)
			for _i in range(3):
				await tap(family.to_lower())
			await frames(110)
			check(started == [family,family+"_2",family+"_3"],"Three distinct ordered %s stages (left=%s)" % [family,left])
			check(target.hit_count == 3 and target.total_damage == (34 if family == "PUNCH" else 52),"Same three-hit %s damage (left=%s)" % [family,left])
			check(actor.energy == 100 and not actor.purple_fist.active and get_nodes_in_group("purple_punch_impacts").is_empty(),"Ordinary finisher has no borrowed purple power")
			await reset(left)
			await tap("jump")
			await tap(family.to_lower())
			check(actor.is_air_attack() and sprite.animation == "AIR_"+family,"Air %s uses own drawing (left=%s)" % [family,left])
			await frames(13)
			check(target.hit_count == 1 and target.last_damage == (9 if family == "PUNCH" else 15),"Air %s hits once (left=%s)" % [family,left])
			await frames(50)
			check(actor.is_on_floor() and actor.state_name == "IDLE","Air attack lands and releases normally")
	await reset()
	actor.energy = 0
	for action: String in ["SPECIAL","DEMON_BIND"]:
		check(not actor.start_action(action) and actor.energy == 0,"Carrot skill rejects insufficient MP: "+action)
	actor.energy = 99.0
	check(not actor.start_action("ULTIMATE") and actor.energy == 99.0,"Cap Off requires the full 100 MP")
	actor.energy = 100.0
	check(not actor._start_blink(1) and actor.energy == 100,"Red Cap cannot borrow Shadow Blink")
	actor.energy = 0
	await tap("special")
	await tap("ultimate")
	Input.action_press("crouch")
	await tap("punch")
	Input.action_release("crouch")
	await frames(40)
	actor.energy = 100
	check(started.is_empty() and actor.energy == 100 and target.hit_count == 0,"Underfunded U/I and S+J do not cast or borrow skills")
	check(get_nodes_in_group("demon_bind_effects").is_empty() and get_nodes_in_group("dark_pulses").is_empty() and get_nodes_in_group("shadow_blink_effects").is_empty(),"Rejected skills create no world effects")
	await tap("move_right")
	await tap("move_right")
	check(actor.blink_timer == 0 and actor.energy == 100,"Double-tap movement remains ordinary movement")
	await reset()
	actor.visited = {"IDLE":true}
	stage.showcase = true
	stage.showcase_clock = 1000
	for move: String in stage.NORMAL_SEQUENCE:
		stage._release_demo()
		actor.reset_training()
		actor.position.x = 800
		await frames(3)
		stage._demonstrate(move)
		await frames(145)
	stage.set_showcase(false)
	check(actor.visited.size() == 16,"Normal demo covers all sixteen playable movement/combat states")
	check(not actor.visited.has("SPECIAL") and not actor.visited.has("BLINK") and not actor.visited.has("DEMON_BIND"),"Normal demo never enters a special state")
	await key(KEY_ESCAPE)
	await key(KEY_TAB)
	check(stage.paused and actor.fighter_profile == "RED_CAP","Tab cannot change profile while paused")
	await key(KEY_ESCAPE)
	await reset()
	for _i in range(3):
		actor.start_action("PUNCH")
	await key(KEY_TAB)
	await key(KEY_TAB)
	check(actor.fighter_profile == "PHUZASHI" and actor.specials_enabled and actor.combo_buffer == 0 and actor.action_timer == 0,"Switch during a combo cancels queued attacks and restores PHUZASHI")
	check(stage.SEQUENCE == stage.PHUZASHI_SEQUENCE and actor.rig.draft_animation.sprite_frames.has_animation("DEMON_BIND"),"Switch restores original demo and full powers")
	await frames(5)
	check(actor.start_action("SPECIAL"),"Original Dark Pulse still works after switching back")
	await frames(32)
	check(not get_nodes_in_group("dark_pulses").is_empty(),"Original skill still creates its real projectile")
	await key(KEY_TAB)
	check(actor.fighter_profile == "RED_CAP" and get_nodes_in_group("dark_pulses").is_empty() and actor.energy == 100,"Switch clears old character effects and resets meters")
	check(not actor.select_fighter("UNKNOWN") and actor.fighter_profile == "RED_CAP","Invalid selection cannot corrupt current profile")
	stage.queue_free()
	await frames(2)
	print("RED CAP RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
