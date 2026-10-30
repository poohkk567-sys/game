extends SceneTree
## A real gameplay recording: idle, walking both ways, and F4 comparison.
func _initialize() -> void:
	call_deferred("record")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func record() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(30)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/spritesheet_idle.png")
	await frames(30)
	Input.action_press("move_right")
	await frames(35)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/spritesheet_walk.png")
	await frames(25)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(60)
	Input.action_release("move_left")
	await frames(30)
	var compare := InputEventKey.new()
	compare.physical_keycode = KEY_F4
	compare.pressed = true
	stage._input(compare)
	await frames(60)
	Input.action_press("move_right")
	await frames(60)
	Input.action_release("move_right")
	Input.action_press("move_left")
	await frames(60)
	Input.action_release("move_left")
	await frames(30)
	stage._input(compare)
	await frames(30)
	quit()
