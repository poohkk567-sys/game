extends Node2D
## Cosmetic guardians follow only their own live buff/form; no combat stats here.
const Guardian = preload("res://scripts/effects/side_guardian_art.gd")
@onready var fighter: Node2D = get_parent()
var clock: float = 0
var kind: String = ""
var sprite: AnimatedSprite2D
var intensity: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = Guardian.create(self)

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
	# Fino owns one guardian during the ride; avoid two overlapping copies.
	visible = not kind.is_empty() and not fighter.is_fino_active()
	if is_instance_valid(sprite):
		sprite.visible = visible
		if visible:
			Guardian.present(sprite,kind,clock,fighter.facing,318 if kind == "GOLD" else 300,Vector2(-50*fighter.facing,6),intensity*0.82)
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
