extends SceneTree
## Real input, physics, hit queries and interruption tests for air/chain attacks.
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

func reset(left: bool = false) -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	target.reset_target()
	actor.position.x = 1035.0 if left else 820.0
	actor.facing = -1 if left else 1
	started.clear()
	await frames(4)

func on_attack(action: String) -> void:
	started.append(action)

func run() -> void:
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	actor = stage.get_node("PHUZASHI")
	actor.energy = 100 # Explicit full-mana combat fixture.
	target = stage.get_node("TrainingCrystal")
	actor.attack_started.connect(on_attack)
	var sprite: AnimatedSprite2D = actor.rig.draft_animation
	for clip: String in sprite.EXTRA_CLIPS:
		check(sprite.sprite_frames.has_animation(clip) and sprite.sprite_frames.get_frame_count(clip) == 8, "Complete approved animation exists: " + clip)
		var source: String = sprite.EXTRA_CLIPS[clip]
		var imported: AtlasTexture = sprite.sprite_frames.get_frame_texture(clip,3)
		if sprite.COMBO_FRAMES.has_animation(clip):
			check(imported.atlas.resource_path.begins_with("res://assets/characters/combos/") and imported.atlas != sprite.FRAMES.get_frame_texture(source,3).atlas, "Distinct whole-body drawing is used: " + clip)
		else:
			check(imported.get_image().get_data() == sprite.FRAMES.get_frame_texture(source,3).get_image().get_data(), "Existing aerial body art is unchanged: " + clip)
		var config: Array = actor.ATTACKS[clip]
		var contact_frame: int = sprite.frame_at_progress(clip, float(config[3]) + 0.03)
		var allowed: Array = [4,5] if source == "KICK" and clip != "KICK_2" else [3,4,5]
		check(contact_frame in allowed, "Extended strike drawing matches actual hit timing: " + clip)

	for left: bool in [false, true]:
		for family: String in ["PUNCH", "KICK"]:
			await reset(left)
			var binding: String = family.to_lower()
			await tap(binding)
			await tap(binding)
			await tap(binding)
			check(actor.combo_buffer == 2, "%s buffers both early taps (left=%s)" % [family,left])
			await frames(110)
			check(started == [family, family+"_2", family+"_3"], "%s input starts exactly three ordered attacks (left=%s)" % [family,left])
			check(target.hit_count == 3 and target.combo == 3, "%s hits once per stage (left=%s)" % [family,left])
			check(target.total_damage == (34 if family == "PUNCH" else 52), "%s damage includes all three stages (left=%s)" % [family,left])
			check(actor.action_timer == 0.0 and actor.combo_step == 0 and actor.combo_buffer == 0, "Finisher exits cleanly: %s (left=%s)" % [family,left])
			check(actor.energy == 100.0, "Normal combos do not consume MP")

	await reset()
	Input.action_press("punch")
	await frames(100)
	Input.action_release("punch")
	check(started == ["PUNCH"] and target.hit_count == 1 and target.total_damage == 8, "Holding J performs one punch and never auto-combos")
	await reset()
	await tap("kick")
	await tap("kick")
	await frames(100)
	check(started == ["KICK", "KICK_2"] and target.hit_count == 2 and target.total_damage == 30, "Two taps perform exactly two kicks")
	await reset()
	for _i in range(4):
		await tap("punch")
	await frames(90)
	check(started == ["PUNCH", "PUNCH_2", "PUNCH_3"], "A fourth buffered tap cannot extend the three-hit chain")
	await reset()
	await tap("punch")
	await frames(23)
	check(actor.action_timer == 0.0 and actor.combo_grace > 0.0, "Brief post-recovery continuation window exists")
	await tap("punch")
	check(actor.action_name == "PUNCH_2", "A slightly late second press continues the chain")
	await frames(40)
	await tap("punch")
	check(actor.action_name == "PUNCH" and actor.combo_step == 1, "Waiting beyond the link window starts a new chain")
	await reset()
	await tap("punch")
	await tap("kick")
	await frames(50)
	check(started == ["PUNCH"], "Punch and kick chains do not accidentally mix")

	await reset()
	for _i in range(3):
		await tap("punch")
	actor.receive_training_hit(false)
	check(actor.combo_buffer == 0 and actor.combo_step == 0, "Getting hit clears queued combo inputs")
	await frames(80)
	check(started == ["PUNCH"] and actor.state_name == "IDLE", "Interrupted combo cannot restart after hit-stun")
	await reset()
	for _i in range(3):
		await tap("kick")
	await tap("reset")
	check(actor.combo_step == 0 and actor.combo_buffer == 0 and actor.action_timer == 0, "R cancels the active chain and queued inputs")
	var starts_before: int = started.size()
	await frames(80)
	check(started.size() == starts_before, "Reset cannot replay queued attacks later")
	await reset()
	for _i in range(3):
		await tap("punch")
	var pause_event := InputEventKey.new()
	pause_event.physical_keycode = KEY_ESCAPE
	pause_event.pressed = true
	stage._input(pause_event)
	var frozen: float = actor.action_timer
	await frames(10)
	check(actor.action_timer == frozen and actor.combo_buffer == 2, "Pause freezes attack progress and preserves the two queued inputs")
	stage._input(pause_event)
	await frames(100)
	check(started == ["PUNCH", "PUNCH_2", "PUNCH_3"], "Unpausing completes the queued chain once")

	for left: bool in [false, true]:
		for family: String in ["PUNCH", "KICK"]:
			await reset(left)
			await tap("jump")
			var vertical_before: float = actor.velocity.y
			await tap(family.to_lower())
			check(actor.is_air_attack() and actor.action_name == "AIR_" + family, "Jump+%s selects an aerial attack (left=%s)" % [family,left])
			check(actor.velocity.y < 0.0 and actor.velocity.y > vertical_before and not actor.is_on_floor(), "Air %s preserves ascent and gravity" % family)
			check(sprite.visible and sprite.animation == "AIR_" + family and not actor.rig.skin.visible, "Air %s uses intact spritesheet art" % family)
			check(not actor.start_action("SPECIAL") and not actor.start_action("ULTIMATE"), "Air normals do not unlock grounded special skills")
			await frames(13)
			check(target.hit_count == 1 and target.last_damage == (9 if family == "PUNCH" else 15), "Air %s deals real damage once (left=%s)" % [family,left])
			await frames(50)
			check(actor.is_on_floor() and actor.state_name == "IDLE" and absf(actor.position.y - actor.FLOOR_Y) < 0.1, "Air %s lands without hovering or getting stuck" % family)

	await reset()
	Input.action_press("jump")
	Input.action_press("kick")
	await frames(2)
	Input.action_release("jump")
	Input.action_release("kick")
	check(actor.action_name == "AIR_KICK" and not actor.is_on_floor(), "Space and K pressed on the same frame jump and kick")
	Input.action_press("move_right")
	await frames(8)
	check(actor.velocity.x > 150.0 and actor.velocity.y < 0.0, "Directional control remains available during aerial attacks")
	Input.action_release("move_right")
	await reset()
	Input.action_press("jump")
	Input.action_press("punch")
	await frames(2)
	Input.action_release("jump")
	Input.action_release("punch")
	check(actor.action_name == "AIR_PUNCH" and not actor.is_on_floor(), "Space and J pressed on the same frame jump and punch")
	await reset()
	await tap("jump")
	await frames(34)
	check(not actor.is_on_floor() and actor.velocity.y > 0.0, "Late-air attack setup is descending")
	await tap("kick")
	await frames(12)
	check(actor.is_on_floor() and actor.action_timer == 0.0 and not actor.is_air_attack(), "Landing cancels an unfinished aerial kick immediately")
	await tap("punch")
	check(actor.action_name == "PUNCH" and actor.combo_step == 1 and actor.combo_buffer == 0, "A fresh grounded combo can start immediately after landing")
	await reset()
	check(actor._start_blink(1) and not actor.start_action("PUNCH"), "An attack cannot overlap Shadow Blink")
	await frames(50)
	check(actor.start_action("PUNCH"), "Attacking resumes after Blink")
	stage.queue_free()
	await frames(2)
	print("COMBAT COMBO RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
