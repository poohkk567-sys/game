extends SceneTree
## Capture the actual playable blink in both directions, slowed for art review.
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
	for direction: int in [1, -1]:
		actor.reset_training()
		actor.position.x = 525 if direction > 0 else 740
		await frames(8)
		Engine.time_scale = 0.4
		actor._start_blink(direction)
		var prefix: String = "right" if direction > 0 else "left"
		for i in range(112):
			await frames(1)
			if i in [16, 32, 51, 72]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://work/blink_%s_%02d.png" % [prefix, i])
		Engine.time_scale = 1.0
		await frames(20)
	quit()
