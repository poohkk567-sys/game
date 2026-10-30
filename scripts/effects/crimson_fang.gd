extends Node2D
## A finite, blockable mid-height wave; one contact per cast, no homing.
const Hit = preload("res://scripts/combat/skill_hit.gd")
const Art = preload("res://scripts/effects/black_skill_art.gd")
const Impact = preload("res://scripts/effects/crimson_impact.gd")
const SPEED: float = 590.0
const RANGE: float = 560.0
var source: Node2D
var direction: int = 1
var travelled: float = 0
var age: float = 0
var burst: float = 0
var connected: bool = false

func configure(caster: Node2D) -> void:
	source = caster
	direction = caster.facing
	position = caster.global_position+Vector2(direction*48,-84)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 2
	add_to_group("six_skill_effects")
	add_to_group("crimson_fangs")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(source) or source.health <= 0 or (source.duel_mode and not source.controls_enabled):
		queue_free()
		return
	if source.impact_pause > 0: return
	age += delta
	if connected:
		burst += delta
		if burst >= 0.18: queue_free()
	else:
		var step: float = minf(SPEED*delta,RANGE-travelled)
		var midpoint: Vector2 = global_position+Vector2(direction*step*0.5,0)
		position.x += direction*step
		travelled += step
		for target: Node2D in Hit.query(source,Rect2(midpoint-Vector2(22+step*0.5,48),Vector2(44+step,96))):
			var amount: int = Hit.apply(source,target,22,"BLOOD_FANG",false,210)
			if amount < 0: continue
			connected = true
			var impact := Impact.new()
			impact.position = global_position
			impact.direction = direction
			get_parent().add_child(impact)
			break
		if not connected and travelled >= RANGE: queue_free()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
	var fade: float = 1-burst/0.18 if connected else minf(1,(RANGE-travelled)/60)
	Art.frame(self,"FANG",0.25+fmod(age*8,0.70),Vector2(-18,0),Vector2(180,148),fade)
	for i in range(6):
		var q: float = fmod(age*2+i/6.0,1)
		draw_line(Vector2(-q*120,-14+i*6),Vector2(-q*120-16,-14+i*6),Color(1,0.09,0.18,(1-q)*0.55*fade),2,false)
	draw_set_transform(Vector2.ZERO)
