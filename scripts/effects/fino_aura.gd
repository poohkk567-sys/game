extends Node2D
const Guardian = preload("res://scripts/effects/side_guardian_art.gd")
var guardian: AnimatedSprite2D
const Art = preload("res://scripts/effects/skill_art.gd")
@onready var fighter: Node2D = get_parent()

func _ready() -> void:
	guardian = Guardian.create(self)

func _physics_process(_delta: float) -> void:
	visible = fighter.is_fino_active()
	guardian.visible = visible
	if visible:
		Guardian.present(guardian,"PURPLE",fighter.elapsed,fighter.facing,286,Vector2(-50*fighter.facing,4),sin(fighter.action_progress()*PI)*0.72)
		queue_redraw()

func _draw() -> void:
	if not fighter.is_fino_active(): return
	var p: float = fighter.action_progress()
	var opacity: float = sin(p*PI)
	var d: float = fighter.facing
	draw_set_transform(Vector2.ZERO,0,Vector2(d,1))
	Art.frame(self,1+floori(fighter.elapsed*12)%3,Vector2(-80,-32),Vector2(165,112),opacity*0.7)
	Art.frame(self,1+floori(fighter.elapsed*12+1)%3,Vector2(85,-18),Vector2(140,95),opacity*0.6)
	for i in range(13):
		var x: float = -135+i*20
		var h: float = 22+sin(fighter.elapsed*18+i*2.7)*16
		var flame := PackedVector2Array([Vector2(x-12,-2),Vector2(x-8,-h*0.55),Vector2(x+4,-h-18),Vector2(x+11,-h*0.35),Vector2(x+15,-2)])
		draw_colored_polygon(flame,Color(0.45,0.04,0.9,opacity*0.8))
		draw_line(Vector2(x,-3),Vector2(x+4,-h-11),Color(0.9,0.6,1,opacity*0.7),3,false)
	for i in range(16):
		var point := Vector2(-155+fmod(i*37+fighter.elapsed*140,300),-fmod(i*23+fighter.elapsed*90,220))
		draw_rect(Rect2(point,Vector2(3,7)),Color(0.77,0.23,1,opacity*0.65))
	draw_set_transform(Vector2.ZERO)
