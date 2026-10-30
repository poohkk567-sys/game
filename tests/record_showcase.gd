extends SceneTree
## Godot movie capture: --write-movie work/showcase.avi --fixed-fps 30
func _initialize() -> void:
	call_deferred("record")

func record() -> void:
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	for i in range(10):
		await process_frame
	stage.set_showcase(true)
	for i in range(864):
		await process_frame
	stage.set_showcase(false)
	quit()
