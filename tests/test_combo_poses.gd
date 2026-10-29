extends SceneTree
var checks: int = 0
var failures: int = 0
var stage: Node2D
var actor: PhuzashiCharacter
var target: Area2D

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

func begin(left: bool = false, miss: bool = false) -> void:
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	target.reset_target()
	actor.position.x = 300 if miss else (1035 if left else 820)
	actor.facing = -1 if left else 1
	await frames(4)
	for _i in range(3):
		actor.start_action("PUNCH")
	for _i in range(80):
		await frames(1)
		if actor.action_name == "PUNCH_3" and actor.action_progress() >= 0.35:
			return
	check(false,"Uppercut is reached within the combo")

func run() -> void:
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	actor = stage.get_node("PHUZASHI")
	actor.energy = 100 # Explicit full-mana combat fixture.
	target = stage.get_node("TrainingCrystal")
	var sprite: AnimatedSprite2D = actor.rig.draft_animation
	var new_frames: int = 0
	for clip: StringName in sprite.COMBO_FRAMES.get_animation_names():
		new_frames += sprite.COMBO_FRAMES.get_frame_count(clip)
		var valid: bool = true
		for index in range(8):
			var atlas: AtlasTexture = sprite.COMBO_FRAMES.get_frame_texture(clip,index)
			valid = valid and atlas.margin.position.x >= 0 and atlas.margin.position.y >= 0
			valid = valid and is_equal_approx(atlas.margin.position.y+atlas.region.size.y,960.0)
		check(valid,"Complete figures and common ground pivot: "+clip)
	check(new_frames == 32,"Four distinct combo moves contain 32 new drawings")
	for left: bool in [false,true]:
		await begin(left)
		check(sprite.animation == "PUNCH_3" and sprite.visible and not actor.rig.skin.visible,"New uppercut plays from full-body art")
		check(actor.purple_fist.active,"Third punch activates the purple power layer")
		var expected: Vector2 = sprite.combo_fist_global_position()
		check(actor.purple_fist.to_global(actor.purple_fist.hand).distance_to(expected) < 1.0,"Purple power follows the drawn fist (left=%s)" % left)
		check(expected.y < actor.global_position.y-140 and (expected.x-actor.global_position.x)*actor.facing > 0,"Uppercut fist rises above the head and mirrors correctly")
		check(target.hit_count == 3 and target.total_damage == 34,"New poses and purple effects keep one damage event per stage")
		check(get_nodes_in_group("purple_punch_impacts").size() == 1,"One purple impact is spawned by the real finisher hit")
		var impact: Node2D = get_nodes_in_group("purple_punch_impacts")[0]
		var age: float = impact.age
		var clock: float = actor.purple_fist.clock
		paused = true
		for _i in range(6):
			await process_frame
		check(impact.age == age and actor.purple_fist.clock == clock,"Pause freezes punch energy and its impact")
		paused = false
		await frames(50)
		check(not actor.purple_fist.active and actor.purple_fist.trail.is_empty(),"Recovery clears fist energy and trail")
		check(get_nodes_in_group("purple_punch_impacts").is_empty(),"Punch impact expires without residual nodes")
		check(actor.energy == 100.0,"Purple normal finisher does not consume skill MP")
	await begin(false,true)
	check(actor.purple_fist.active and target.hit_count == 0,"A missed uppercut still shows its powered fist")
	check(get_nodes_in_group("purple_punch_impacts").is_empty(),"Missing creates no false target impact")
	actor.receive_training_hit(false)
	await frames(1)
	check(not actor.purple_fist.active and actor.purple_fist.trail.is_empty(),"Hit interruption removes the purple fist immediately")
	await begin()
	actor.reset_training()
	actor.energy = 100 # Explicit full-mana combat fixture.
	await frames(2)
	check(get_nodes_in_group("purple_punch_impacts").is_empty() and not actor.purple_fist.active,"Reset removes both purple fist and impact")
	check(sprite.animation == "IDLE" and sprite.scale.is_equal_approx(Vector2.ONE*sprite.FRAME_SCALE),"Reset restores base sprite scale and pivot")
	stage.queue_free()
	await frames(2)
	print("COMBO POSE RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
