extends SceneTree
var checks: int = 0
var failures: int = 0
var stage: Node2D
var a: PhuzashiCharacter
var b: PhuzashiCharacter
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
	for command: StringName in InputMap.get_actions(): Input.action_release(command)
	stage.restart_match()
	stage.p1.energy = 100
	stage.p2.energy = 100
	stage.phase = "FIGHT"
	a.controls_enabled = true
	b.controls_enabled = true
	a.position.x = 750 if left else 640
	b.position.x = 640 if left else 750
	await frames(5)
func awaken() -> void:
	b.red_awakened = true
	b.rig.set_red_awakened(true)
func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(6)
	a = stage.p1
	b = stage.p2
	check(a.max_health == 200 and b.max_health == 200 and a.health == 200 and b.health == 200,"Production versus defaults to 200 HP per fighter")
	check(b.display_name == "ASSJIRO","Red Cap's player-facing name is now ASSJIRO")
	await setup()
	check(not b.start_action("SPECIAL") and not b.start_action("DEMON_BIND") and b.energy == 100,"Capped form rejects both carrot skills without spending mana")
	check(b.start_action("PUNCH"),"Capped form can still punch")
	await frames(30)
	check(b.start_action("KICK"),"Capped form can still kick")
	for left: bool in [false,true]:
		await setup(left)
		var start: float = b.position.x
		check(b._start_dash(b.facing),"Assjiro starts a ground dash in either direction")
		check(not b._start_dash(b.facing) and not b.start_action("PUNCH"),"Dash prevents stacking and attack cancellation")
		await frames(16)
		check(absf(b.position.x-start) > 65 and absf(b.position.x-start) < 115 and b.energy == 100,"Dash travels a short distance without mana cost")
		check(not b.blink_invulnerable() and b.blink_timer == 0,"Assjiro dash does not borrow Blink invulnerability")
	await setup()
	b._start_dash(-1)
	await frames(2)
	Input.action_press("p2_guard")
	b.receive_attack(8,"PUNCH",a)
	check(b.dash_timer == 0 and not b.last_hit_blocked and b.health == 192,"A real hit can interrupt and damage a capped dash")
	for damage: int in [8,14,60]:
		await setup()
		awaken()
		b.receive_attack(damage,"PUNCH",a)
		check(is_equal_approx(b.health,200-damage*0.7),"Awakened damage reduction is exactly 30 percent: "+str(damage))
	await setup()
	awaken()
	Input.action_press("p2_guard")
	await frames(12)
	var before: Vector2 = b.position
	b.receive_attack(8,"PUNCH",a)
	await frames(1)
	check(is_equal_approx(b.health,198.6) and b.guard_meter == 90,"Awakened form also reduces chip damage without reducing guard cost")
	check(b.rig.position.length() > 0.1 and b.guard_impact > 0,"Blocked impact produces a visible whole-body shake")
	await frames(6)
	check(b.position.x > before.x+2 and b.position.x < before.x+15,"Successful guard recoils a small physical distance")
	await setup()
	awaken()
	check(b.start_action("SPECIAL"),"Awakened form unlocks carrot headbutt")
	await setup()
	awaken()
	check(b.start_action("DEMON_BIND"),"Awakened form unlocks carrot barrage")
	await setup()
	check(b.start_action("ULTIMATE"),"Capped form retains its 70-MP transformation")
	await frames(200)
	check(b.red_awakened and b.energy == 30,"Transformation still completes before unlocking skills")
	for left: bool in [false,true]:
		await setup(left)
		var x: float = a.position.x
		check(a.start_action("ULTIMATE") and a.energy == 40,"Purple Fino ultimate costs 60 MP")
		await frames(12)
		check(a.fino_visual.visible and not a.rig.visible and a.fino_visual.sprite_frames.get_frame_count("FINO") == 16,"Ultimate displays the complete rider/scooter sheet instead of the old body pose")
		await frames(95)
		check(b.health == 140 and b.damage_taken == 60,"Fino rams the opponent exactly once for 60 damage")
		check(a.struck.size() == 1 and absf(a.position.x-x) < 150 and absf(a.velocity.x) < 1,"Close-range Fino brakes after the confirmed ram instead of riding over the victim")
		await frames(12) # Includes the new ultimate impact pause.
		check(not a.fino_visual.visible and a.rig.visible,"Fino recovery restores the normal fighter")
	await setup()
	a.start_action("ULTIMATE")
	await frames(15)
	a.receive_attack(8,"PUNCH",b)
	await frames(2)
	check(not a.fino_visual.visible and a.rig.visible,"Taking a hit interrupts the scooter and restores the fighter")
	check(not FileAccess.get_file_as_string("res://scripts/character/combat_effects.gd").contains("violet_dragon_vfx"),"The old dragon is removed from runtime effect code")
	await setup()
	a.position.x = 300
	Input.action_press("p1_move_right")
	await frames(20)
	var sprite: AnimatedSprite2D = a.rig.draft_animation
	check(a.state_name == "WALK" and a.walk_distance > 40,"Walk cycle advances by actual distance traveled")
	var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture("WALK",sprite.frame)
	check(str(atlas.get_meta("original_source","")).ends_with("walk_fixed.png"),"Runtime walk uses the corrected alternating-leg artwork")
	check(sprite.frame == sprite.frame_at_progress("WALK",fmod(a.walk_distance/104,1)),"Walk animation phase stays synchronized to movement")
	await setup()
	check(a.start_action("CHEER") and a.energy == 70,"Cheer call costs 30 MP")
	check(not a.start_action("CHEER"),"Cheer cannot stack or bypass its cooldown")
	await frames(50)
	check(a.cheer_buff == 0 and get_nodes_in_group("cheer_assists").size() == 1,"Support girl finishes cheering before granting the buff")
	await frames(125)
	check(a.cheer_buff > 7 and a.cheer_buff <= 8 and get_nodes_in_group("cheer_assists").is_empty(),"Girl vanishes before the full eight-second ninja buff begins")
	check(a.bind_lock_duration() == 1.1,"Cheer raises the next bind duration to 1.1 seconds")
	Input.action_press("p1_move_left")
	await frames(12)
	check(absf(a.velocity.x) > 200 and absf(a.velocity.x) < 210,"Cheer increases ground walking speed by ten percent")
	Input.action_release("p1_move_left")
	a.position.x = 640
	b.position.x = 750
	await frames(4)
	check(a.start_action("DEMON_BIND"),"Buffed PHUZASHI can cast Demon Bind")
	await frames(35)
	check(b.is_movement_locked() and b.movement_lock.remaining > 0.75,"Actual demon arrival applies the longer lock")
	await frames(45)
	check(b.is_movement_locked(),"Buffed lock remains active beyond the original 0.7 seconds")
	await frames(30)
	check(not b.is_movement_locked(),"Buffed lock releases automatically")
	await frames(420)
	check(a.cheer_buff == 0 and a.bind_lock_duration() == 0.7 and get_nodes_in_group("cheer_assists").is_empty(),"Cheer and its helper expire without permanently changing bind duration")
	await setup()
	check(not b.start_action("CHEER") and b.energy == 100,"Assjiro cannot borrow PHUZASHI's support assist")
	stage.queue_free()
	await frames(3)
	var menu: Control = load("res://scenes/title_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(3)
	check(menu.selectors.size() == 2 and menu.rigs.size() == 2,"Title menu displays both selectable fighters")
	menu.selectors[0].select(1)
	menu.selectors[1].select(0)
	menu.start_versus()
	await frames(8)
	stage = current_scene
	check(stage.p1.display_name == "ASSJIRO" and stage.p2.display_name == "PHUZASHI","Title selection assigns chosen fighters to their actual player slots")
	check(stage.p1.health == 200 and stage.p2.health == 200,"Character selection keeps the new versus HP rules")
	stage.queue_free()
	await frames(3)
	remove_meta("fighter_choices")
	print("NEW GAME RULES RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
