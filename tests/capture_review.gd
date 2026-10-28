extends SceneTree
## Run with a display (GL Compatibility), not the dummy headless renderer.
var stage: Node2D

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Unable to save " + path)
	print("CAPTURE ",path)

func run() -> void:
	root.size = Vector2i(1280,720)
	stage = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	await frames(15)
	await capture("res://work/training.png")
	var fighter: PhuzashiCharacter = stage.get_node("PHUZASHI")
	fighter.position.x = 800
	Input.action_press("guard")
	await frames(30)
	await capture("res://work/guard.png")
	Input.action_release("guard")
	await frames(10)
	fighter.start_action("KICK")
	await frames(18)
	await capture("res://work/kick.png")
	await frames(30)
	fighter.position.x = 500
	fighter.start_action("ULTIMATE")
	await frames(65)
	await capture("res://work/ultimate.png")
	await frames(50)
	fighter.receive_training_hit(true)
	await frames(42)
	await capture("res://work/fall.png")
	await frames(50)
	stage.show_help = true
	await frames(2)
	await capture("res://work/move_list.png")
	stage.queue_free()
	await frames(2)
	await _gallery()
	quit()

func _gallery() -> void:
	var panel := Control.new()
	root.add_child(panel)
	var background := ColorRect.new()
	background.color = Color("0a1020")
	background.size = Vector2(1280,720)
	panel.add_child(background)
	var title := Label.new()
	title.text = "PHUZASHI / DARK PULSE  ·  12 ANIMATED POSES"
	title.position = Vector2(32,18)
	title.add_theme_font_size_override("font_size",27)
	panel.add_child(title)
	var RigScript = load("res://scripts/character/phuzashi_rig.gd")
	for i in range(12):
		var origin := Vector2(24+(i%4)*314, 66+(i/4)*212)
		var card := ColorRect.new()
		card.color = Color("121e32")
		card.position = origin
		card.size = Vector2(300,200)
		panel.add_child(card)
		var rig := Node2D.new()
		rig.set_script(RigScript)
		panel.add_child(rig)
		rig.position = origin + Vector2(140,168)
		rig.scale = Vector2(2.7,2.7)
		var clip: String = rig.CLIPS[i]
		var phase: float = 0.5
		if clip == "IDLE": phase = 0.0
		if clip == "WALK": phase = 0.0
		if clip == "RUN": phase = 0.0
		if clip == "JUMP": phase = 0.36
		rig.apply_pose(rig.sample_pose(clip, phase), clip != "JUMP")
		var label := Label.new()
		label.text = "%02d  %s" % [i+1,clip]
		label.position = origin + Vector2(12,7)
		label.add_theme_font_size_override("font_size",15)
		label.modulate = Color("cca5ff")
		panel.add_child(label)
	await frames(3)
	await capture("res://work/pose_gallery.png")
	panel.queue_free()
	await frames(2)
