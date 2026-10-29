extends SceneTree
var checks: int = 0
var failures: int = 0
var stage: Node2D
var boxer: PhuzashiCharacter
var enemy: PhuzashiCharacter
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS "+label)
	else:
		failures += 1
		push_error("FAIL "+label)
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func setup(left: bool = false) -> void:
	for action: StringName in InputMap.get_actions(): Input.action_release(action)
	stage.restart_match()
	stage.phase = "FIGHT"
	boxer.controls_enabled = true
	enemy.controls_enabled = true
	boxer.position.x = 640 if left else 750
	enemy.position.x = 750 if left else 640
	await frames(5)
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	boxer = stage.p2
	enemy = stage.p1
	check(boxer.select_fighter("MUAY_THAI"),"Third fighter profile is selectable")
	await frames(5)
	check(boxer.display_name == "MUAY THAI" and not boxer.specials_enabled,"Muay Thai is a normal-moves-only fighter")
	check(boxer.max_health == 200 and boxer.health == 200,"Third fighter follows the shared 200-HP rule")
	var sprite: AnimatedSprite2D = boxer.rig.draft_animation
	var total: int = 0
	for clip: StringName in sprite.muay_frames.get_animation_names():
		var own: bool = sprite.muay_frames.get_frame_count(clip) == 8
		for frame in range(8):
			var atlas: AtlasTexture = sprite.muay_frames.get_frame_texture(clip,frame)
			own = own and str(atlas.get_meta("original_source",atlas.atlas.resource_path)).contains("/muay_thai/")
			total += 1
		check(own,"Own complete eight-frame drawing set: "+clip)
	check(total == 112,"Third fighter has 112 complete source drawings")
	check(sprite.frame_at_progress("CROUCH",1.0) == 5,"Held crouch stays on the deep crouching drawing")
	check(sprite.frame_at_progress("PUNCH",0.45) == 2,"Jab holds its extended contact drawing during damage")
	check(sprite.frame_at_progress("KICK",0.50) == 2,"Teep holds its extended contact drawing during damage")
	await setup()
	check(boxer.standing_height() == 168 and boxer.hurt_area.shape.shape.size.y == 168,"Taller fighter has a matching taller hurtbox")
	var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture("IDLE",0)
	var visual_height: float = atlas.region.size.y*absf(sprite.scale.y*boxer.rig.scale.y)
	check(absf(visual_height-187.2) < 2,"Muay Thai standing artwork is twenty percent taller than the 156px fighters")
	for skill: String in ["SPECIAL","ULTIMATE","DEMON_BIND","CHEER"]:
		check(not boxer.start_action(skill) and boxer.energy == 100,"No borrowed special skill: "+skill)
	for left: bool in [false,true]:
		for family: String in ["PUNCH","KICK"]:
			await setup(left)
			boxer.energy = 0
			for _i in range(3): boxer.start_action(family)
			await frames(110)
			check(enemy.damage_taken == (36 if family == "PUNCH" else 52),"Real "+family+" combo damage, mirrored="+str(left))
			check(boxer.energy == 11,"Muay Thai normals retain 3+3+5 mana rewards")
			check(not boxer.purple_fist.active,"Muay Thai combos never borrow purple fist effects")
	check(str(sprite.sprite_frames.get_frame_texture("PUNCH_3",3).get_meta("original_source",sprite.sprite_frames.get_frame_texture("PUNCH_3",3).atlas.resource_path)).contains("punch_combo"),"Third punch uses the authored elbow drawing")
	check(str(sprite.sprite_frames.get_frame_texture("KICK_2",3).get_meta("original_source",sprite.sprite_frames.get_frame_texture("KICK_2",3).atlas.resource_path)).contains("kick_combo"),"Second kick uses the authored knee drawing")
	check(boxer.attack_config("PUNCH_3")[5] < boxer.attack_config("PUNCH_2")[5] and boxer.attack_config("KICK_2")[5] < boxer.attack_config("KICK")[5],"Elbow and knee use closer strike ranges")
	await setup()
	Input.action_press("p2_jump")
	await frames(2)
	Input.action_release("p2_jump")
	boxer.start_action("KICK")
	await frames(18)
	check(enemy.damage_taken == 15 and boxer.state_name == "AIR_KICK","Third fighter can jump-kick using its own drawings")
	await setup()
	Input.action_press("p2_crouch")
	await frames(12)
	check(boxer.body_shape.shape.size.y == 100 and boxer.state_name == "CROUCH","Third fighter crouches with a proportionate low hurtbox")
	Input.action_release("p2_crouch")
	Input.action_press("p2_guard")
	await frames(12)
	boxer.receive_attack(8,"PUNCH",enemy)
	check(boxer.guard_meter == 90 and boxer.health == 198,"Third fighter uses the same transparent shield/guard meter rules")
	await setup()
	check(boxer._start_movement_burst(boxer.facing) and boxer.dash_timer > 0,"Third fighter supports the normal dash input")
	boxer.apply_movement_lock(0.7)
	check(boxer.dash_timer == 0 and boxer.is_movement_locked(),"Movement locks interrupt the third fighter's dash")
	await setup()
	boxer.health = 0
	await frames(4)
	check(boxer.state_name == "FALL","Third fighter has its own defeated pose")
	stage.queue_free()
	await frames(3)
	var menu: Control = load("res://scenes/title_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(4)
	check(menu.selectors[0].item_count == 3 and menu.selectors[1].item_count == 3,"Both title selectors offer all three fighters")
	menu.selectors[0].select(2)
	menu.selectors[1].select(1)
	menu.start_versus()
	await frames(8)
	stage = current_scene
	check(stage.p1.fighter_profile == "MUAY_THAI" and stage.p2.fighter_profile == "RED_CAP","Title selection starts a real Muay Thai versus Assjiro match")
	stage.queue_free()
	await frames(3)
	remove_meta("fighter_choices")
	print("MUAY THAI RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
