extends SceneTree
## Actual grounded combos at 60% speed for reviewing the four distinct poses.
func _initialize() -> void:
	call_deferred("record")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func record() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	var actor: PhuzashiCharacter = stage.get_node("PHUZASHI")
	var target: Area2D = stage.get_node("TrainingCrystal")
	for direction: int in [1,-1]:
		for family: String in ["PUNCH","KICK"]:
			actor.reset_training()
			target.reset_target()
			actor.position.x = 820 if direction > 0 else 1035
			actor.facing = direction
			await frames(8)
			Engine.time_scale = 0.6
			for _i in range(3):
				await tap(family.to_lower())
			var saved: Dictionary = {}
			for _i in range(205):
				await frames(1)
				var desired: int = 3 if family == "KICK" and actor.combo_step == 2 else 4
				if actor.combo_step in [2,3] and actor.rig.draft_animation.frame == desired and not saved.has(actor.combo_step):
					var path: String = "res://work/%s_%d_%s.png" % [family.to_lower(),actor.combo_step,"right" if direction > 0 else "left"]
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(path)
					saved[actor.combo_step] = true
				if family == "KICK" and actor.combo_step == 3 and actor.rig.draft_animation.frame == 3 and not saved.has("raised"):
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://work/kick_3_raised_%s.png" % ("right" if direction > 0 else "left"))
					saved["raised"] = true
			Engine.time_scale = 1.0
	await frames(20)
	quit()
