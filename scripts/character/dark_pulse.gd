extends Area2D
## Projectile gameplay is unchanged: 24 damage, 620 px/s, one impact.
## Purple rotating shuriken replaces the fireball; legacy impact art is retained.
const Shuriken = preload("res://scripts/effects/purple_shuriken_art.gd")
const ATLAS: Texture2D = preload("res://assets/effects/dark_pulse_vfx.png")
const IMPACT_TIME: float = 0.28
var direction: int = 1
var source: Node2D
var age: float = 0.0
var impact_age: float = 0.0
var hit: bool = false
var spin_angle: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
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
	spin_angle += direction*delta*24
	position.x += float(direction) * 620.0 * delta
	if age > 1.8 or position.x < -80.0 or position.x > 1360.0:
		queue_free()
		return
	queue_redraw()

func _on_target(target: Area2D) -> void:
	if hit or (not target.has_method("take_hit") and not target.has_method("receive_attack")):
		return
	if target.has_method("can_be_hit_by") and not target.can_be_hit_by(source):
		return
	var inflicted: int = 24
	if target.has_method("receive_attack"):
		inflicted = target.receive_attack(24,"SPECIAL",source)
		if inflicted < 0:
			return
	else:
		target.take_hit(24,"SPECIAL",source)
	hit = true
	# Delay collision disable to avoid mutating physics flags in a callback.
	set_deferred("monitoring", false)
	set_deferred("collision_mask", 0)
	if is_instance_valid(source):
		if source.has_method("uses_dark_pulse") and source.uses_dark_pulse(): source.shadow_return.confirm(target)
		source.target_struck.emit(inflicted)
	queue_redraw()

func _frame(index: int, dimensions: Vector2, opacity: float = 1.0) -> void:
	var col: int = index % 4
	var row: int = floori(float(index) / 4.0)
	var size: Vector2 = ATLAS.get_size()
	var upper := Vector2(floorf(float(col) * size.x / 4.0), floorf(float(row) * size.y / 4.0))
	var lower := Vector2(floorf(float(col + 1) * size.x / 4.0), floorf(float(row + 1) * size.y / 4.0))
	draw_texture_rect_region(ATLAS, Rect2(-dimensions * 0.5, dimensions), Rect2(upper, lower - upper), Color(1, 1, 1, opacity), false, true)

func _draw() -> void:
	if hit:
		var q: float = clampf(impact_age / IMPACT_TIME, 0.0, 0.9999)
		_frame(12 + mini(3, floori(q * 4)), Vector2(175 + q * 75, 158 + q * 75), 1.0 - q * 0.2)
		for i in range(2):
			draw_arc(Vector2.ZERO, 28 + q * (50 + i * 22), 0, TAU, 36, Color(0.85, 0.35, 1, 0.7 * (1.0 - q)), 4, false)
		for i in range(12):
			var axis := Vector2.from_angle(i * TAU / 12.0)
			draw_line(axis * (18 + q * 30), axis * (40 + q * 65), Color(0.67, 0.18, 1, 1.0 - q), 3, false)
	else:
		for i in range(3,0,-1):
			Shuriken.draw(self,Vector2(-direction*i*19,0),spin_angle-direction*i*0.38,1-i*0.08,(4-i)*0.07)
		Shuriken.draw(self,Vector2.ZERO,spin_angle)
		draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
		for i in range(9):
			var tail := Vector2(-29 - i * 13, sin(age * 28 + i * 2) * (8 + i))
			draw_rect(Rect2(tail, Vector2(4, 4)), Color(0.62, 0.12, 1, (9.0 - i) / 10.0))
		for arc in range(2):
			var start: float = age*24+arc*PI
			draw_arc(Vector2.ZERO,43,start,start+1.7,18,Color(0.94,0.73,1,0.7),2,false)
	draw_set_transform(Vector2.ZERO)
