extends SceneTree
## In-engine review of the revised assist beside PHUZASHI, both directions.
var stage: Node2D

func _initialize() -> void:
	call_deferred("record")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/cheer_style_"+label+".png")

func record() -> void:
	set_meta("clear_training",true)
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(10)
	for direction: int in [1,-1]:
		stage.phuzashi.reset_training()
		stage.phuzashi.position.x = 640
		stage.phuzashi.facing = direction
		await frames(5)
		stage.phuzashi.start_action("CHEER")
		await frames(28)
		await capture("run_"+str(direction))
		await frames(34)
		await capture("cheer_"+str(direction))
		await frames(135)
	quit()
