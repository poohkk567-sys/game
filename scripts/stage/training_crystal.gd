extends Area2D
## Inanimate practice target; not a fighter or a second character.
signal struck(damage: int, move_name: String)
const MovementLock = preload("res://scripts/combat/movement_lock.gd")
var movement_lock: Node
var health: int = 100
var total_damage: int = 0
var last_damage: int = 0
var last_move: String = "—"
var hit_count: int = 0
var combo: int = 0
var combo_clock: float = 0.0
var flash: float = 0.0
var elapsed: float = 0.0
var refill_clock: float = 0.0

func _ready() -> void:
	add_to_group("training_target")
	add_to_group("bind_targets")
	movement_lock = MovementLock.new()
	movement_lock.name = "MovementLock"
	add_child(movement_lock)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64, 136)
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	if not is_movement_locked():
		elapsed += delta
	flash = maxf(0.0, flash - delta)
	combo_clock = maxf(0.0, combo_clock - delta)
	if combo_clock <= 0:
		combo = 0
	if health <= 0:
		refill_clock += delta
		if refill_clock >= 1.3:
			health = 100
			refill_clock = 0.0
	queue_redraw()

func take_hit(damage: int, move_name: String) -> void:
	health = maxi(0, health - damage)
	total_damage += damage
	last_damage = damage
	last_move = move_name
	hit_count += 1
	combo += 1
	combo_clock = 2.0
	flash = 0.3
	struck.emit(damage, move_name)

func reset_target() -> void:
	movement_lock.clear()
	health = 100
	total_damage = 0
	last_damage = 0
	last_move = "—"
	hit_count = 0
	combo = 0
	combo_clock = 0.0
	flash = 0.0
	refill_clock = 0.0

func get_bind_anchor() -> Vector2:
	return global_position

func is_movement_locked() -> bool:
	return movement_lock.is_locked()

func apply_movement_lock(seconds: float) -> bool:
	movement_lock.apply(seconds)
	last_move = "DEMON_BIND"
	last_damage = 0
	return true

func _draw() -> void:
	var bob: float = sin(elapsed * 2) * 4
	var shake: float = 0.0 if is_movement_locked() else sin(elapsed * 90) * flash * 14
	draw_set_transform(Vector2(0, 75), 0, Vector2(1,0.23))
	draw_circle(Vector2.ZERO, 45, Color(0.04,0.06,0.13,0.23))
	draw_arc(Vector2.ZERO, 42, 0, TAU, 32, Color("bcb7e0"), 3)
	draw_set_transform(Vector2(shake,bob))
	var tint := Color("f5d4ff") if flash > 0 else Color("728fc8")
	var crystal := PackedVector2Array([Vector2(0,-60),Vector2(29,-18),Vector2(23,24),Vector2(0,54),Vector2(-23,24),Vector2(-29,-18)])
	draw_circle(Vector2.ZERO, 50, Color(0.5,0.3,0.9,0.07))
	draw_colored_polygon(crystal, Color("344966").lerp(tint, 0.45))
	draw_colored_polygon(PackedVector2Array([Vector2(0,-60),Vector2(29,-18),Vector2(0,8),Vector2(-29,-18)]), tint)
	draw_line(Vector2(0,-57), Vector2(0,51), Color("d8def1"), 2)
	draw_line(Vector2(-28,-18), Vector2(0,8), Color("b3c6f0"), 2)
	draw_line(Vector2(28,-18), Vector2(0,8), Color("b3c6f0"), 2)
	draw_arc(Vector2.ZERO, 42, elapsed, elapsed + PI * 1.2, 24, Color("bf9eff"), 2)
	if flash > 0:
		for i in range(12):
			var ray := Vector2.from_angle(i * TAU / 12)
			var radius: float = 35 + (0.3-flash) * 170
			draw_line(ray*radius, ray*(radius+10), Color(0.85,0.6,1,flash*3), 3)
