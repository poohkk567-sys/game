extends Area2D
## Projectile gameplay is unchanged: 24 damage, 620 px/s, one impact.
## Added: 16-frame visual charge/flight/impact atlas and impact lifetime.
const ATLAS: Texture2D = preload("res://assets/effects/dark_pulse_vfx.png")
const IMPACT_TIME: float = 0.28
var direction: int = 1
var source: Node2D
var age: float = 0.0
var impact_age: float = 0.0
var hit: bool = false

func _ready() -> void:
	add_to_group("dark_pulses")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_layer = 0
	collision_mask = 4
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 29.0
	collision.shape = circle
	add_child(collision)
	area_entered.connect(_on_target)

func _physics_process(delta: float) -> void:
	if hit:
		impact_age += delta
		if impact_age >= IMPACT_TIME:
			queue_free()
		else:
			queue_redraw()
		return
	age += delta
	position.x += float(direction) * 620.0 * delta
	if age > 1.8 or position.x < -80.0 or position.x > 1360.0:
		queue_free()
		return
	queue_redraw()

func _on_target(target: Area2D) -> void:
	if hit or not target.has_method("take_hit"):
		return
	hit = true
	# Delay collision disable to avoid mutating physics flags in a callback.
	set_deferred("monitoring", false)
	set_deferred("collision_mask", 0)
	target.take_hit(24, "SPECIAL")
	if is_instance_valid(source):
		source.target_struck.emit(24)
	queue_redraw()

func _frame(index: int, dimensions: Vector2, opacity: float = 1.0) -> void:
	var size: Vector2 = ATLAS.get_size() / 4.0
	var col: int = index % 4
	var row: int = floori(float(index) / 4.0)
	draw_texture_rect_region(ATLAS, Rect2(-dimensions * 0.5, dimensions), Rect2(Vector2(col, row) * size, size), Color(1, 1, 1, opacity), false, true)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(direction), 1))
	if hit:
		var q: float = clampf(impact_age / IMPACT_TIME, 0.0, 0.9999)
		_frame(12 + mini(3, floori(q * 4)), Vector2(175 + q * 75, 158 + q * 75), 1.0 - q * 0.2)
		for i in range(2):
			draw_arc(Vector2.ZERO, 28 + q * (50 + i * 22), 0, TAU, 36, Color(0.85, 0.35, 1, 0.7 * (1.0 - q)), 4, false)
		for i in range(12):
			var axis := Vector2.from_angle(i * TAU / 12.0)
			draw_line(axis * (18 + q * 30), axis * (40 + q * 65), Color(0.67, 0.18, 1, 1.0 - q), 3, false)
	else:
		_frame(8 + (floori(age * 12.0) % 4), Vector2(144, 122))
		for i in range(9):
			var tail := Vector2(-29 - i * 13, sin(age * 28 + i * 2) * (8 + i))
			draw_rect(Rect2(tail, Vector2(4, 4)), Color(0.62, 0.12, 1, (9.0 - i) / 10.0))
		draw_arc(Vector2.ZERO, 26, age * 12, age * 12 + PI * 1.4, 25, Color(0.94, 0.73, 1, 0.7), 3, false)
	draw_set_transform(Vector2.ZERO)
