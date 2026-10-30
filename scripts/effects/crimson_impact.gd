extends Node2D
## A confirmed contact, anchored in world space rather than following the caster.
const Art = preload("res://scripts/effects/black_skill_art.gd")
var age: float = 0
var direction: int = 1
var heavy: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 3
	add_to_group("six_skill_effects")

func _physics_process(delta: float) -> void:
	age += delta
	if age > 0.30: queue_free()
	queue_redraw()

func _draw() -> void:
	var p: float = clampf(age/0.30,0,1)
	draw_set_transform(Vector2.ZERO,0,Vector2(direction,1))
	Art.frame(self,"CRUSH" if heavy else "DRIVE",0.50+p*0.49,Vector2.ZERO,Vector2.ONE*(145 if heavy else 100),1-p)
	for i in range(12):
		var ray := Vector2.from_angle(i*TAU/12+0.2)
		draw_line(ray*(8+p*20),ray*(18+p*(90 if heavy else 55)),Color(1,0.12,0.20,1-p),3 if heavy else 2,false)
	draw_set_transform(Vector2.ZERO)
