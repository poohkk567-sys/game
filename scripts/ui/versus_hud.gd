extends Control
const WHITE := Color("f6f1e8")
const MUTED := Color("c9c4bc")
const VIOLET := Color("bb85ff")
const GOLD := Color("efc46e")
@onready var stage: Node2D = get_parent().get_parent()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_card(Rect2(24,20,499,102),VIOLET)
	_card(Rect2(757,20,499,102),GOLD)
	_text(Vector2(42,49),"P1  /  PHUZASHI",22,WHITE)
	_text(Vector2(776,49),"P2  /  RED CAP",22,WHITE)
	_bar(Vector2(42,62),462,stage.p1.health,Color("ce8ab1"),false)
	_bar(Vector2(776,62),462,stage.p2.health,Color("ddb77c"),true)
	_bar(Vector2(42,91),462,stage.p1.energy,VIOLET,false,9)
	_bar(Vector2(776,91),462,stage.p2.energy,GOLD,true,9)
	_text(Vector2(43,116),"HP %03d    MP %03d" % [stage.p1.health,stage.p1.energy],11,MUTED)
	_text(Vector2(777,116),("HP %03d    MP %03d" % [stage.p2.health,stage.p2.energy]) + ("   AWAKENED" if stage.p2.red_awakened else "   ULTIMATE 100 MP"),11,MUTED)
	_card(Rect2(545,20,190,102),Color("69758b"))
	_center(640,47,"LOCAL VERSUS",13,MUTED)
	_center(640,88,"%02d" % ceili(stage.remaining),40,WHITE)
	_center(640,112,"FIRST TO 2",11,GOLD)
	for i in range(2):
		draw_circle(Vector2(471+i*22,41),6,VIOLET if stage.scores[0] > i else Color("333544"))
		draw_circle(Vector2(1205+i*22,41),6,GOLD if stage.scores[1] > i else Color("333544"))
	_center(640,148,"SCHOOL GATE  /  SUNSET",13,Color("f1d99f"))
	_label_fighter(stage.p1,"P1",VIOLET)
	_label_fighter(stage.p2,"P2",GOLD)
	if stage.phase == "READY":
		_banner("ROUND %d" % stage.round_number,"READY" if stage.phase_time < 1.15 else "FIGHT!",GOLD)
	elif stage.phase in ["ROUND_OVER","MATCH_OVER"]:
		_banner(stage.result,"MATCH COMPLETE  /  R REMATCH" if stage.phase == "MATCH_OVER" else "NEXT ROUND",VIOLET if stage.winner == 0 else GOLD)
	_card(Rect2(24,632,1232,67),Color("687184"))
	_text(Vector2(40,653),"P1  A/D MOVE   SPACE/W JUMP   SHIFT RUN   S CROUCH   J PUNCH   K KICK   L GUARD   U/I SKILLS   S+J BIND   AA/DD BLINK",12,WHITE)
	_text(Vector2(40,674),"P2  ARROWS MOVE/JUMP/CROUCH   CTRL RUN   NUM 1/2/3 or , . / = PUNCH/KICK/GUARD   NUM 5 or ; = CAP OFF ULTIMATE 100MP",11,GOLD)
	_text(Vector2(40,691),"F1 CONTROLS    F3 HITBOXES    R RESTART MATCH    ESC PAUSE    F6 SOLO TRAINING",10,MUTED)
	if stage.show_help:
		_help()
	if stage.paused:
		draw_rect(Rect2(0,0,1280,720),Color(0.025,0.035,0.06,0.78))
		_center(640,330,"PAUSED",46,WHITE)
		_center(640,370,"ESC TO RESUME   /   R RESTART",16,GOLD)

func _label_fighter(fighter: PhuzashiCharacter, label: String, color: Color) -> void:
	_center(fighter.position.x,616,label+(" / AWAKENED" if fighter.red_awakened else ""),12,color)
	if fighter.action_name == "TRANSFORM" and fighter.action_timer > 0:
		_center(fighter.position.x,fighter.position.y-195,fighter.red_transform_phase(),14,GOLD)
	if fighter.is_movement_locked():
		_center(fighter.position.x,fighter.position.y-175,"BOUND %.2fs" % fighter.movement_lock.remaining,14,VIOLET)

func _banner(title: String, subtitle: String, accent: Color) -> void:
	_card(Rect2(382,206,516,103),accent)
	_center(640,249,title,30,WHITE)
	_center(640,284,subtitle,18,accent)

func _help() -> void:
	_card(Rect2(230,174,820,365),VIOLET)
	_center(640,211,"TWO PLAYERS / ONE KEYBOARD",25,WHITE)
	var rows: Array = [
	 ["P1 PHUZASHI","P2 RED CAP"],
	 ["A / D : move     Space or W : jump","Left / Right : move     Up : jump"],
	 ["Shift : run     S : crouch","Ctrl : run     Down : crouch"],
	 ["J : punch     K : kick     L : guard","Num 1 : punch     Num 2 : kick     Num 3 : guard"],
	 ["J J J / K K K : three-stage combos","Num 1 1 1 / Num 2 2 2 : three-stage combos"],
	 ["Space + J/K : aerial punch/kick","Up + Num 1/2 : aerial punch/kick"],
	 ["U : Dark Pulse     I : dragon ultimate","Laptop keys: comma / period / slash"],
	 ["S+J : Demon Bind 25 MP / 0.7 seconds","Num 5 or ; : CAP OFF ULTIMATE / 100 MP"],
	 ["A A / D D : Shadow Blink 15 MP","Hold guard facing opponent to block attacks"]
	]
	for i in range(rows.size()):
		_text(Vector2(253,248+i*27),rows[i][0],12,VIOLET if i == 0 else WHITE)
		_text(Vector2(646,248+i*27),rows[i][1],12,GOLD if i == 0 else WHITE)
	_center(640,520,"F1 CLOSE   /   R REMATCH   /   ESC PAUSE",12,MUTED)

func _card(rect: Rect2, accent: Color) -> void:
	draw_rect(rect,Color(0.035,0.045,0.065,0.93))
	draw_rect(rect,Color(0.45,0.46,0.52,0.7),false,1)
	draw_rect(Rect2(rect.position,Vector2(rect.size.x,2)),accent)

func _bar(point: Vector2, width: float, value: float, color: Color, mirrored: bool, height: float = 17) -> void:
	draw_rect(Rect2(point,Vector2(width,height)),Color("252633"))
	var fill: float = (width-4)*clampf(value/100.0,0.0,1.0)
	var start: Vector2 = point+Vector2(width-2-fill if mirrored else 2,2)
	draw_rect(Rect2(start,Vector2(fill,height-4)),color)

func _center(x: float, y: float, line: String, size: int = 12, color: Color = WHITE) -> void:
	var width: float = ThemeDB.fallback_font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	_text(Vector2(x-width*0.5,y),line,size,color)

func _text(point: Vector2, line: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font,point,line,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
