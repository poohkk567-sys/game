extends SceneTree
const Profile = preload("res://scripts/input/controller_profile.gd")
var pads: Node
var stage: Node2D
func _initialize() -> void:
	call_deferred("record")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func capture(name: String, preview: bool = false) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/roster_"+("preview_" if preview else "")+name+".png")
func setup(a_x: float = 560,b_x: float = 680) -> void:
	for command: StringName in InputMap.get_actions(): Input.action_release(command)
	stage.restart_match()
	stage.phase = "FIGHT"
	stage.p1.controls_enabled = true
	stage.p2.controls_enabled = true
	stage.p1.position.x = a_x
	stage.p2.position.x = b_x
	await frames(5)
func record() -> void:
	pads = root.get_node("Gamepads")
	var menu: Control = load("res://scenes/title_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(60)
	await capture("title",true)
	menu.selectors[1].select(2)
	menu._refresh_character(1)
	await frames(25)
	await capture("select_muay")
	menu.start_versus()
	await frames(115)
	stage = current_scene
	await capture("height")
	await setup(300,1000)
	Input.action_press("p1_move_right")
	await frames(18)
	await capture("walk_a")
	await frames(16)
	await capture("walk_b")
	Input.action_release("p1_move_right")
	await frames(10)
	stage.p1.start_action("CHEER")
	await frames(65)
	await capture("cheer_pink",true)
	stage.p2.position.x = 800
	stage.p1.start_action("DEMON_BIND")
	await frames(35)
	await capture("buffed_bind")
	await frames(80)
	await setup()
	Input.action_press("p1_guard")
	await frames(12)
	stage.p2.start_action("PUNCH")
	await frames(10)
	await capture("shield_impact")
	await frames(25)
	await setup()
	for _i in range(3): stage.p2.start_action("PUNCH")
	for _i in range(100):
		await frames(1)
		if stage.p2.action_name == "PUNCH_3" and stage.p2.action_progress() > 0.4:
			await capture("muay_elbow")
			break
	await frames(45)
	await setup()
	for _i in range(3): stage.p2.start_action("KICK")
	var saved: Dictionary = {}
	for _i in range(110):
		await frames(1)
		if stage.p2.action_name == "KICK_2" and stage.p2.action_progress() > 0.4 and not saved.has("knee"):
			await capture("muay_knee",true)
			saved.knee = true
		if stage.p2.action_name == "KICK_3" and stage.p2.action_progress() > 0.4 and not saved.has("kick"):
			await capture("muay_high_kick")
			saved.kick = true
	await setup(400,900)
	stage.p1.start_action("ULTIMATE")
	await frames(66)
	await capture("fino_black",true)
	await frames(55)
	stage.p2.select_fighter("RED_CAP")
	await setup(480,850)
	Input.action_press("p2_dash")
	await frames(6)
	await capture("assjiro_dash")
	Input.action_release("p2_dash")
	await frames(30)
	await setup()
	stage.p2.start_action("ULTIMATE")
	await frames(200)
	stage.p1.start_action("PUNCH")
	await frames(16)
	await capture("awakened_armor")
	await frames(25)
	stage.p2.energy = 100
	stage.p2.start_action("DEMON_BIND")
	await frames(35)
	await capture("awakened_barrage")
	await frames(70)
	pads.configure_devices([2,5],{2:{"guid":"demo1","name":"DEMO Xbox Controller"},5:{"guid":"demo2","name":"DEMO PlayStation Controller"}})
	pads.open_settings()
	var settings: CanvasLayer = pads.settings_panel
	settings.choices = {"p1_":pads.device_choice(5),"p2_":pads.device_choice(2)}
	settings._refresh_devices()
	await frames(20)
	await capture("settings",true)
	settings.tabs.current_tab = 1
	settings.editing = "p1_"
	Profile.remap(settings.mappings.p1_,"punch",Profile.button(JOY_BUTTON_B))
	settings._refresh_bindings()
	await frames(20)
	await capture("remap")
	await frames(30)
	settings._home()
	await frames(30)
	await capture("menu_final")
	await frames(25)
	quit()
