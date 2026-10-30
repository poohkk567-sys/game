extends SceneTree
## Scripted inputs only for the review movie; gameplay has two human controllers.
var stage: Node3D
func _initialize() -> void: call_deferred("record")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/coop_preview_"+label+".png")
func release() -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)
func arrange() -> void:
	release()
	stage.restart()
	stage.state = "FIGHT"
	stage.boss.ai_enabled = false
	stage.boss.position = Vector3(0,0,-0.8)
	stage.team[0].position = Vector3(-1.8,0,0.3)
	stage.team[1].position = Vector3(1.8,0,0.3)
	await frames(30)
func record() -> void:
	var menu: Control = load("res://scenes/title_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(18)
	await shot("menu")
	menu.start_coop()
	await frames(120)
	stage = current_scene
	stage.boss.ai_enabled = false
	await shot("arena")
	await arrange()
	for tick in range(110):
		if tick in [0,9,18]:
			Input.action_press("p1_punch")
			Input.action_press("p2_kick")
		if tick in [1,10,19]:
			Input.action_release("p1_punch")
			Input.action_release("p2_kick")
		await frames(1)
		if tick == 28: await shot("team_combo")
	await arrange()
	stage.team[0].position = Vector3(0,0,1.6)
	stage.team[1].position = Vector3(-4.0,0,1.4)
	await frames(3)
	stage.boss.start_attack("SWEEP",stage.team[0].position)
	await frames(27)
	await shot("sweep_warning")
	await frames(13)
	Input.action_press("p1_coop_jump")
	await frames(12)
	await shot("jump_sweep")
	Input.action_release("p1_coop_jump")
	await frames(50)
	await arrange()
	stage.team[0].position = Vector3(-3,0,2)
	stage.team[1].position = Vector3(2.4,0,0)
	await frames(4)
	stage.boss.start_attack("SLAM",stage.team[1].position)
	await frames(44)
	await shot("slam_warning")
	Input.action_press("p2_move_right")
	await frames(20)
	await shot("boss_leap")
	await frames(38)
	Input.action_release("p2_move_right")
	await arrange()
	stage.team[0].position = Vector3(-3,0,1.5)
	stage.team[1].position = Vector3(3,0,1.5)
	await frames(3)
	stage.boss.start_attack("CHARGE",stage.team[1].position)
	await frames(40)
	await shot("charge_lane")
	await frames(65)
	await arrange()
	stage.team[0].position = Vector3(-3,0,2)
	stage.team[1].position = Vector3(-1.6,0,2)
	stage.boss.position = Vector3(5,0,-2)
	await frames(4)
	stage.team[1].receive_hit(999,stage.boss.position,0)
	await frames(32)
	Input.action_press("p1_coop_revive")
	await frames(54)
	await shot("revive")
	await frames(66)
	Input.action_release("p1_coop_revive")
	await arrange()
	# Actual two-player inputs and a live AI finish the demonstration.
	stage.boss.ai_enabled = true
	for tick in range(240):
		for i in range(2):
			var actor: Node3D = stage.team[i]
			if actor.downed: continue
			var target: Vector3 = stage.boss.position+Vector3(-1.7 if i == 0 else 1.7,0,0.8)
			var difference: Vector3 = target-actor.position
			for spec: Array in [["move_left",difference.x < -0.3],["move_right",difference.x > 0.3],["coop_forward",difference.z < -0.3],["coop_back",difference.z > 0.3]]:
				if spec[1]: Input.action_press(actor.input_prefix+spec[0])
				else: Input.action_release(actor.input_prefix+spec[0])
			if tick%20 == 0: Input.action_press(actor.input_prefix+("punch" if i == 0 else "kick"))
			if tick%20 == 1: Input.action_release(actor.input_prefix+("punch" if i == 0 else "kick"))
			if stage.boss.state == "WINDUP" and stage.boss.state_time > stage.boss.windup_time*0.65: Input.action_press(actor.input_prefix+"coop_jump")
			else: Input.action_release(actor.input_prefix+"coop_jump")
		await frames(1)
		if tick == 180: await shot("live_battle")
	release()
	await frames(20)
	quit()
