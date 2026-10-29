extends Node2D
## A cosmetic support runner; buffs are owned and timed by the actual fighter.
var caster: Node2D
var age: float = 0
var direction: int = 1
var start: Vector2
var destination: Vector2
var granted: bool = false
var sprite: AnimatedSprite2D

func configure(source: Node2D) -> void:
	caster = source
	direction = caster.facing
	destination = caster.global_position+Vector2(-direction*100,0)
	start = destination+Vector2(-direction*270,0)
	position = start

func _ready() -> void:
	add_to_group("cheer_assists")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://assets/characters/phuzashi_clear/cheer_assist_frames.res")
	sprite.centered = false
	var factor: float = 148.0/float(sprite.sprite_frames.get_meta("source_height"))
	sprite.scale = Vector2(factor*direction,factor)
	sprite.position = -Vector2(512*direction,960)*factor
	add_child(sprite)
	sprite.play("RUN")
	z_index = 0
	get_parent().move_child(self,caster.get_index())

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or caster.health <= 0 or (caster.duel_mode and not caster.controls_enabled):
		queue_free()
		return
	age += delta
	if age < 0.45:
		global_position = start.lerp(destination,age/0.45)
	elif age < 2.35:
		global_position = destination
		sprite.play("CHEER")
		if not granted:
			granted = true
			caster.cheer_buff = 8.0
			caster.announce("CHEER / BIND 1.1s / MOVE +10% / 8 SECONDS")
	elif age < 2.8:
		sprite.play("RUN")
		global_position = destination.lerp(start,(age-2.35)/0.45)
		sprite.scale.x = -absf(sprite.scale.x)*direction
		sprite.position.x = -512*sprite.scale.x
	else:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if age < 0.45 or age > 2.35:
		return
	for i in range(5):
		var point := Vector2(sin(age*3+i*2)*38,-90-fmod(age*32+i*17,85))
		draw_circle(point,2,Color(1,0.65,0.8,0.8))
