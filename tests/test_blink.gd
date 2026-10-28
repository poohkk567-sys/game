extends SceneTree
var checks: int = 0
var failures: int = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS " + label)
	else:
		failures += 1
		push_error("FAIL " + label)

func frames(n: int) -> void:
	for _i in range(n):
		await physics_frame
		await process_frame

func tap(key: String) -> void:
	Input.action_press(key)
	await frames(2)
	Input.action_release(key)
	await frames(2)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	var actor: PhuzashiCharacter = stage.get_node("PHUZASHI")
	var sprite: AnimatedSprite2D = actor.rig.draft_animation
	check(sprite.sprite_frames.has_animation("BLINK"), "SpriteFrames contains BLINK")
	check(sprite.sprite_frames.get_frame_count("BLINK") == 12, "Blink uses 12 original full-body frames")
	check(actor.is_on_floor(), "Standing on floor")
	var x: float = actor.position.x
	await tap("move_right")
	await tap("move_right")
	check(actor.blink_timer > 0.0, "D double tap activates blink")
	x = actor.blink_origin
	check(actor.energy >= 84.0 and actor.energy < 87.0, "Blink costs 15 MP")
	await frames(9)
	check(actor.blink_invulnerable(), "Blink has intangible frames")
	var hp: float = actor.health
	actor.receive_training_hit(false)
	check(actor.health == hp, "Invulnerable blink ignores hit")
	await frames(26)
	check(actor.blink_timer == 0.0, "Blink animation has finished")
	check(absf(actor.position.x - (x + 130.0)) < 2.0, "Right blink travels 130px")
	await frames(14)
	x = actor.position.x
	await tap("move_left")
	await tap("move_left")
	check(actor.blink_timer > 0.0, "A double tap activates blink")
	x = actor.blink_origin
	await frames(28)
	check(absf(actor.position.x - (x - 130.0)) < 3.0, "Left blink travels 130px")
	actor.reset_training()
	actor.energy = 5
	await frames(4)
	await tap("move_right")
	await tap("move_right")
	check(actor.blink_timer == 0.0, "Cannot blink when MP insufficient")
	actor.reset_training()
	check(actor.blink_timer == 0.0 and actor.blink_cooldown == 0.0, "Reset clears blink")
	stage.queue_free()
	await frames(2)
	print("SHADOW BLINK %d checks %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
