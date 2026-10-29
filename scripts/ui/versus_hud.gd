extends Control
const SkillBar = preload("res://scripts/ui/skill_bar.gd")
const WHITE := Color("f6f1e8")
const MUTED := Color("c9c4bc")
const VIOLET := Color("bb85ff")
const GOLD := Color("efc46e")
@onready var stage: Node2D = get_parent().get_parent()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	_card(Rect2(24,20,499,140),VIOLET)
	_card(Rect2(757,20,499,140),GOLD)
	_text(Vector2(42,49),"P1  /  "+stage.p1.display_name,22,WHITE)
	_text(Vector2(776,49),"P2  /  "+stage.p2.display_name,22,WHITE)
	_bar(Vector2(42,62),462,stage.p1.health/stage.p1.max_health*100.0,Color("ce8ab1"),false)
	_bar(Vector2(776,62),462,stage.p2.health/stage.p2.max_health*100.0,Color("ddb77c"),true)
	_bar(Vector2(42,91),462,stage.p1.energy,VIOLET,false,9)
	_bar(Vector2(776,91),462,stage.p2.energy,GOLD,true,9)
	_bar(Vector2(42,113),462,stage.p1.guard_meter,Color("7bdbca"),false,9)
	_bar(Vector2(776,113),462,stage.p2.guard_meter,Color("7bdbca"),true,9)
	_text(Vector2(43,135),"HP %s/%03d    MP %03d    GUARD %03d" % [_hp(stage.p1.health),stage.p1.max_health,stage.p1.energy,stage.p1.guard_meter],11,MUTED)
	_text(Vector2(777,135),"HP %s/%03d    MP %03d    GUARD %03d" % [_hp(stage.p2.health),stage.p2.max_health,stage.p2.energy,stage.p2.guard_meter],11,MUTED)
	_text(Vector2(43,152),Gamepads.source_label("p1_")+_fighter_status(stage.p1),10,VIOLET)
	_text(Vector2(777,152),Gamepads.source_label("p2_")+_fighter_status(stage.p2),10,GOLD)
	_card(Rect2(545,20,190,140),Color("69758b"))
	_center(640,47,"LOCAL VERSUS",13,MUTED)
	_center(640,88,"%02d" % ceili(stage.remaining),40,WHITE)
	_center(640,112,"FIRST TO 2",11,GOLD)
	_center(640,144,"CHARGE +7 MP / SEC",10,MUTED)
	for i in range(2):
		draw_circle(Vector2(471+i*22,41),6,VIOLET if stage.scores[0] > i else Color("333544"))
		draw_circle(Vector2(1205+i*22,41),6,GOLD if stage.scores[1] > i else Color("333544"))
	_center(640,180,"SCHOOL GATE  /  SUNSET",13,Color("f1d99f"))
	_label_fighter(stage.p1,"P1",VIOLET)
	_label_fighter(stage.p2,"P2",GOLD)
	if stage.phase == "READY":
		_banner("ROUND %d" % stage.round_number,"READY" if stage.phase_time < 1.15 else "FIGHT!",GOLD)
	elif stage.phase in ["ROUND_OVER","MATCH_OVER"]:
		_banner(stage.result,"MATCH COMPLETE  /  START OR R REMATCH" if stage.phase == "MATCH_OVER" else "NEXT ROUND",VIOLET if stage.winner == 0 else GOLD)
	_card(Rect2(24,626,1232,86),Color("687184"))
	SkillBar.draw_bar(self,stage.p1,Rect2(30,630,594,46))
	SkillBar.draw_bar(self,stage.p2,Rect2(658,630,594,46),true)
	_text(Vector2(40,691),"P1 A/D SPACE J/K L Q | P2 ARROWS , . / P | PAD RT:1 DOWN+X:2 DOWN+B:3 DOWN+LB:4 DOWN+RB:5 Y:ULT",11,WHITE)
	_text(Vector2(40,706),"F1 MOVE LIST  F7/R3 SETTINGS  F8 MENU  ESC/START PAUSE  Q/LT CHARGE 7 MP/S  STARTING MP: 50/100",10,MUTED)
	if stage.show_help:
		_help()
	if stage.paused:
		draw_rect(Rect2(0,0,1280,720),Color(0.025,0.035,0.06,0.78))
		_center(640,330,"PAUSED",46,WHITE)
		_center(640,405,stage.pause_reason,14,MUTED)
		_center(640,370,"START / ESC RESUME   /   Y ON PAD OR R REMATCH",16,GOLD)

func _hp(value: float) -> String:
	return "%03d" % value if is_equal_approx(value,roundf(value)) else "%.1f" % value

func _label_fighter(fighter: PhuzashiCharacter, label: String, color: Color) -> void:
	_center(fighter.position.x,616,label+(" / AWAKENED" if fighter.red_awakened else ""),12,color)
	if fighter.action_name == "TRANSFORM" and fighter.action_timer > 0:
		_center(fighter.position.x,fighter.position.y-195,fighter.red_transform_phase(),14,GOLD)
	if fighter.cheer_buff > 0:
		_card(Rect2(fighter.position.x-137,fighter.position.y-255,274,27),Color("ffc5de"))
		_center(fighter.position.x,fighter.position.y-235,"CHEER %.1fs / BIND 1.1s / MOVE +10%%" % fighter.cheer_buff,12,Color("ffc5de"))
	if fighter.charging:
		_center(fighter.position.x,fighter.position.y-190,"CHARGING / +7 MP / SEC",13,color)
	if fighter.defense_feedback_time > 0:
		_center(fighter.position.x,fighter.position.y-210,fighter.defense_feedback,16,Color("b6ffff") if fighter.defense_feedback == "PERFECT GUARD" else Color("ffaf85"))
	if fighter.is_movement_locked():
		_center(fighter.position.x,fighter.position.y-175,"BOUND %.2fs" % fighter.movement_lock.remaining,14,VIOLET)

func _banner(title: String, subtitle: String, accent: Color) -> void:
	_card(Rect2(382,206,516,103),accent)
	_center(640,249,title,30,WHITE)
	_center(640,284,subtitle,18,accent)

func _help() -> void:
	_card(Rect2(160,194,960,411),VIOLET)
	_center(640,226,"KEYBOARD + GAMEPADS / LOCAL TWO PLAYER",23,WHITE)
	var rows: Array = [
	 ["P1 "+stage.p1.display_name,"P2 "+stage.p2.display_name],
	 ["A/D move   Space/W jump   Shift run","Arrows move/jump/crouch   Ctrl run"],
	 ["J punch   K kick   L guard   S crouch","Num 1/2/3 or , . / : punch/kick/guard"],
	 ["Q hold: charge 7 MP/s   U skill   I ultimate","P charge   Num4 / apostrophe: skill 1"],
	 ["S+J:2 S+K:3 S+L:4 S+Shift:5","Down+Num1/2/3:2/3/4 Down+Ctrl:5"]
	]
	for i in range(rows.size()):
		_text(Vector2(184,259+i*26),rows[i][0],12,VIOLET if i == 0 else WHITE)
		_text(Vector2(650,259+i*26),rows[i][1],11,GOLD if i == 0 else WHITE)
	_center(640,402,"GAMEPAD / XBOX LABELS (PLAYSTATION EQUIVALENTS BELOW)",13,GOLD)
	_center(640,428,"A / CROSS jump    X / SQUARE punch    B / CIRCLE kick    Y / TRIANGLE ultimate",13,WHITE)
	_center(640,453,"LB / L1 guard    RB / R1 run    LT / L2 charge    RT / R2 skill    Stick / D-pad move",13,WHITE)
	_center(640,478,"DOWN+X:2   DOWN+B:3   DOWN+LB:4   DOWN+RB:5   RT:1   Y:ULT",12,WHITE)
	_center(640,510,"1 PAD: P2 + P1 keyboard; F5 swaps pad side. 2 PADS: first=P1, second=P2.",12,GOLD)
	_center(640,535,"Normal hit +3 MP / finisher +5. Guard regenerates after 1s released; perfect guard +3 MP.",12,MUTED)
	_center(640,559,"Guard break: 1s stun, then 50 guard. Charge stops when moving, jumping or getting hit.",12,MUTED)
	_center(640,587,"BACK / F1 CLOSE   /   START / ESC PAUSE   /   PAUSED: Y ON PAD OR R REMATCH",12,MUTED)

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

func _fighter_status(fighter: PhuzashiCharacter) -> String:
	if fighter.fighter_profile == "BLACK_COAT":
		return " / PACT +30%% %.1fs" % fighter.pact.buff_remaining if fighter.pact.buff_remaining > 0 else " / BLOOD PACT 70 MP"
	if fighter.red_awakened: return " / AWAKENED -30% DAMAGE"
	if fighter.fighter_profile == "RED_CAP": return " / TRANSFORM TO UNLOCK SKILLS"
	if fighter.fighter_profile == "MUAY_THAI": return " / BROWN GORILLA STAND"
	return " / CHEER %.1fs" % fighter.cheer_buff if fighter.cheer_buff > 0 else " / DARK PULSE"
