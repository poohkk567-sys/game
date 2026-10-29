extends Node2D
## Cosmetic guardians follow only their own live buff/form; no combat stats here.
@onready var fighter: Node2D = get_parent()
var clock: float = 0
var kind: String = ""
var sprite: AnimatedSprite2D
var intensity: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://assets/effects/guardian_auras_frames.res")
	sprite.centered = false
	sprite.visible = false
	add_child(sprite)

func _physics_process(delta: float) -> void:
	clock += delta
	refresh()

func refresh() -> void:
	kind = ""
	intensity = 1
	if fighter.health > 0:
		if fighter.uses_dark_pulse() and fighter.cheer_buff > 0:
			kind = "PURPLE"
			intensity = minf(1,fighter.cheer_buff*3)
		elif fighter.fighter_profile == "RED_CAP" and not fighter.cyclone_active():
			if fighter.red_awakened:
				kind = "GOLD"
			elif fighter.action_name == "TRANSFORM" and fighter.action_timer > 0 and fighter.action_progress() > 0.30:
				kind = "GOLD"
				intensity = smoothstep(0.30,0.75,fighter.action_progress())
		elif fighter.fighter_profile == "BLACK_COAT" and fighter.pact.buff_remaining > 0:
			kind = "RED"
			intensity = minf(1,fighter.pact.buff_remaining*3)
			if fighter.action_name == "BLOOD_PACT" and fighter.action_timer > 0:
				intensity *= smoothstep(0.50,0.85,fighter.action_progress())
	visible = not kind.is_empty()
	if is_instance_valid(sprite):
		sprite.visible = visible
		if visible:
			sprite.animation = kind
			sprite.frame = floori(clock*9)%sprite.sprite_frames.get_frame_count(kind)
			var height: float = 252 if kind == "GOLD" else 230
			var factor: float = height/float(sprite.sprite_frames.get_meta("heights")[kind])
			sprite.scale = Vector2(factor*fighter.facing,factor)
			sprite.position = Vector2(-18*fighter.facing,4)-Vector2(512*fighter.facing,960)*factor
			sprite.modulate.a = intensity*0.82
	queue_redraw()

func _draw() -> void:
	if kind.is_empty(): return
	var tint: Color = {"RED":Color("ff3559"),"PURPLE":Color("ad48ff"),"GOLD":Color("ffc34f")}[kind]
	for i in range(16):
		var q: float = fmod(clock*0.7+i/16.0,1)
		var point := Vector2(sin(i*2.4+clock*1.4)*(48+q*12),-q*205)
		draw_rect(Rect2(point,Vector2(2,4)),Color(tint,sin(q*PI)*0.8*intensity))
	draw_set_transform(Vector2(0,1),0,Vector2(1,0.23))
	draw_arc(Vector2.ZERO,53,clock*0.6,TAU+clock*0.6,48,Color(tint,0.65*intensity),2)
	draw_set_transform(Vector2.ZERO)
