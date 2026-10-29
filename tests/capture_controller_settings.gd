extends SceneTree
const Profile = preload("res://scripts/input/controller_profile.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var pads: Node = root.get_node("Gamepads")
	var stage: Node2D = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	for _i in range(5): await process_frame
	pads.configure_devices([2,5],{2:{"guid":"demo1","name":"DEMO Xbox Controller"},5:{"guid":"demo2","name":"DEMO PlayStation Controller"}})
	pads.open_settings()
	var ui: CanvasLayer = pads.settings_panel
	ui.choices = {"p1_":pads.device_choice(5),"p2_":pads.device_choice(2)}
	ui._refresh_devices()
	ui.tabs.current_tab = 1
	Profile.remap(ui.mappings.p1_,"punch",Profile.button(JOY_BUTTON_B))
	ui._refresh_bindings()
	ui.binding_buttons.punch.get_parent().get_parent().scroll_vertical = 220
	for _i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var target: String = "res://work/settings-native42.png" if Engine.get_version_info().minor == 2 else "res://docs/screenshots/roster_remap.png"
	root.get_texture().get_image().save_png(target)
	quit()
