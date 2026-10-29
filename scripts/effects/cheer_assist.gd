extends Node2D
## A cosmetic support runner; buffs are owned and timed by the actual fighter.
const Smoke = preload("res://scripts/effects/ninja_smoke.gd")
const CHEER_END: float = 2.35
const GRANT_TIME: float = 2.48
var caster: Node2D
var age: float = 0
var direction: int = 1
var start: Vector2
var destination: Vector2
var granted: bool = false
var vanished: bool = false
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
	if not is_instance_valid(caster) or not caster.uses_dark_pulse() or caster.health <= 0 or (caster.duel_mode and not caster.controls_enabled):
		queue_free()
		return
	age += delta
	if age < 0.45:
		global_position = start.lerp(destination,age/0.45)
	elif age < CHEER_END:
		global_position = destination
		sprite.play("CHEER")
	else:
		if not vanished:
			vanished = true
			sprite.visible = false
			Smoke.spawn(get_parent(),global_position,110)
		if age >= GRANT_TIME and not granted:
			granted = true
			caster.cheer_buff = 8.0
			caster.announce("CHEER COMPLETE / BIND 1.1s / MOVE +10% / 8 SECONDS")
			queue_free()
	queue_redraw()

func _draw() -> void:
	if age < 0.45 or age >= CHEER_END:
		return
	for i in range(5):
		var point := Vector2(sin(age*3+i*2)*38,-90-fmod(age*32+i*17,85))
		draw_circle(point,2,Color(1,0.65,0.8,0.8))
