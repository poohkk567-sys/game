extends SceneTree
## Integration tests run inside Godot against the real scene and physics server.
var failures: int = 0
var checks: int = 0
var stage: Node2D
var player: PhuzashiCharacter
var target: Area2D

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(1)

func reset() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)
	player.reset_training()
	target.reset_target()
	await frames(3)

func run() -> void:
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	player = stage.get_node("PHUZASHI")
	target = stage.get_node("TrainingCrystal")
	await frames(6)
	expect(player.is_on_floor(), "Main scene loads with a grounded fighter")
	expect(absf(player.position.y - 586.0) < 0.1, "Physics floor matches artwork exactly")
	expect(FileAccess.get_sha256("res://assets/characters/PHUZASHI_MASTER_SHOES_APPROVED.png") == "d0d6156d5114d612c1d04e39781fcd5c783eb09b0ba1268fc8b42c9779e6be06", "Approved master remains byte-identical")
	_test_original_pixels()
	_test_mountains()

	Input.action_press("move_right")
	await frames(35)
	expect(player.state_name == "WALK" and player.velocity.x > 185, "Walking reaches configured speed")
	var walking: float = player.velocity.x
	Input.action_press("run")
	await frames(15)
	expect(player.state_name == "RUN" and player.velocity.x > walking * 1.6, "Running is faster than walking")
	Input.action_release("run")
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(20)
	expect(player.facing == -1 and player.rig.scale.x < 0, "Fighter turns and mirrors toward left")
	await frames(180)
	expect(player.position.x >= 75, "Left arena boundary contains fighter")
	Input.action_release("move_left")
	Input.action_press("move_right")
	Input.action_press("run")
	await frames(240)
	expect(player.position.x <= 1205, "Right arena boundary contains fighter")
	await reset()

	await tap("jump")
	expect(not player.is_on_floor() and player.state_name == "JUMP", "Jump input launches fighter")
	await frames(14)
	var before_second_jump: float = player.velocity.y
	await tap("jump")
	expect(player.velocity.y > before_second_jump, "Airborne jump input cannot create a double jump")
	expect(player.position.y < 500, "Jump gains meaningful height")
	await frames(55)
	expect(player.is_on_floor() and absf(player.position.y - 586) < 0.1, "Jump returns to ground without sinking")
	await reset()

	Input.action_press("crouch")
	Input.action_press("move_right")
	await frames(18)
	expect(player.state_name == "CROUCH" and player.body_shape.shape.size.y == 84, "Crouching lowers the physics shape")
	expect(absf(player.velocity.x) < 1, "Crouching locks ground movement")
	expect(not player.start_action("PUNCH"), "Cannot attack through held crouch")
	Input.action_release("crouch")
	Input.action_release("move_right")
	await frames(3)
	expect(player.body_shape.shape.size.y == 144, "Standing restores the full collision shape")
	Input.action_press("guard")
	await frames(5)
	player.receive_training_hit(false)
	expect(player.health == 98 and player.action_timer == 0, "Guard absorbs test hit as chip damage")
	expect(not player.start_action("KICK"), "Held guard prevents attack startup")
	Input.action_release("guard")
	await reset()

	# Real input -> startup -> active collision -> recovery, once per attack.
	player.position.x = 820
	await frames(3)
	await tap("punch")
	expect(player.action_name == "PUNCH" and target.hit_count == 0, "Punch has startup frames before damage")
	await frames(30)
	expect(target.hit_count == 1 and target.total_damage == 8, "Punch damages crystal exactly once")
	expect(player.action_timer == 0 and player.state_name == "IDLE", "Punch recovers to idle")
	await tap("kick")
	await frames(40)
	expect(target.hit_count == 2 and target.total_damage == 22, "Kick deals 14 damage once")

	await reset()
	player.position.x = 500
	await frames(3)
	await tap("special")
	expect(player.energy > 75 and player.energy < 77, "Special spends 25 MP and regenerates")
	await frames(75)
	expect(target.hit_count == 1 and target.last_damage == 24, "Traveling pulse collides and deals 24 damage once")
	expect(get_nodes_in_group("dark_pulses").is_empty(), "Pulse is freed after impact")
	player.energy = 10
	expect(not player.start_action("ULTIMATE") and player.energy == 10, "Insufficient MP rejects ultimate without spending")
	player.energy = 100
	player.position.x = 500
	await frames(3)
	expect(player.start_action("ULTIMATE"), "Ultimate starts when grounded with enough MP")
	expect(player.energy >= 40 and player.energy < 42, "Ultimate costs 60 MP")
	await frames(115)
	expect(target.hit_count == 2 and target.last_damage == 60, "Ultimate reaches crystal and deals 60 damage once")

	await reset()
	player.receive_training_hit(false)
	expect(player.state_name == "HIT" and player.health == 92, "Test hit enters hit-stun and applies damage")
	expect(not player.start_action("PUNCH"), "Hit-stun prevents overlapping attacks")
	await frames(35)
	expect(player.state_name == "IDLE", "Hit-stun completes recovery")
	player.receive_training_hit(true)
	expect(player.state_name == "FALL" and player.health == 74, "Knockdown uses FALL clip and damage")
	await frames(90)
	expect(player.state_name == "IDLE" and player.is_on_floor(), "Knockdown automatically stands back up")
	await reset()
	player.start_action("SPECIAL")
	await frames(29)
	player.reset_training()
	await frames(4)
	expect(player.action_name.is_empty() and player.action_timer == 0 and player.energy == 100, "Reset clears action state and restores resources")
	expect(get_nodes_in_group("dark_pulses").is_empty(), "Reset removes in-flight projectiles")

	# Facing affects actual attack geometry and projectile travel.
	await reset()
	player.position.x = 1035
	player.facing = -1
	await frames(3)
	player.start_action("PUNCH")
	await frames(30)
	expect(target.hit_count == 1 and target.last_damage == 8, "Left-facing melee hitbox damages the target")
	await reset()
	player.position.x = 1160
	player.facing = -1
	await frames(3)
	player.start_action("SPECIAL")
	await frames(70)
	expect(target.hit_count == 1 and target.last_damage == 24, "Left-facing projectile travels left and hits once")
	await reset()
	# Esc is dispatched through the actual key event path.
	Input.action_press("move_right")
	await frames(10)
	var pause_event := InputEventKey.new()
	pause_event.physical_keycode = KEY_ESCAPE
	pause_event.pressed = true
	stage._input(pause_event)
	var frozen_position: Vector2 = player.position
	await frames(8)
	expect(stage.paused and player.position == frozen_position, "Pause freezes gameplay physics")
	stage._input(pause_event)
	await frames(5)
	expect(not stage.paused and player.position.x > frozen_position.x, "Esc resumes gameplay")
	await reset()

	player.health = 73
	player.position.x = 610
	Input.action_press("move_right")
	stage._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect(player.health == 73 and player.position.x == 610, "Losing focus preserves manual training progress")
	expect(not Input.is_action_pressed("move_right"), "Losing focus releases held movement")
	await reset()

	# Every timeline must differ from its rest pose and contain finite channels.
	for clip: String in player.rig.CLIPS:
		var pose: Array = player.rig.sample_pose(clip, 0.5)
		expect(pose.size() == 13 and pose != player.rig.REST, "Authored animation exists: " + clip)
		if clip != "JUMP":
			var planted: bool = true
			for step in range(21):
				player.rig.apply_pose(player.rig.sample_pose(clip, step/20.0))
				var actual_bottom: float = -INF
				var inverse: Transform2D = player.rig.global_transform.affine_inverse()
				for part: String in player.rig.pieces:
					var transform: Transform2D = inverse * player.rig.pieces[part].global_transform
					for point: Vector2 in player.rig.support_hulls[part]:
						actual_bottom = maxf(actual_bottom, (transform * point).y)
				planted = planted and absf(actual_bottom) < 0.001
			expect(planted, "Opaque pixels stay above the floor across clip: " + clip)
	player.visited = {"IDLE": true}
	stage.set_showcase(true)
	await frames(1770)
	stage.set_showcase(false)
	expect(player.visited.size() == 12, "Automatic showcase exercises all 12 states")
	expect(not Input.is_action_pressed("run") and not Input.is_action_pressed("move_right"), "Leaving showcase releases synthetic input")

	print("RESULT: %d checks, %d failures" % [checks, failures])
	stage.queue_free()
	await frames(2)
	quit(1 if failures > 0 else 0)

func _test_original_pixels() -> void:
	var original: Image = player.rig.MASTER.get_image()
	var reconstructed := Image.create(64,64,false,Image.FORMAT_RGBA8)
	var unique: bool = true
	var same: bool = true
	var count: int = 0
	for part: String in player.rig.pieces:
		var piece: Image = player.rig.pieces[part].texture.get_image()
		for y in range(64):
			for x in range(64):
				var pixel: Color = piece.get_pixel(x,y)
				if pixel.a > 0:
					unique = unique and reconstructed.get_pixel(x,y).a == 0
					reconstructed.set_pixel(x,y,pixel)
					count += 1
	for y in range(64):
		for x in range(64):
			if original.get_pixel(x,y).a > 0 or reconstructed.get_pixel(x,y).a > 0:
				same = same and original.get_pixel(x,y) == reconstructed.get_pixel(x,y)
	expect(unique and count == player.rig.pixel_count, "Rig assigns every visible pixel exactly once")
	expect(same, "Rig pieces reconstruct original face, outfit and shoes pixel-for-pixel")

func _test_mountains() -> void:
	var artwork: Node2D = stage.get_node("StageArt")
	var valid: bool = true
	# Includes the old failure cases where peak+ridge exceeded the base.
	for peak: float in [128.0,169.0,232.0,252.0,288.0,310.0,450.0]:
		var polygon: PackedVector2Array = artwork.mountain_points(350,peak,335,320)
		var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygon)
		valid = valid and triangles.size() == (polygon.size()-2)*3
	expect(valid, "Mountain geometry triangulates for all peaks, including old error cases")
