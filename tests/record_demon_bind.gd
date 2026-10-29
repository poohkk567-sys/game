extends SceneTree
## Actual S+J input, capture, release and post-bind combo, in both directions.
func _initialize() -> void:
	call_deferred("record")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func record() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	var actor: PhuzashiCharacter = stage.get_node("PHUZASHI")
	var target: Area2D = stage.get_node("TrainingCrystal")
	for direction: int in [1,-1]:
		actor.reset_training()
		target.reset_target()
		actor.position.x = 630 if direction > 0 else 1170
		actor.facing = direction
		await frames(8)
		Input.action_press("crouch")
		Input.action_press("punch")
		await frames(2)
		Input.action_release("punch")
		Input.action_release("crouch")
		var saved: bool = false
		for _i in range(110):
			await frames(1)
			if not saved and target.is_movement_locked() and target.movement_lock.remaining < 0.57:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://work/demon_hold_%s.png" % ("right" if direction > 0 else "left"))
				saved = true
		actor.position.x = 820 if direction > 0 else 1035
		await frames(5)
		for _i in range(3):
			Input.action_press("punch")
			await frames(2)
			Input.action_release("punch")
			await frames(2)
		await frames(95)
	stage.show_help = true
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/demon_move_list.png")
	await frames(35)
	quit()
