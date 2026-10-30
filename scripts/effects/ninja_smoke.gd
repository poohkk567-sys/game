extends Node2D
## Short, pause-safe smoke bursts; never own damage or a movement lock.
const LIFETIME: float = 0.38
var age: float = 0
var extent: float = 150

static func spawn(parent: Node2D, anchor: Vector2, height: float = 150) -> Node2D:
	var puff: Node2D = load("res://scripts/effects/ninja_smoke.gd").new()
	puff.extent = height
	parent.add_child(puff)
	puff.global_position = anchor
	return puff

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("ninja_smoke_effects")
	z_index = 3

func _physics_process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var q: float = clampf(age/LIFETIME,0,1)
	var alpha: float = (1-smoothstep(0.18,1,q))*smoothstep(0,0.08,q)
	var factor: float = extent/150.0
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*factor)
	for i in range(11):
		var angle: float = i*2.39996
		var spread: float = (12+i*3)*(0.5+q*1.7)
		var point := Vector2(cos(angle)*spread,-55+sin(angle)*spread*0.8-q*28)
		var radius: float = (14+i%4*3)*(0.7+q*0.7)
		var puff := PackedVector2Array()
		for vertex in range(10):
			puff.append((point+Vector2.from_angle(vertex*TAU/10)*radius).snapped(Vector2(2,2)))
		draw_colored_polygon(puff,Color(Color("28113f"),alpha*0.83))
		var inner := PackedVector2Array()
		for vertex in range(10):
			inner.append((point+Vector2(-3,-4)+Vector2.from_angle(vertex*TAU/10)*radius*0.70).snapped(Vector2(2,2)))
		draw_colored_polygon(inner,Color(Color("a362d5"),alpha*0.6))
	for i in range(8):
		var angle: float = i*TAU/8+0.3
		var point := Vector2(0,-60)+Vector2.from_angle(angle)*(24+q*72)
		draw_line(point,point+Vector2.from_angle(angle)*14,Color(0.89,0.68,1,alpha*0.7),2,false)
	draw_set_transform(Vector2.ZERO)
