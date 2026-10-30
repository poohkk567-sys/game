extends "res://tests/test_contact_controls.gd"
## Art alignment and real buff/form lifecycle. These auras never award combat stats.
const Guardian = preload("res://scripts/effects/side_guardian_art.gd")
const Grip: SpriteFrames = preload("res://assets/effects/ninja_grapple_frames.res")
func run() -> void:
	for kind: String in ["PURPLE","RED","GOLD"]:
		check(Guardian.FRAMES.get_frame_count(kind) == 8,"Eight pixel-art loop drawings: "+kind)
		var fixed := Vector2.ZERO
		var stable: bool = true
		var own: bool = true
		for i in range(8):
			var atlas: AtlasTexture = Guardian.FRAMES.get_frame_texture(kind,i)
			var point: Vector2 = atlas.margin.position+atlas.get_meta("core")
			if i == 0: fixed = point
			stable = stable and point.distance_to(fixed) < 0.02
			own = own and atlas.atlas.resource_path.contains("/side_guardians/") and atlas.region.size.x > 100 and atlas.region.size.y > 100
		check(stable,"Core stays anchored across flame/cloth motion: "+kind)
		check(own,"Every complete frame belongs to the accepted pixel design: "+kind)
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	for profile: String in ["PHUZASHI","PHUZASHI_CHILL"]:
		for left: bool in [false,true]:
			await setup(profile,left)
			a.cheer_buff = 8
			await frames(3)
			check(a.status_aura.sprite.animation == "PURPLE" and a.status_aura.visible,"Purple ninja follows actual cheer: "+profile)
			check(a.status_aura.sprite.sprite_frames == Guardian.FRAMES and a.status_aura.sprite.scale.x*a.facing > 0,"New art bank and facing mirror are used, left="+str(left))
			check(a.status_aura.sprite.material.shader == Guardian.SPECTRAL,"Feathered energy shader keeps the guardian spectral")
			var before: int = a.status_aura.sprite.frame
			await frames(9)
			check(a.status_aura.sprite.frame != before,"Aura advances through drawings instead of a static image")
			a.start_action("DEMON_BIND")
			await frames(40)
			var demons: Array[Node] = get_nodes_in_group("demon_bind_effects")
			check(demons.size() == 1 and demons[0].phase == "HOLD" and demons[0].guardian.sprite_frames == Grip,"Empowered leg bind uses separate compact grappling art")
			check(demons[0].guardian.scale.x*b.facing > 0 and demons[0].visual_height == 116 and demons[0].lock_time == 1.1,"Small rear grappler follows victim facing and preserves 1.1s lock")
			a.cheer_buff = 0
			await frames(2)
			check(not a.status_aura.visible and demons[0].guardian.visible,"Cheer cloak expires while the already-cast lock retains its snapshot")
			await frames(110)
			check(get_nodes_in_group("demon_bind_effects").is_empty(),"Holding spirit releases and frees itself")
			a.start_action("DEMON_BIND")
			await frames(35)
			demons = get_nodes_in_group("demon_bind_effects")
			check(demons.size() == 1 and not demons[0].empowered and demons[0].guardian.sprite_frames == Grip and demons[0].lock_time == 0.7,"Unbuffed cast uses the small ninja with original 0.7s bind")
		await setup(profile)
		a.cheer_buff = 8
		a.start_action("ULTIMATE")
		await frames(36)
		var fino: Node2D = a.get_node("FinoAura")
		check(a.is_fino_active() and fino.guardian.visible and fino.guardian.sprite_frames == Guardian.FRAMES,"Fino ride carries the signature ninja guardian: "+profile)
		check(not a.status_aura.visible,"Cheer does not draw a second overlapping guardian during Fino")
		await frames(90)
		check(not fino.visible and a.status_aura.visible,"Cheer guardian returns after Fino while buff remains")
	await setup("BLACK_COAT")
	check(not a.status_aura.visible,"Red pact aura is absent before the sacrifice")
	a.start_action("ULTIMATE")
	await frames(98)
	check(a.status_aura.sprite.animation == "RED" and a.status_aura.sprite.modulate.a > 0.7,"Red grinning contract demon appears after the door slash")
	check(a.energy == 30 and not a.attack_invulnerable(),"New red aura does not change 70MP cost or grant immunity")
	b.select_fighter("PHUZASHI_CHILL")
	b.controls_enabled = true
	b.cheer_buff = 8
	await frames(3)
	check(a.status_aura.sprite.material != b.status_aura.sprite.material,"Two players own independent materials and atlas coordinates")
	var clock: float = a.status_aura.clock
	var duration: float = a.pact.buff_remaining
	paused = true
	for _i in range(8): await process_frame
	check(a.status_aura.clock == clock and a.pact.buff_remaining == duration,"Pause freezes both guardian animation and real buff duration")
	paused = false
	await setup("RED_CAP")
	a.red_awakened = false
	a.rig.set_red_awakened(false)
	await frames(2)
	check(not a.status_aura.visible,"Capped form has no golden guardian")
	a.start_action("ULTIMATE")
	await frames(135)
	check(a.status_aura.sprite.animation == "GOLD" and a.status_aura.visible,"Side-facing lotus guardian builds during awakening")
	await frames(71)
	check(a.red_awakened and a.status_aura.visible and a.energy == 30,"Bald form keeps the new golden guardian and old mana rules")
	a.start_action("CARROT_SPIN")
	await frames(2)
	check(not a.status_aura.visible,"Golden guardian hides while the body is replaced by carrot cyclone")
	await frames(75)
	check(a.status_aura.visible,"Golden guardian returns after cyclone recovery")
	a.health = 0
	await frames(2)
	check(not a.status_aura.visible,"KO hides the sacred aura")
	stage.start_round()
	await frames(3)
	check(not a.red_awakened and not a.status_aura.visible and a.energy == 50,"Round reset clears form/guardian and restores 50MP")
	stage.queue_free()
	await frames(3)
	check(get_nodes_in_group("demon_bind_effects").is_empty(),"Scene exit leaves no summoned guardian actors")
	print("SIDE GUARDIAN RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
