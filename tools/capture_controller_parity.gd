extends SceneTree
const Profile = preload("res://scripts/input/controller_profile.gd")
func _initialize() -> void: call_deferred("capture")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func press(code: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 2
	event.button_index = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func capture() -> void:
	set_meta("clear_training",true)
	var stage: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await frames(6)
	var pads: Node = root.get_node("Gamepads")
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.configure_devices([2],{2:{"guid":"parity-preview","name":"Controller Parity"}})
	pads.waiting_neutral = false
	pads._apply_layout()
	press(JOY_BUTTON_DPAD_DOWN)
	await frames(2)
	press(JOY_BUTTON_B)
	await frames(60)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/parity_preview_cheer.png")
	quit()
