extends SceneTree
## Real-scene lifecycle, pause, reset and boundary regressions for the new VFX.
var checks: int = 0
var failures: int = 0

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

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	var actor: PhuzashiCharacter = stage.get_node("PHUZASHI")
	actor.energy = 100 # Explicit full-mana combat fixture.
	check(FileAccess.get_sha256("res://assets/effects/shadow_blink/shadow_blink_approved.png") == "6040de76cb8a691cb8d3b3fa0a8fab0b38206c23021ae8a49c504e4de866dfa7", "Approved effect sheet is byte-identical")
	check(actor._start_blink(1), "Right blink starts with illustrated VFX")
	check(get_nodes_in_group("shadow_blink_effects").size() == 1, "One independent effect per blink")
	var effect: Node2D = get_nodes_in_group("shadow_blink_effects")[0]
	var origin: Vector2 = effect.departure
	await frames(12)
	check(effect.departure == origin and actor.global_position.x > origin.x, "Departure rift stays at origin while fighter moves")
	check(effect.dash_sprite.visible and effect.dash_sprite.scale.x > 0, "Energy streak follows right-facing dash")
	check(effect.ghosts.size() > 0, "Full-body afterimages are captured during travel")
	var frozen: float = effect.age
	paused = true
	for _i in range(5):
		await process_frame
	check(is_equal_approx(effect.age, frozen), "Pausing freezes VFX and its lifetime")
	paused = false
	await frames(15)
	check(actor.blink_timer == 0.0 and not actor.blink_invulnerable(), "Visual recovery does not extend gameplay invulnerability")
	check(is_instance_valid(effect) and effect.arrival_sprite.visible, "Arrival smoke continues after the move finishes")
	check(effect.arrival_sprite.global_position.distance_to(effect.destination + Vector2(0,3)) < 0.1, "Arrival rift remains anchored to actual destination")
	await frames(24)
	check(get_nodes_in_group("shadow_blink_effects").is_empty(), "All visuals and afterimages expire")
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	await frames(4)
	check(actor._start_blink(-1), "Left blink starts")
	effect = get_nodes_in_group("shadow_blink_effects")[0]
	await frames(12)
	check(effect.direction == -1 and effect.dash_sprite.scale.x < 0, "Left blink mirrors approved art")
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	await frames(2)
	check(get_nodes_in_group("shadow_blink_effects").is_empty(), "Reset removes active rifts and ghosts")
	actor.position.x = 1185
	await frames(3)
	check(actor._start_blink(1), "Blink near arena edge starts")
	effect = get_nodes_in_group("shadow_blink_effects")[0]
	check(is_equal_approx(effect.destination.x, 1205.0), "Arrival is clamped to actual arena boundary")
	await frames(26)
	check(absf(actor.global_position.x - effect.destination.x) < 0.1, "Fighter and arrival effect agree at arena edge")
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	await frames(2)
	actor.energy = 1
	check(not actor._start_blink(1), "Low MP rejects blink")
	check(get_nodes_in_group("shadow_blink_effects").is_empty(), "Rejected blink creates no effects")
	stage.queue_free()
	await frames(2)
	check(get_nodes_in_group("shadow_blink_effects").is_empty(), "Leaving stage clears effect nodes")
	print("BLINK VFX %d checks %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
