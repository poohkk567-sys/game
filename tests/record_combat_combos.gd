extends SceneTree
## Render real input-driven aerial attacks and three-hit chains, both facings.
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

func screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func record() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	var actor: PhuzashiCharacter = stage.get_node("PHUZASHI")
	var target: Area2D = stage.get_node("TrainingCrystal")
	for direction: int in [1,-1]:
		for aerial: bool in [true,false]:
			for family: String in ["PUNCH","KICK"]:
				actor.reset_training()
				target.reset_target()
				actor.position.x = 820 if direction > 0 else 1035
				actor.facing = direction
				await frames(8)
				var binding: String = family.to_lower()
				var label: String = ("air_" if aerial else "combo_") + binding + ("_right" if direction > 0 else "_left")
				if aerial:
					await tap("jump")
					await tap(binding)
					var saved: bool = false
					for _i in range(79):
						await frames(1)
						if not saved and actor.attack_phase() == "ACTIVE" and actor.rig.draft_animation.frame == 4:
							await screenshot("res://work/%s.png" % label)
							saved = true
				else:
					for _i in range(3):
						await tap(binding)
					var saved: bool = false
					for _i in range(116):
						await frames(1)
						if not saved and actor.combo_step == 3 and actor.attack_phase() == "ACTIVE":
							await screenshot("res://work/%s.png" % label)
							saved = true
	stage.show_help = true
	await frames(4)
	await screenshot("res://work/combos_move_list.png")
	await frames(40)
	quit()
