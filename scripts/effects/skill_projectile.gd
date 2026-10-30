extends Node2D
## Telegraphs precede real collision. Each target can be hit only once per cast.
const Hit = preload("res://scripts/combat/skill_hit.gd")
const Art = preload("res://scripts/effects/skill_art.gd")
var source: Node2D
var kind: String
var direction: int
var age: float = 0
var velocity: Vector2
var struck: Dictionary = {}
var burst: bool = false
var burst_age: float = 0
var floor_y: float = 586

func configure(caster: Node2D, action: String) -> void:
	source = caster
	kind = action
	direction = caster.facing
	floor_y = caster.global_position.y
	global_position = caster.global_position
	if kind == "SOY_BOMB":
		position += Vector2(direction*54,-130)
		velocity = Vector2(direction*420,-350)
	else: position.x += direction*95

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("six_skill_effects")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source) or (source.duel_mode and not source.controls_enabled):
		queue_free()
		return
	if source.impact_pause > 0: return
	age += delta
	if kind == "SOY_BOMB":
		if not burst:
			velocity.y += 1000*delta
			position += velocity*delta
			if position.y >= floor_y-8:
				position.y = floor_y-8
				burst = true
			else:
				for target: Node2D in Hit.query(source,Rect2(global_position-Vector2(13,22),Vector2(26,44))):
					if _hit(target,22,"SOY_BOMB",false,170):
						burst = true
						break
		if burst:
			burst_age += delta
			for target: Node2D in Hit.query(source,Rect2(global_position-Vector2(76,70),Vector2(152,140))):
				_hit(target,22,"SOY_BOMB",false,170)
			if burst_age > 0.32: queue_free()
	else:
		position.x += direction*380*delta
		for target: Node2D in Hit.query(source,Rect2(global_position-Vector2(46,70),Vector2(92,70))):
			_hit(target,24,"GORILLA_QUAKE",false,180)
		if age > 1.35: queue_free()
	if age > 2.0 or position.x < -100 or position.x > 1380: queue_free()
	queue_redraw()

func _hit(target: Node2D, damage: int, move: String, launch: bool, push: float) -> bool:
	if struck.has(target.get_instance_id()): return false
	var amount: int = Hit.apply(source,target,damage,move,launch,push)
	if amount < 0: return false
	struck[target.get_instance_id()] = true
	return true

func _draw() -> void:
	if kind == "SOY_BOMB":
		if not burst:
			draw_set_transform(Vector2.ZERO,age*direction*9)
			draw_style_box(_bottle_style(),Rect2(-9,-14,18,28))
			draw_rect(Rect2(-5,-10,3,18),Color("665047"))
			draw_rect(Rect2(-10,-4,20,9),Color("e7d4a3"))
			draw_rect(Rect2(-5,-21,10,8),Color("b73532"))
			draw_set_transform(Vector2.ZERO)
		else:
			var p: float = burst_age/0.32
			Art.frame(self,12+mini(3,floori(p*4)),Vector2(0,-20),Vector2(190,145),1-p*0.3)
			for i in range(22):
				var a: float = i*TAU/22
				var ray := Vector2(cos(a),sin(a)*0.65-0.5)
				var point: Vector2 = ray*(15+p*85)+Vector2(0,p*p*30)
				draw_circle(point,maxf(1,6*(1-p)),Color(Color("21100d"),1-p))
				draw_line(point,point+Vector2(-3,-7),Color(Color("8d6850"),1-p),2)
		return
	var color := Color("ff60be")
	var p: float = fmod(age*5,1)
	var opacity: float = minf(1,(1.35-age)*4)
	for i in range(7):
		var x: float = -48+i*16
		var h: float = (70+sin(i*12.1)*40)*(sin(p*PI)*0.65+0.65)
		var points := PackedVector2Array([Vector2(x-13,0),Vector2(x-8,-h*0.5),Vector2(x+sin(i*2.1)*12,-h),Vector2(x+9,-h*0.36),Vector2(x+14,0)])
		draw_colored_polygon(points,Color(color.darkened(0.35),opacity*0.85))
		draw_line(Vector2(x,0),points[2],Color(color.lightened(0.65),opacity),2)
	for i in range(16):
		var point := Vector2(sin(i*17.3)*65,-fmod(age*160+i*17,150))
		draw_rect(Rect2(point,Vector2(3,6)),Color(color.lightened(0.35),opacity*0.75))

func _bottle_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c100b")
	style.border_color = Color("0b0809")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style
