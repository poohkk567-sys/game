extends Node2D
## Cosmetic impact only; the attack query remains the single damage source.
const ATLAS: Texture2D = preload("res://assets/effects/dark_pulse_vfx.png")
const DURATION: float = 0.28
var age: float = 0.0
var direction: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_to_group("purple_punch_impacts")

func _process(delta: float) -> void:
	age += delta
	if age >= DURATION:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var q: float = clampf(age/DURATION,0.0,0.9999)
	var index: int = 12+mini(3,floori(q*4))
	var size: Vector2 = ATLAS.get_size()
	var upper := Vector2(floorf((index%4)*size.x/4.0),floorf(3*size.y/4.0))
	var lower := Vector2(floorf((index%4+1)*size.x/4.0),size.y)
	var extent := Vector2(130,142)*(0.80+q*0.35)
	draw_set_transform(Vector2.ZERO,0,Vector2(float(direction),1))
	draw_texture_rect_region(ATLAS,Rect2(-extent*0.5,extent),Rect2(upper,lower-upper),Color(1,1,1,1.0-smoothstep(0.4,1.0,q)),false,true)
	for i in range(10):
		var axis := Vector2.from_angle(i*TAU/10.0)
		draw_line(axis*(15+q*25),axis*(28+q*55),Color(0.86,0.46,1,1.0-q),2,false)
