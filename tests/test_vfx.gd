extends SceneTree
## Import and runtime lifecycle tests for the completed VFX.
var checks: int = 0
var failures: int = 0

func expect(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS " + label)
	else:
		failures += 1
		push_error("FAIL " + label)

func advance(n: int) -> void:
	for _i in range(n):
		await physics_frame
		await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for path: String in ["res://assets/effects/dark_pulse_vfx.png", "res://assets/effects/violet_dragon_vfx.png"]:
		var texture: Texture2D = load(path)
		expect(texture != null, "Atlas is imported: " + path)
		if texture == null:
			continue
		var size: Vector2 = texture.get_size()
		expect(size.x > 0.0 and size.y > 0.0 and int(size.x) % 4 == 0 and int(size.y) % 4 == 0, "Atlas can be split 4x4: " + path)
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await advance(6)
	var fighter: PhuzashiCharacter = stage.get_node("PHUZASHI")
	expect(fighter.effects != null and fighter.effects.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Effects render independently with nearest filter")
	fighter.position.x = 500
	expect(fighter.start_action("SPECIAL"), "SPECIAL starts")
	await advance(32)
	expect(get_nodes_in_group("dark_pulses").size() > 0, "SPECIAL spawns visible projectile")
	await advance(90)
	expect(get_nodes_in_group("dark_pulses").is_empty(), "Projectile is removed after impact or timeout")
	fighter.reset_training()
	await advance(4)
	expect(fighter.start_action("ULTIMATE"), "ULTIMATE starts")
	await advance(120)
	expect(fighter.action_timer == 0.0 and fighter.state_name == "IDLE", "ULTIMATE completes")
	fighter.reset_training()
	await advance(2)
	expect(get_nodes_in_group("dark_pulses").is_empty(), "Reset clears projectiles")
	stage.queue_free()
	await advance(2)
	print("VFX RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
