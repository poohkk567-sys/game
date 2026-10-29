extends SceneTree
## Visual regression: before/after joint seams, rendered by Godot.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280,720)
	var panel := Control.new()
	root.add_child(panel)
	var background := ColorRect.new()
	background.color = Color("142334")
	background.size = Vector2(1280,720)
	panel.add_child(background)
	for i in range(4):
		var old: bool = i % 2 == 0
		var clip: String = "GUARD" if i < 2 else "RUN"
		var x: float = 320 if old else 960
		var y: float = 328 if i < 2 else 680
		var label := Label.new()
		label.text = ("BEFORE / " if old else "FIXED / ") + clip
		label.position = Vector2(x-260,y-300)
		label.add_theme_font_size_override("font_size",24)
		panel.add_child(label)
		var rig := Node2D.new()
		rig.set_script(load("res://work/old_rig.gd" if old else "res://scripts/character/phuzashi_rig.gd"))
		panel.add_child(rig)
		rig.position = Vector2(x,y)
		rig.scale = Vector2(5,5)
		rig.apply_pose(rig.sample_pose(clip,0.5))
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://work/joint_fix_comparison.png")
	quit()
