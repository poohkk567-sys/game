extends SceneTree
## Review footage from real gameplay, with no manually forced animation frames.
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

func save_image(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/red_cap_"+name+".png")

func record() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(45)
	stage.switch_fighter()
	await frames(60)
	await save_image("idle")
	var actor: PhuzashiCharacter = stage.get_node("PHUZASHI")
	var target: Area2D = stage.get_node("TrainingCrystal")
	for move: String in ["WALK","RUN","JUMP","CROUCH","GUARD","HIT","FALL"]:
		stage._release_demo()
		actor.reset_training()
		actor.position.x = 500
		await frames(3)
		stage.showcase = true
		stage.showcase_clock = 1000
		stage._demonstrate(move)
		await frames(95)
	stage.set_showcase(false)
	for direction: int in [1,-1]:
		for family: String in ["PUNCH","KICK"]:
			actor.reset_training()
			target.reset_target()
			actor.position.x = 820 if direction > 0 else 1035
			actor.facing = direction
			await frames(8)
			Engine.time_scale = 0.65
			for _i in range(3):
				await tap(family.to_lower())
			var saved: Dictionary = {}
			for _i in range(175):
				await frames(1)
				if actor.combo_step in [2,3] and actor.attack_phase() == "ACTIVE" and not saved.has(actor.combo_step):
					await save_image("%s_%d_%s" % [family.to_lower(),actor.combo_step,"right" if direction > 0 else "left"])
					saved[actor.combo_step] = true
			Engine.time_scale = 1.0
		for family: String in ["punch","kick"]:
			actor.reset_training()
			target.reset_target()
			actor.position.x = 820 if direction > 0 else 1035
			actor.facing = direction
			await frames(8)
			await tap("jump")
			await tap(family)
			await frames(5)
			await save_image("air_%s_%s" % [family,"right" if direction > 0 else "left"])
			await frames(50)
	stage.switch_fighter()
	await frames(45)
	stage.switch_fighter()
	await frames(60)
	quit()
