extends Node2D
## Cast rules, hit confirmation and visual timing for the additional six-slot moves.
const Book = preload("res://scripts/combat/skill_book.gd")
const Hit = preload("res://scripts/combat/skill_hit.gd")
const Projectile = preload("res://scripts/effects/skill_projectile.gd")
const Feedback = preload("res://scripts/combat/skill_feedback.gd")
const Art = preload("res://scripts/effects/skill_art.gd")
const CAST: SpriteFrames = preload("res://assets/characters/ninja_cast/cast_frames.res")
const BlackSkills = preload("res://scripts/combat/black_skills.gd")
var black: Node2D
var fighter: Node2D
var cooldowns: Dictionary = {}
var spawned: bool = false
var launched: bool = false
var pulse: int = -1
var guard_buff: float = 0
var push_remaining: float = 0
var push_velocity: float = 0
var king_victim: Node2D
var king_connected: bool = false
var stand: AnimatedSprite2D
var extra_body: AnimatedSprite2D
var ghost: AnimatedSprite2D
var stand_fade: float = 0
var cyclone: AnimatedSprite2D

func _ready() -> void:
	fighter = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stand = AnimatedSprite2D.new()
	stand.sprite_frames = load("res://assets/characters/muay_thai/gorilla_stand_frames.res")
	stand.centered = false
	stand.visible = false
	var cutout := ShaderMaterial.new()
	cutout.shader = load("res://assets/characters/drafts/alpha_cutout.gdshader")
	stand.material = cutout
	add_child(stand)
	extra_body = AnimatedSprite2D.new()
	extra_body.sprite_frames = load("res://assets/characters/red_awakened/skills_frames.res")
	extra_body.centered = false
	extra_body.visible = false
	extra_body.material = cutout
	add_child(extra_body)
	ghost = AnimatedSprite2D.new()
	ghost.centered = false
	ghost.visible = false
	ghost.modulate = Color(0.34,0.08,0.60,0.6)
	add_child(ghost)
	cyclone = AnimatedSprite2D.new()
	cyclone.sprite_frames = load("res://assets/effects/carrot_cyclone_frames.res")
	cyclone.centered = false
	cyclone.visible = false
	add_child(cyclone)
	black = BlackSkills.new()
	add_child(black)

func tick(delta: float) -> void:
	for action: String in cooldowns:
		cooldowns[action] = maxf(0,float(cooldowns[action])-delta)
	guard_buff = maxf(0,guard_buff-delta)
	push_remaining = maxf(0,push_remaining-delta)
	stand_fade = maxf(0,stand_fade-delta*5)

func reset() -> void:
	if is_instance_valid(black): black.reset()
	cooldowns.clear()
	guard_buff = 0
	push_remaining = 0
	stand_fade = 0
	king_victim = null
	king_connected = false
	if is_instance_valid(stand): stand.visible = false
	if is_instance_valid(extra_body): extra_body.visible = false
	if is_instance_valid(ghost): ghost.visible = false
	if is_instance_valid(cyclone): cyclone.visible = false

func start(action: String) -> bool:
	var capped_shove: bool = action == "CAPPED_SHOVE" and fighter.fighter_profile == "RED_CAP" and not fighter.red_awakened
	if (action not in Book.ROSTER[fighter.fighter_profile] and not capped_shove) or not Book.MOVES.has(action): return false
	if action == "BLOOD_PACT" and fighter.pact.buff_remaining > 0:
		fighter.announce("BLOOD PACT / ALREADY ACTIVE")
		return false
	if fighter.fighter_profile == "RED_CAP" and not fighter.red_awakened and not capped_shove:
		fighter.announce("AWAKEN FIRST / 70 MP")
		return false
	if not fighter.duel_mode and not fighter.rig.use_clear_model and fighter.fighter_profile == "PHUZASHI":
		fighter.rig.set_clear_enabled(true)
	if (fighter.duel_mode and (not fighter.controls_enabled or fighter.health <= 0)) or fighter.action_timer > 0 or fighter.dash_timer > 0 or fighter.blink_timer > 0 or fighter.guard_break_remaining > 0 or fighter.is_movement_locked(): return false
	if not fighter.is_on_floor() or fighter.velocity.y < 0 or (not fighter.skill_input_modifier and (fighter.pressed("guard") or (fighter.pressed("crouch") and action != "GORILLA_KNEE"))): return false
	var cooldown_key: String = "SOY_BOMB" if capped_shove else action
	if float(cooldowns.get(cooldown_key,0)) > 0:
		fighter.announce("%s / COOLDOWN %.1fs" % [Book.SHORT_NAMES[action],cooldowns[cooldown_key]])
		return false
	if action == "SHADOW_RETURN" and fighter.shadow_return.target() == null:
		fighter.announce("HIT SHURIKEN FIRST / GUARD HIT COUNTS")
		return false
	var cost: float = fighter.skill_mana_cost(action)
	if fighter.energy < cost:
		fighter.announce("%s / NEED %d MP" % [Book.SHORT_NAMES[action],cost])
		return false
	fighter.energy -= cost
	cooldowns[cooldown_key] = Book.COOLDOWNS[cooldown_key]
	fighter._clear_combo()
	fighter._begin_attack(action)
	fighter.announce("%s / %d MP" % [Book.NAMES[action],cost])
	return true

func begin(_action: String) -> void:
	black.reset()
	if _action == "BLOOD_PACT": fighter.pact.begin()
	if _action == "SHADOW_RETURN": fighter.shadow_return.begin()
	spawned = false
	launched = false
	pulse = -1
	king_victim = null
	king_connected = false

func incoming(move: String, attacker: Node2D) -> bool:
	if fighter.action_name != "SHADOW_COUNTER" or fighter.action_timer <= 0: return false
	if fighter.action_progress() < 0.12 or fighter.action_progress() > 0.40: return false
	if not is_instance_valid(attacker) or absf(attacker.global_position.x-fighter.global_position.x) > 155: return false
	if (attacker.global_position.x-fighter.global_position.x)*fighter.facing < 0: return false
	if move not in ["PUNCH","PUNCH_2","PUNCH_3","KICK","KICK_2","KICK_3","AIR_PUNCH","AIR_KICK","GORILLA_ELBOW","GORILLA_KNEE","CARROT_UPROOT","CARROT_SPIN","RAGE_DRIVE","RAGE_DRIVE_FINISH","HELL_RISER","GRIN_CRUSH"]: return false
	fighter.last_hit_blocked = true
	fighter._begin_attack("SHADOW_REPRISAL")
	fighter.announce("SHADOW COUNTER / CONFIRMED")
	return true

func movement(desired: float) -> float:
	var action: String = fighter.action_name
	var p: float = fighter.action_progress()
	if fighter.action_timer > 0:
		if action == "CARROT_UPROOT" and p >= 0.26 and p < 0.50:
			if not launched:
				launched = true
				fighter.velocity.y = -240
			return fighter.facing*145
		if action in ["GORILLA_ELBOW","GORILLA_KNEE"] and p >= 0.18 and p < 0.42:
			return fighter.facing*110
		if action == "CARROT_SPIN" and p >= 0.25 and p < 0.65: return fighter.facing*100
	if push_remaining > 0: return push_velocity
	return black.movement(desired)

func process_attack() -> void:
	var action: String = fighter.action_name
	var p: float = fighter.action_progress()
	if black.owns(action):
		black.process_attack()
		return
	if action == "BLOOD_PACT":
		fighter.pact.commit()
		return
	if action == "SHADOW_RETURN": return # Owned by the return component, not a floor projectile.
	if action in ["SOY_BOMB","GORILLA_QUAKE"]:
		if not spawned:
			spawned = true
			var effect := Projectile.new()
			effect.configure(fighter,action)
			fighter.get_parent().add_child(effect)
		return
	if action == "GORILLA_GUARD":
		if not spawned:
			spawned = true
			guard_buff = 4.0
		return
	if action == "SHADOW_COUNTER": return
	var config: Array = Book.MOVES[action]
	var reach: float = config[5]
	var height: float = config[6]
	var center: Vector2 = fighter.global_position+Vector2(fighter.facing*(reach*0.5+18),-height*0.5-16)
	if action == "CARROT_SPIN": center.x = fighter.global_position.x
	var rect := Rect2(center-Vector2(reach,height)*0.5,Vector2(reach,height))
	if action == "GORILLA_KING":
		var next: int = mini(5,floori((p-0.25)/0.10))
		if next == pulse: return
		pulse = next
		if pulse == 0:
			for target: Node2D in Hit.query(fighter,rect):
				var amount: int = Hit.apply(fighter,target,8,action,false,0)
				if amount < 0: continue
				var blocked: bool = target.was_last_hit_blocked() if target.has_method("was_last_hit_blocked") else false
				if not blocked:
					king_victim = target
					king_connected = true
				break
		elif king_connected and is_instance_valid(king_victim) and king_victim in Hit.query(fighter,rect):
			Hit.apply(fighter,king_victim,20 if pulse == 5 else 8,"GORILLA_KING_FINISH" if pulse == 5 else action,false,240 if pulse == 5 else 0)
		return
	if action == "GORILLA_ROAR" and not spawned:
		spawned = true
		Feedback.obtain(fighter.get_parent()).impact(2,"ROAR")
	for target: Node2D in Hit.query(fighter,rect):
		if fighter.struck.has(target.get_instance_id()): continue
		var damage: int = config[2]
		var push: float = 850 if action == "CAPPED_SHOVE" else (350 if action == "GORILLA_ROAR" else (230 if action in ["CARROT_SPIN","SHADOW_REPRISAL"] else 150))
		var amount: int = Hit.apply(fighter,target,damage,action,action in ["CARROT_UPROOT","GORILLA_KNEE"],push)
		if amount >= 0: fighter.struck[target.get_instance_id()] = true

func pose(original: String, progress: float) -> Array:
	var action: String = fighter.action_name
	if fighter.action_timer <= 0: return [original,progress]
	if black.owns(action): return black.pose(original,progress)
	match action:
		"BLOOD_PACT": return ["HIT",0.35] if progress >= 0.50 and progress < 0.65 else ["GUARD",0.8]
		"SHADOW_RETURN": return ["PUNCH_3",clampf((progress-0.35)/0.30,0,1)] if progress >= 0.35 and progress < 0.75 else ["GUARD",0.8]
		"CAPPED_SHOVE": return ["PUNCH_2",progress]
		"SHADOW_COUNTER": return ["GUARD",0.75]
		"SHADOW_REPRISAL": return ["PUNCH_3",progress]
		"CARROT_UPROOT": return ["CROUCH",progress*2] if progress < 0.25 else ["JUMP",clampf((progress-0.25)/0.75,0,1)]
		"SOY_BOMB","CARROT_SPIN": return ["GUARD",0.8]
		"GORILLA_ELBOW": return ["PUNCH_3",progress]
		"GORILLA_KNEE": return ["KICK_2",progress]
		"GORILLA_QUAKE": return ["PUNCH_3",progress] if progress < 0.43 else ["CROUCH",0.8]
		"GORILLA_GUARD","GORILLA_ROAR": return ["GUARD",0.8]
		"GORILLA_KING":
			if progress < 0.25: return ["KICK_2",progress/0.5]
			if progress > 0.80: return ["PUNCH_3",0.65+(progress-0.80)]
			var phase: float = fmod((progress-0.25)/0.10,1)
			return ["KICK_2" if maxi(0,pulse)%2 else "PUNCH_3",0.20+phase*0.55]
	return [original,progress]

func present() -> void:
	var action: String = fighter.action_name if fighter.action_timer > 0 else ""
	var p: float = fighter.action_progress()
	var is_stand: bool = action.begins_with("GORILLA_") or (guard_buff > 0 and fighter.can_guard())
	if is_stand:
		stand_fade = minf(1,stand_fade+0.25)
		var index: int = 2
		match action:
			"GORILLA_ELBOW","GORILLA_QUAKE": index = 4 if p < 0.18 else (5 if p < 0.42 else (6 if p < 0.62 else 7))
			"GORILLA_KNEE": index = 8 if p < 0.18 else (9 if p < 0.36 else (10 if p < 0.60 else 11))
			"GORILLA_ROAR": index = 12 if p < 0.4 else 13
			"GORILLA_GUARD": index = mini(2,floori(p*4))
			"GORILLA_KING": index = (8 if p < 0.25 else (15 if p >= 0.75 else (14 if maxi(0,pulse)%2 == 0 else 10)))
		stand.animation = "STAND"
		stand.frame = index
	stand.visible = stand_fade > 0 and fighter.fighter_profile == "MUAY_THAI" and fighter.health > 0
	if stand.visible:
		var factor: float = 278.0/float(stand.sprite_frames.get_meta("source_height"))
		stand.scale = Vector2(factor*fighter.facing,factor)
		stand.position = Vector2(-fighter.facing*40,0)-Vector2(512*fighter.facing,960)*factor
		stand.modulate = Color(1,0.91,0.94,stand_fade*0.82)
	extra_body.visible = action in ["SOY_BOMB","CAPPED_SHOVE"]
	if extra_body.visible:
		extra_body.sprite_frames = CAST if action == "CAPPED_SHOVE" else load("res://assets/characters/red_awakened/skills_frames.res")
		var clip: String = "SHOVE" if action == "CAPPED_SHOVE" else action
		var factor: float = 156.0/float(CAST.get_meta("heights")[clip] if action == "CAPPED_SHOVE" else extra_body.sprite_frames.get_meta("source_height"))
		extra_body.scale = Vector2(factor*fighter.facing,factor)
		extra_body.position = -Vector2(512*fighter.facing,960)*factor
		extra_body.animation = clip
		extra_body.frame = mini(7,floori(p*8))
		fighter.rig.visible = false
	cyclone.visible = fighter.cyclone_active()
	if cyclone.visible:
		var factor: float = 190.0/float(cyclone.sprite_frames.get_meta("source_height"))
		cyclone.scale = Vector2(factor*fighter.facing,factor)
		cyclone.position = -Vector2(512*fighter.facing,960)*factor
		cyclone.animation = "CYCLONE"
		cyclone.frame = mini(15,floori(p*16))
		fighter.rig.visible = false
	ghost.visible = action in ["SHADOW_COUNTER","SHADOW_REPRISAL"]
	if ghost.visible:
		var body: AnimatedSprite2D = fighter.rig.draft_animation
		ghost.sprite_frames = body.sprite_frames
		ghost.animation = "GUARD" if action == "SHADOW_COUNTER" else "PUNCH_3"
		ghost.frame = body.frame
		ghost.position = fighter.rig.position+Vector2(-fighter.facing*20,-5)+body.position*Vector2(fighter.facing*3,3)
		ghost.scale = body.scale*Vector2(fighter.facing*3,3)
	if is_instance_valid(fighter.shadow_return): fighter.shadow_return.present()
	black.present()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(fighter): return
	var action: String = fighter.action_name if fighter.action_timer > 0 else ""
	var p: float = fighter.action_progress()
	var tint := Color("fd78bb") if fighter.fighter_profile == "MUAY_THAI" else (Color("ff9f32") if fighter.fighter_profile == "RED_CAP" else Color("bc57ff"))
	if action == "CAPPED_SHOVE" and p > 0.25 and p < 0.85:
		var power: float = sin((p-0.25)/0.60*PI)
		for i in range(3):
			var radius: float = 35+(p-0.25)*150+i*12
			var angle: float = -PI/2 if fighter.facing > 0 else PI/2
			draw_arc(Vector2(fighter.facing*45,-85),radius,angle,angle+PI,24,Color(1,0.75+i*0.06,0.4,power*(0.6-i*0.15)),4-i,false)
	if action == "CARROT_UPROOT":
		draw_set_transform(Vector2.ZERO,0,Vector2(fighter.facing,1))
		Art.frame(self,8+mini(3,floori(p*4)),Vector2(10,-95),Vector2(235,225),sin(p*PI))
		draw_set_transform(Vector2.ZERO)
	if action == "SHADOW_REPRISAL":
		draw_set_transform(Vector2.ZERO,0,Vector2(fighter.facing,1))
		Art.frame(self,4+mini(3,floori(p*4)),Vector2(100,-90),Vector2(235,180),sin(p*PI))
		draw_set_transform(Vector2.ZERO)
	if stand.visible:
		for i in range(18):
			var point := Vector2(sin(i*9.31)*95-fighter.facing*40,-fmod(fighter.elapsed*70+i*19,260))
			draw_rect(Rect2(point,Vector2(3,5)),Color(tint,stand_fade*0.35))
	if action in ["CARROT_UPROOT","CARROT_SPIN","SHADOW_REPRISAL","GORILLA_ELBOW","GORILLA_KNEE","GORILLA_KING"]:
		var power: float = sin(p*PI)
		draw_set_transform(Vector2(fighter.facing*35,-85),-fighter.facing*p*2,Vector2(fighter.facing,1))
		for i in range(3):
			draw_arc(Vector2.ZERO,48+i*12,-1.8,0.9,22,Color(tint,power*(0.8-i*0.2)),7-i*2,false)
		for i in range(12):
			var ray := Vector2.from_angle(i*TAU/12+p*3)
			draw_line(ray*(35+p*15),ray*(45+p*35),Color(tint.lightened(0.6),power*0.7),2,false)
		draw_set_transform(Vector2.ZERO)
	if action == "GORILLA_ROAR" and p > 0.35:
		for i in range(3):
			var radius: float = fmod((p-0.35)*290+i*55,190)
			draw_arc(Vector2(fighter.facing*40,-130),radius,-1.2 if fighter.facing > 0 else PI-1.2,1.2 if fighter.facing > 0 else PI+1.2,26,Color(tint,1-radius/190),4,false)
