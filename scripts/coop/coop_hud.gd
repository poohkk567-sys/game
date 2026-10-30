extends Control
const Rules = preload("res://scripts/coop/coop_rules.gd")
const WHITE := Color("f3edf8")
const MUTED := Color("b5bfd0")
const PURPLE := Color("c495ff")
const GOLD := Color("ffd089")
const CYAN := Color("8ce7e6")
var arena: Node3D
var retry: Button
var menu: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: Font = load("res://assets/fonts/NotoSansThai-Regular.ttf").duplicate()
	font.fallbacks = [ThemeDB.fallback_font]
	for i in range(2):
		var button := Button.new()
		button.text = "สู้ใหม่ / R" if i == 0 else "กลับเมนู / F8"
		button.position = Vector2(440+i*210,440)
		button.size = Vector2(190,44)
		button.add_theme_font_override("font",font)
		button.add_theme_font_size_override("font_size",18)
		add_child(button)
		if i == 0:
			retry = button
			button.pressed.connect(arena.restart)
		else:
			menu = button
			button.pressed.connect(arena.return_to_menu)

func _process(_delta: float) -> void:
	var visible_buttons: bool = arena.paused or arena.state in ["VICTORY","DEFEAT"]
	retry.visible = visible_buttons and not Gamepads.settings_open
	menu.visible = retry.visible
	queue_redraw()

func text(point: Vector2, line: String, size: int = 13, tint: Color = WHITE) -> void:
	draw_string(ThemeDB.fallback_font,point,line,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)

func center(point: Vector2, line: String, size: int = 13, tint: Color = WHITE) -> void:
	var width: float = ThemeDB.fallback_font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	text(point-Vector2(width*0.5,0),line,size,tint)

func panel(rect: Rect2, tint: Color) -> void:
	draw_style_box(style(tint),rect)
	draw_rect(Rect2(rect.position,Vector2(rect.size.x,2)),tint)

func style(tint: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.035,0.045,0.075,0.94)
	box.border_color = Color(tint,0.27)
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box

func bar(rect: Rect2, value: float, tint: Color) -> void:
	draw_rect(rect,Color("252c3f"))
	draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(value,0,1),rect.size.y)),tint)

func _draw() -> void:
	if not is_instance_valid(arena.boss): return
	for i in range(2):
		var player: Node3D = arena.team[i]
		var x: float = 24 if i == 0 else 922
		var tint: Color = PURPLE if i == 0 else GOLD
		panel(Rect2(x,22,334,108),tint)
		text(Vector2(x+14,47),"P%d / %s" % [i+1,player.display_name],18,tint)
		bar(Rect2(x+14,60,306,13),player.health/Rules.HEALTH,Color("e399a6") if i == 0 else Color("ddba81"))
		bar(Rect2(x+14,80,224,5),player.guard_meter/100,CYAN)
		text(Vector2(x+14,103),"HP %03d / 200   GD %03d" % [player.health,player.guard_meter],11,WHITE)
		text(Vector2(x+14,120),Gamepads.source_label(player.input_prefix)+"   /   DAMAGE %d" % player.damage_dealt,10,MUTED)
	panel(Rect2(380,22,520,108),Color("eb725a"))
	center(Vector2(640,43),"O B S I D I A N   W A R D E N",17)
	bar(Rect2(397,54,486,18),arena.boss.health/Rules.BOSS_HEALTH,Color("e36c62"))
	center(Vector2(640,68),"%03d / 900" % arena.boss.health,11,WHITE)
	bar(Rect2(397,79,486,4),arena.boss.stagger/140,GOLD)
	center(Vector2(640,101),"BREAK! / +20% DAMAGE" if arena.boss.state == "STAGGERED" else ("PHASE 2 / ENRAGED" if arena.boss.enraged else "PHASE 1 / STONE GUARDIAN"),11,GOLD if arena.boss.enraged else MUTED)
	center(Vector2(640,120),"CO-OP 3D / NORMAL ATTACKS ONLY   %02d:%02d" % [int(arena.elapsed)/60,int(arena.elapsed)%60],10,CYAN)
	if arena.boss.state == "WINDUP":
		panel(Rect2(368,143,544,40),GOLD)
		center(Vector2(640,165),Rules.ATTACK_LABELS[arena.boss.attack],14,GOLD)
		bar(Rect2(380,174,520,3),arena.boss.state_time/arena.boss.windup_time,Color("ff9676"))
	elif arena.boss.state == "STAGGERED": center(Vector2(640,164),"GUARDIAN STAGGERED / TEAM UP!",18,CYAN)
	for player: Node3D in arena.team:
		var world_point: Vector3 = player.global_position+Vector3(0,3.0 if not player.downed else 1.5,0)
		if arena.camera.is_position_behind(world_point): continue
		var point: Vector2 = arena.camera.unproject_position(world_point)
		var tint: Color = PURPLE if player.player_id == 0 else GOLD
		center(point,"P%d" % (player.player_id+1),13,tint)
		if player.downed:
			center(point+Vector2(0,19),"DOWN / PARTNER: HOLD Q, P OR LT",11,WHITE)
			bar(Rect2(point+Vector2(-52,27),Vector2(104,6)),player.revive_progress/Rules.REVIVE_TIME,CYAN)
		elif player.reviving: center(point+Vector2(0,19),"REVIVING...",11,CYAN)
		elif player.guard_break > 0: center(point+Vector2(0,19),"GUARD BREAK",12,Color("ff927c"))
	panel(Rect2(24,632,1232,68),Color("657c9c"))
	text(Vector2(40,653),"P1 WASD MOVE / SPACE JUMP / J K COMBO / L GUARD / SHIFT RUN / E DASH / Q REVIVE",12,PURPLE)
	text(Vector2(40,674),"P2 ARROWS MOVE / ENTER JUMP / NUM1, NUM2 ( , . ) COMBO / NUM3 ( / ) GUARD / CTRL RUN / NUM0 DASH / P REVIVE",11,GOLD)
	text(Vector2(40,691),"PAD: LEFT STICK / D-PAD MOVE | A JUMP | X / B COMBOS | LB GUARD | RB RUN | L3 DASH | HOLD LT REVIVE | F1 HELP | F7 SETTINGS | F8 MENU",10,MUTED)
	if arena.state == "READY":
		panel(Rect2(340,255,600,135),CYAN)
		center(Vector2(640,295),"ECLIPSE COURTYARD",30)
		center(Vector2(640,330),"PHUZASHI CHILL + ASSJIRO",22,PURPLE)
		center(Vector2(640,362),"TWO PLAYERS / ONE BOSS / FIGHT TOGETHER",13,CYAN)
	if arena.show_help: help_card()
	if arena.paused or arena.state in ["VICTORY","DEFEAT"]:
		draw_rect(Rect2(0,0,1280,720),Color(0.015,0.025,0.05,0.78))
		var title: String = "PAUSED" if arena.paused else ("BOSS DEFEATED" if arena.state == "VICTORY" else "TEAM DOWN")
		center(Vector2(640,292),title,42,CYAN if arena.state == "VICTORY" else WHITE)
		center(Vector2(640,335),"PHUZASHI CHILL + ASSJIRO / %02d:%02d" % [int(arena.elapsed)/60,int(arena.elapsed)%60],17,MUTED)
		center(Vector2(640,377),arena.pause_reason if not arena.pause_reason.is_empty() else "R / START: RETRY    F8: MENU" if not arena.paused else "ESC / START TO RESUME",14,GOLD)

func help_card() -> void:
	panel(Rect2(245,195,790,402),CYAN)
	center(Vector2(640,229),"CO-OP 3D / BASIC COMBAT TRIAL",24)
	var lines: Array[String] = [
		"WASD / ARROWS / LEFT STICK: move across the 3D ground; attacks aim at the boss.",
		"SPACE / ENTER / A: jump. J / NUM1 / X: punch. K / NUM2 / B: kick.",
		"Tap punch or kick three times to queue a three-hit combo. Jump + attack works too.",
		"L / NUM3 / LB: guard. Timed guard blocks all damage. Empty guard: 1 second stun.",
		"SHIFT / CTRL / RB: run. E / NUM0 / L3: quick dash (no invulnerability).",
		"A downed partner: approach within 1.8m and hold Q / P / LT for 1.8 seconds.",
		"Getting hit or leaving your partner resets the revive. Revive gives 70 HP.",
		"SWEEP: leave the front half-circle or jump. SLAM: leave the circle or jump.",
		"CHARGE: sidestep the marked lane. Tell positions are fixed before the attack.",
		"Fill BREAK to stagger the boss for 2 seconds. Phase 2 starts below half HP.",
		"Special skills / transformations are disabled in this trial. No friendly fire.",
		"F7 / R3: assign and remap pads. A single pad defaults to P2; F5 swaps sides.",
		"ESC / START pause. R retry. F8 title menu. F1 / BACK close this card."
	]
	for i in range(lines.size()): text(Vector2(267,262+i*24),lines[i],13,MUTED if i%2 else WHITE)
