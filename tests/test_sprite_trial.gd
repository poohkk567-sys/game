extends SceneTree
var checks: int = 0
var failures: int = 0
var stage: Node2D
var player: PhuzashiCharacter

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ",label)
	else:
		failures += 1
		push_error("FAIL "+label)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func run() -> void:
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	player = stage.get_node("PHUZASHI")
	await frames(5)
	var sprite: AnimatedSprite2D = player.rig.draft_animation
	expect(player.rig.use_draft_spritesheet and sprite.visible and not player.rig.skin.visible,"Main scene defaults to full-body spritesheet animation")
	expect(sprite.animation == "IDLE" and sprite.sprite_frames.get_frame_count("IDLE") == 8,"Idle loads eight full-body frames")
	expect(sprite.sprite_frames.get_frame_count("WALK") == 8,"Walk loads eight full-body frames")
	var initial: int = sprite.frame
	await frames(12)
	expect(sprite.frame != initial,"AnimatedSprite2D advances real frames during idle")
	var anchored: bool = true
	var body_height: float = 0.0
	for animation: String in ["IDLE","WALK"]:
		for i in range(8):
			var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(animation,i)
			anchored = anchored and atlas.get_size() == Vector2(512,384)
			anchored = anchored and absf(atlas.margin.position.y+atlas.region.size.y-360.0)<0.001
			body_height = maxf(body_height,atlas.region.size.y*sprite.scale.y*3.0)
	expect(anchored,"Every atlas frame has a shared canvas and feet baseline")
	expect(absf(body_height-156.0)<0.01,"One uniform scale keeps the maximum body height at 156 pixels")
	Input.action_press("move_right")
	await frames(12)
	expect(player.state_name == "WALK" and sprite.visible and sprite.animation == "WALK","Actual movement selects the walking spritesheet")
	initial = sprite.frame
	await frames(8)
	expect(sprite.frame != initial,"Walk advances its illustrated frames")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(15)
	expect(player.facing == -1 and player.rig.scale.x < 0 and sprite.visible,"Walking left mirrors the complete sprite")
	Input.action_press("run")
	await frames(15)
	expect(player.state_name == "RUN" and sprite.visible and sprite.animation == "RUN" and not player.rig.skin.visible,"Running uses its illustrated animation")
	Input.action_release("run")
	Input.action_release("move_left")
	await frames(15)
	var position_before: Vector2 = player.position
	var toggle := InputEventKey.new()
	toggle.physical_keycode = KEY_F4
	toggle.pressed = true
	stage._input(toggle)
	expect(not player.rig.use_draft_spritesheet and not sprite.visible and player.rig.skin.visible,"F4 compares with the master renderer")
	expect(player.position == position_before and player.health == 100,"Art comparison leaves physics and resources unchanged")
	stage._input(toggle)
	expect(player.rig.use_draft_spritesheet and sprite.visible,"F4 restores the spritesheet")
	player.reset_training()
	await frames(2)
	expect(sprite.visible and sprite.animation == "IDLE","Reset returns to illustrated idle")
	player.start_action("PUNCH")
	await frames(3)
	expect(player.state_name == "PUNCH" and sprite.visible and sprite.animation == "PUNCH" and not player.rig.skin.visible,"Punch uses its illustrated animation")
	await frames(30)
	expect(player.state_name == "IDLE" and sprite.visible,"Combat recovery returns to the spritesheet")
	var pause := InputEventKey.new()
	pause.physical_keycode = KEY_ESCAPE
	pause.pressed = true
	stage._input(pause)
	var paused_frame: int = sprite.frame
	await frames(20)
	expect(sprite.frame == paused_frame,"Pause freezes AnimatedSprite2D playback")
	stage._input(pause)
	# Every gameplay state has eight complete frames, with no clipping in margins.
	for clip: String in player.rig.CLIPS:
		expect(sprite.sprite_frames.has_animation(clip) and sprite.sprite_frames.get_frame_count(clip) == 8,"Eight illustrated frames exist for "+clip)
		var valid: bool = true
		for index in range(8):
			var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(clip,index)
			valid = valid and atlas.margin.position.x >= 0 and atlas.margin.position.y >= 0
			valid = valid and atlas.margin.position.x+atlas.region.size.x <= atlas.get_width()
			valid = valid and absf(atlas.margin.position.y+atlas.region.size.y-360.0)<0.001
		expect(valid,"Full silhouettes fit the common canvas for "+clip)
		var loops: bool = clip in ["IDLE","WALK","RUN"]
		expect(sprite.sprite_frames.get_animation_loop(clip) == loops,"Loop/hold mode matches "+clip)
	# Holding crouch/guard must not restart their stand-to-pose transitions.
	player.reset_training()
	await frames(4)
	for action: String in ["crouch","guard"]:
		Input.action_press(action)
		await frames(40)
		expect(sprite.visible and sprite.animation == action.to_upper() and sprite.frame == 7 and not sprite.is_playing(),"Held "+action+" reaches and holds its final frame")
		await frames(20)
		expect(sprite.frame == 7,"Held "+action+" does not pop back to standing")
		Input.action_release(action)
		await frames(4)
	# Attack visuals and actual hit windows must agree.
	player.reset_training()
	await frames(4)
	for attack: String in ["PUNCH","KICK","SPECIAL","ULTIMATE"]:
		player.energy = 100
		var config: Array = player.ATTACKS[attack]
		expect(player.start_action(attack),"Start illustrated "+attack)
		await frames(roundi(float(config[0])*float(config[3])*60.0)+2)
		expect((player.fino_visual.visible and not player.rig.visible and player.fino_visual.frame >= 5) if attack == "ULTIMATE" else (sprite.visible and sprite.animation == attack and sprite.frame >= 3 and sprite.frame <= 5),"Contact drawing matches the active window for "+attack)
		await frames(ceili(float(config[0])*60.0)+3)
		expect(player.state_name == "IDLE" and sprite.animation == "IDLE","Illustrated "+attack+" completes recovery")
	player.receive_training_hit(false)
	await frames(9)
	expect(sprite.visible and sprite.animation == "HIT" and sprite.frame >= 2,"Hit-stun drives the reaction frames")
	await frames(32)
	player.receive_training_hit(true)
	await frames(40)
	expect(sprite.visible and sprite.animation == "FALL" and sprite.frame in [3,4],"Knockdown displays the horizontal lying frames")
	await frames(50)
	expect(sprite.animation == "IDLE" and player.is_on_floor(),"Get-up animation returns to illustrated idle")
	Input.action_press("jump")
	await frames(4)
	Input.action_release("jump")
	expect(sprite.visible and sprite.animation == "JUMP","Jump displays its illustrated sequence")
	var ascent_frame: int = sprite.frame
	await frames(25)
	expect(sprite.animation == "JUMP" and sprite.frame > ascent_frame,"Jump frames advance with airborne progress")
	await frames(30)
	expect(sprite.animation == "IDLE","Landing returns to illustrated idle")
	stage.queue_free()
	await frames(2)
	print("SPRITE TRIAL RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
