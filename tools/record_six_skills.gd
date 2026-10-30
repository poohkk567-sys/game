extends SceneTree
## Review footage: explicit full-mana fixtures let every move be reviewed quickly.
const Book = preload("res://scripts/combat/skill_book.gd")
var stage: Node2D
func _initialize() -> void: call_deferred("record")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/six_skills_"+name+".png")
func record() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(10)
	await capture("opening_50mp")
	for profile: String in Book.ROSTER:
		for action: String in Book.ROSTER[profile]:
			for command: StringName in InputMap.get_actions(): Input.action_release(command)
			stage.restart_match()
			stage.phase = "FIGHT"
			stage.p1.select_fighter(profile)
			stage.p2.select_fighter("PHUZASHI")
			stage.p1.controls_enabled = true
			stage.p2.controls_enabled = true
			stage.p1.position.x = 480
			var distance: float = 110
			if action in ["SPECIAL","ULTIMATE","SOY_BOMB"]: distance = 300
			if action in ["SHADOW_RETURN","GORILLA_QUAKE"]: distance = 215
			if action in ["CHEER","DEMON_BIND","TRANSFORM"]: distance = 400
			stage.p2.position.x = 480+distance
			if profile == "RED_CAP" and action != "TRANSFORM":
				stage.p1.red_awakened = true
				stage.p1.rig.set_red_awakened(true)
			stage.p1.energy = 100
			await frames(6)
			if action == "SHADOW_RETURN": stage.p1.shadow_return.confirm(stage.p2.hurt_area)
			stage.p1.start_action(action)
			var captured: bool = false
			var impact: bool = false
			for tick in range(210 if action in ["TRANSFORM","GORILLA_KING"] else 125):
				if action == "SHADOW_COUNTER" and tick == 10: stage.p2.start_action("PUNCH")
				if action == "GORILLA_GUARD" and tick == 42: Input.action_press("p1_guard")
				if action == "GORILLA_GUARD" and tick == 58: stage.p2.start_action("PUNCH")
				await frames(1)
				if not captured and tick >= (75 if action == "TRANSFORM" else (65 if action in ["GORILLA_GUARD","CHEER"] else 28)):
					await capture(action.to_lower())
					captured = true
				if action == "SOY_BOMB" and not impact:
					for effect: Node in get_nodes_in_group("six_skill_effects"):
						if effect.burst and effect.burst_age > 0.10:
							await capture(action.to_lower()+"_impact")
							impact = true
	quit()
