extends Node2D
## Follows the drawn fist in every uppercut frame, without recoloring the body.
const ATLAS: Texture2D = preload("res://assets/effects/dark_pulse_vfx.png")
@onready var fighter: PhuzashiCharacter = get_parent()
var hand: Vector2 = Vector2.ZERO
var phase: float = 0.0
var active: bool = false
var trail: Array[Vector2] = []
var trail_times: Array[float] = []
var clock: float = 0.0

func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func clear() -> void:
	active = false
	trail.clear()
	trail_times.clear()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	active = fighter.specials_enabled and fighter.action_name == "PUNCH_3" and fighter.action_timer > 0.0
	if not active:
		if not trail.is_empty():
			clear()
		queue_redraw()
		return
	phase = fighter.action_progress()
	var sprite: AnimatedSprite2D = fighter.rig.draft_animation
	hand = to_local(sprite.combo_fist_global_position()) if sprite.visible else Vector2(fighter.facing * 70,-105)
	if phase >= 0.18 and phase <= 0.68:
		var point: Vector2 = to_global(hand)
		if trail.is_empty() or trail[trail.size()-1].distance_to(point) > 0.5:
			trail.append(point)
			trail_times.append(clock)
	while not trail_times.is_empty() and clock - trail_times[0] > 0.16:
		trail.pop_front()
		trail_times.pop_front()
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var glow: float = smoothstep(0.02,0.17,phase) * (1.0-smoothstep(0.64,0.91,phase))
	if trail.size() > 1:
		var points := PackedVector2Array()
		for point: Vector2 in trail:
			points.append(to_local(point))
		draw_polyline(points,Color(0.46,0.04,1,0.26 * glow),22,false)
		draw_polyline(points,Color(0.72,0.13,1,0.60 * glow),10,false)
		draw_polyline(points,Color(0.98,0.73,1,0.90 * glow),3,false)
	draw_circle(hand,27,Color(0.52,0.08,1,0.10 * glow))
	draw_circle(hand,19,Color(0.76,0.16,1,0.18 * glow))
	var index: int = mini(3,floori(phase/0.30 * 4.0)) if phase < 0.30 else 4+mini(3,floori((phase-0.30)/0.34 * 4.0))
	var col: int = index % 4
	var row: int = index / 4
	var size: Vector2 = ATLAS.get_size()
	var upper := Vector2(floorf(col*size.x/4.0),floorf(row*size.y/4.0))
	var lower := Vector2(floorf((col+1)*size.x/4.0),floorf((row+1)*size.y/4.0))
	var extent := Vector2(66,66) if phase < 0.30 else Vector2(94,86)
	draw_set_transform(hand,0,Vector2(float(fighter.facing),1))
	draw_texture_rect_region(ATLAS,Rect2(-extent*0.5,extent),Rect2(upper,lower-upper),Color(1,1,1,glow),false,true)
	draw_set_transform(Vector2.ZERO)
	for i in range(6):
		var axis := Vector2.from_angle(clock*5 + i*TAU/6.0)
		var tip: Vector2 = hand+axis*(22+sin(clock*32+i*7)*5)
		var bolt := PackedVector2Array([hand+axis*10,(hand+tip)*0.5+axis.orthogonal()*sin(clock*24+i)*5,tip])
		draw_polyline(bolt,Color(0.81,0.35,1,glow*0.9),2.5,false)
		draw_circle(tip,1.5,Color(1,0.85,1,glow))
