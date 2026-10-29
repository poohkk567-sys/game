extends Node2D
## Cosmetic guardians follow only their own live buff/form; no combat stats here.
const Guardian = preload("res://scripts/effects/side_guardian_art.gd")
const Smoke = preload("res://scripts/effects/ninja_smoke.gd")
@onready var fighter: Node2D = get_parent()
var clock: float = 0
var kind: String = ""
var sprite: AnimatedSprite2D
var intensity: float = 0
var arrival_age: float = 0
var arrival_offset: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = Guardian.create(self)

func _physics_process(delta: float) -> void:
	clock += delta
	arrival_age += delta
	refresh()

func refresh() -> void:
	var previous: String = kind
	kind = ""
	intensity = 1
	if fighter.health > 0:
		if fighter.uses_dark_pulse() and fighter.cheer_buff > 0:
			kind = "PURPLE"
			intensity = minf(1,fighter.cheer_buff*3)
		elif fighter.fighter_profile == "RED_CAP":
			if fighter.red_awakened:
				kind = "GOLD"
			elif fighter.action_name == "TRANSFORM" and fighter.action_timer > 0 and fighter.action_progress() >= 10.0/16.0:
				kind = "GOLD"
		elif fighter.fighter_profile == "BLACK_COAT" and fighter.pact.buff_remaining > 0:
			kind = "RED"
			intensity = minf(1,fighter.pact.buff_remaining*3)
			if fighter.action_name == "BLOOD_PACT" and fighter.action_timer > 0:
				intensity *= smoothstep(0.50,0.85,fighter.action_progress())
	if kind != previous:
		arrival_age = 0
		if kind == "PURPLE": Smoke.spawn(self,fighter.global_position+Vector2(-50*fighter.facing,0),190)
	arrival_offset = 0
	if kind == "PURPLE": intensity *= smoothstep(0.02,0.20,arrival_age)
	if kind == "GOLD":
		arrival_offset = -230*(1-smoothstep(0,0.85,arrival_age))
		intensity *= smoothstep(0,0.32,arrival_age)
	# Keep the arrival clock running while cyclone hides the form, so returning
	# from a skill never repeats the descent. Fino likewise owns only one ninja.
	visible = not kind.is_empty() and not fighter.is_fino_active() and not fighter.cyclone_active()
	if is_instance_valid(sprite):
		sprite.visible = visible
		if visible:
			Guardian.present(sprite,kind,clock,fighter.facing,318 if kind == "GOLD" else 300,Vector2(-50*fighter.facing,6+arrival_offset),intensity*0.82)
	queue_redraw()

func _draw() -> void:
	if kind.is_empty(): return
	var tint: Color = {"RED":Color("ff3559"),"PURPLE":Color("ad48ff"),"GOLD":Color("ffc34f")}[kind]
	if kind == "GOLD" and arrival_age < 1.0:
		var fade: float = sin(clampf(arrival_age,0,1)*PI)
		var center: float = -50*fighter.facing
		var shaft := PackedVector2Array([Vector2(center-90,-560),Vector2(center+90,-560),Vector2(center+34,0),Vector2(center-34,0)])
		draw_colored_polygon(shaft,Color(1,0.85,0.4,fade*0.13))
		for side in [-1,1]:
			draw_line(Vector2(center+side*90,-560),Vector2(center+side*34,-10),Color(1,0.86,0.49,fade*0.42),2,false)
		for i in range(12):
			var point := Vector2(center+sin(i*2.7)*68,-450+fmod(arrival_age*280+i*39,440))
			draw_line(point-Vector2(0,5),point+Vector2(0,5),Color(1,0.96,0.7,fade*0.8),2,false)
			draw_line(point-Vector2(3,0),point+Vector2(3,0),Color(1,0.96,0.7,fade*0.8),2,false)
	for i in range(16):
		var q: float = fmod(clock*0.7+i/16.0,1)
		var point := Vector2(sin(i*2.4+clock*1.4)*(48+q*12),-q*205)
		draw_rect(Rect2(point,Vector2(2,4)),Color(tint,sin(q*PI)*0.8*intensity))
	draw_set_transform(Vector2(0,1),0,Vector2(1,0.23))
	draw_arc(Vector2.ZERO,53,clock*0.6,TAU+clock*0.6,48,Color(tint,0.65*intensity),2)
	draw_set_transform(Vector2.ZERO)
