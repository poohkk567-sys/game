extends Node2D
## BLACK's five attack skills share the established damage/guard/buff path.
const Book = preload("res://scripts/combat/skill_book.gd")
const Hit = preload("res://scripts/combat/skill_hit.gd")
const Art = preload("res://scripts/effects/black_skill_art.gd")
const Fang = preload("res://scripts/effects/crimson_fang.gd")
const Impact = preload("res://scripts/effects/crimson_impact.gd")
const BODY: SpriteFrames = preload("res://assets/characters/black_coat/skills/black_cast_frames.res")
var fighter: Node2D
var released: bool = false
var contacts: Dictionary = {}
var body: AnimatedSprite2D

func _ready() -> void:
	fighter = get_parent().fighter
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body = AnimatedSprite2D.new()
	body.sprite_frames = BODY
	body.centered = false
	body.visible = false
	var cutout := ShaderMaterial.new()
	cutout.shader = load("res://assets/characters/drafts/alpha_cutout.gdshader")
	body.material = cutout
	add_child(body)

func owns(action: String) -> bool:
	return action in Book.ROSTER.BLACK_COAT.slice(0,5)

func reset() -> void:
	released = false
	contacts.clear()
	if is_instance_valid(body):
		if body.visible: fighter.rig.visible = true
		body.visible = false
	queue_redraw()

func movement(desired: float) -> float:
	if fighter.action_timer <= 0 or fighter.fighter_profile != "BLACK_COAT": return desired
	var p: float = fighter.action_progress()
	if fighter.action_name == "RAGE_DRIVE" and p >= 0.12 and p < 0.66:
		# Physical travel through the common pushboxes, not a teleport.
		return fighter.facing*245*sin(clampf((p-0.12)/0.54,0,1)*PI)
	if fighter.action_name == "GRIN_CRUSH" and p >= 0.28 and p < 0.48: return fighter.facing*90
	return desired

func process_attack() -> void:
	var action: String = fighter.action_name
	if action == "BLOOD_FANG":
		if not released:
			released = true
			var fang := Fang.new()
			fang.configure(fighter)
			fighter.get_parent().add_child(fang)
		return
	var p: float = fighter.action_progress()
	var beat: int = mini(2,maxi(0,floori((p-0.28)/0.16))) if action == "RAGE_DRIVE" else 0
	var config: Array = Book.MOVES[action]
	var size := Vector2(config[5],config[6])
	var center: Vector2 = fighter.global_position+Vector2(fighter.facing*(size.x*0.5+18),-size.y*0.5-8)
	if action == "CRIMSON_BURST": center.x = fighter.global_position.x
	var damage: int = (14 if beat == 2 else 8) if action == "RAGE_DRIVE" else int(config[2])
	var move: String = "RAGE_DRIVE_FINISH" if action == "RAGE_DRIVE" and beat == 2 else action
	var push: float = (300 if beat == 2 else 20) if action == "RAGE_DRIVE" else (480 if action == "CRIMSON_BURST" else (290 if action == "GRIN_CRUSH" else 120))
	for target: Node2D in Hit.query(fighter,Rect2(center-size*0.5,size)):
		var contact: String = "%d:%d" % [target.get_instance_id(),beat]
		if contacts.has(contact): continue
		var amount: int = Hit.apply(fighter,target,damage,move,action == "HELL_RISER",push)
		if amount < 0: continue
		contacts[contact] = true
		var impact := Impact.new()
		impact.position = target.get_parent().global_position+Vector2(0,-80) if target.has_method("was_last_hit_blocked") else target.global_position+Vector2(0,-45)
		impact.direction = fighter.facing
		impact.heavy = move in ["GRIN_CRUSH","CRIMSON_BURST","RAGE_DRIVE_FINISH"]
		fighter.get_parent().add_child(impact)

func pose(original: String, progress: float) -> Array:
	match fighter.action_name:
		"BLOOD_FANG": return ["PUNCH_2",progress]
		"RAGE_DRIVE":
			if progress < 0.28: return ["RUN",progress/0.28]
			var beat: int = mini(2,maxi(0,floori((progress-0.28)/0.16)))
			return [["PUNCH","PUNCH_2","PUNCH_3"][beat],0.20+clampf(fmod(maxf(0,progress-0.28),0.16)/0.16,0,1)*0.65]
		"CRIMSON_BURST": return ["GUARD",clampf(progress*1.7,0,0.85)]
	return [original,progress]

func present() -> void:
	var action: String = fighter.action_name if fighter.action_timer > 0 and fighter.health > 0 else ""
	body.visible = fighter.fighter_profile == "BLACK_COAT" and action in ["HELL_RISER","GRIN_CRUSH"]
	if body.visible:
		var clip: String = "RISE" if action == "HELL_RISER" else "CRUSH"
		var factor: float = 156.0/float(BODY.get_meta("heights")[clip])
		body.animation = clip
		body.frame = mini(7,floori(fighter.action_progress()*8))
		body.scale = Vector2(factor*fighter.facing,factor)
		body.position = -Vector2(512*fighter.facing,960)*factor
		fighter.rig.visible = false
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(fighter) or fighter.fighter_profile != "BLACK_COAT" or fighter.health <= 0 or fighter.action_timer <= 0: return
	var action: String = fighter.action_name
	if not owns(action): return
	var p: float = fighter.action_progress()
	var strength: float = minf(1,p*8)*minf(1,(1-p)*5)
	draw_set_transform(Vector2.ZERO,0,Vector2(fighter.facing,1))
	# Small scarlet embers telegraph every startup without hiding the fighter.
	for i in range(12):
		var q: float = fmod(p*2+i/12.0,1)
		draw_line(Vector2(-20+sin(i*7.2)*40,-q*145),Vector2(-18+sin(i*7.2)*40,-q*145-5),Color(1,0.045,0.12,strength*(1-q)*0.7),2,false)
	match action:
		"BLOOD_FANG":
			if p < 0.56: Art.frame(self,"FANG",p/0.56,Vector2(62,-86),Vector2(145,145),strength)
		"RAGE_DRIVE":
			var beat: float = clampf((p-0.12)/0.65,0,0.999)
			Art.frame(self,"DRIVE",beat,Vector2(90,-83),Vector2(220,180),strength*0.9)
		"HELL_RISER":
			Art.frame(self,"RISE",clampf((p-0.12)/0.70,0,1),Vector2(72,-125),Vector2(195,270),strength*0.88)
		"GRIN_CRUSH":
			Art.frame(self,"CRUSH",clampf((p-0.12)/0.76,0,1),Vector2(112,-100),Vector2(240,255),strength*0.88)
			if p >= 0.48 and p < 0.78:
				var q: float = (p-0.48)/0.30
				draw_set_transform(Vector2(110,-4),0,Vector2(1,0.22))
				draw_arc(Vector2.ZERO,40+q*130,0,TAU,32,Color(1,0.04,0.15,1-q),5,false)
		"CRIMSON_BURST":
			var q: float = clampf((p-0.18)/0.62,0,1)
			Art.frame(self,"BURST",q,Vector2(0,-88),Vector2.ONE*(110+q*280),strength*0.9)
	draw_set_transform(Vector2.ZERO)
