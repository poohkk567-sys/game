extends Area2D
## Traveling special: one impact, finite lifetime, removed on training reset.
var direction: int = 1
var source: Node2D
var age: float = 0.0
var hit: bool = false

func _ready() -> void:
	add_to_group("dark_pulses")
	collision_layer = 0
	collision_mask = 4
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 29.0
	collision.shape = circle
	add_child(collision)
	area_entered.connect(_on_target)

func _physics_process(delta: float) -> void:
	age += delta
	position.x += direction * 620.0 * delta
	if age > 1.8 or position.x < -80.0 or position.x > 1360.0:
		queue_free()
	queue_redraw()

func _on_target(target: Area2D) -> void:
	if hit or not target.has_method("take_hit"):
		return
	hit = true
	target.take_hit(24, "SPECIAL")
	if is_instance_valid(source):
		source.target_struck.emit(24)
	queue_free()

func _draw() -> void:
	for i in range(5):
		draw_circle(Vector2(-direction * i * 13, 0), 30.0 - i * 4.0, Color(0.48, 0.06, 1.0, 0.16 - i * 0.025))
	draw_arc(Vector2.ZERO, 25, age * 13, age * 13 + TAU * 0.8, 20, Color("be61ff"), 5, true)
	draw_arc(Vector2.ZERO, 17, -age * 17, -age * 17 + PI * 1.5, 15, Color("f3d9ff"), 3, true)
	draw_circle(Vector2.ZERO, 8, Color("faf0ff"))
	for i in range(6):
		var point := Vector2(-direction * (20 + i * 10), sin(age * 30 + i) * 15)
		draw_rect(Rect2(point, Vector2(4, 4)), Color("a938ff"))
