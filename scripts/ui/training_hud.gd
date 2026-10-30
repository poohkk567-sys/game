extends Control
const SkillBar = preload("res://scripts/ui/skill_bar.gd")
const SkillBook = preload("res://scripts/combat/skill_book.gd")
const INK := Color("0b1120")
const WHITE := Color("f3efff")
const MUTED := Color("aebbd0")
const PURPLE := Color("bb7aff")
const CYAN := Color("8cdae6")
@onready var stage: Node2D = get_parent().get_parent()
@onready var player: PhuzashiCharacter = stage.get_node("PHUZASHI")
@onready var crystal: Area2D = stage.get_node("TrainingCrystal")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Header and health card.
	_panel(Rect2(26,24,390,135), PURPLE)
	_text(Vector2(44,51), player.display_name, 25, WHITE)
	_text(Vector2(208,50), "D A R K   P U L S E", 13, PURPLE)
	_bar(Vector2(79,70), 311, player.health, Color("e69b9e"))
	_text(Vector2(44,83), "HP", 13, MUTED)
	_bar(Vector2(79,96), 311, player.energy, Color("a275e6"))
	_text(Vector2(44,109), "MP", 13, MUTED)
	_text(Vector2(356,83), "%05.1f" % player.health, 12, WHITE)
	_text(Vector2(356,109), "%03d" % int(player.energy), 12, WHITE)
	_bar(Vector2(79,122),311,player.guard_meter,Color("7bdbca"))
	_text(Vector2(44,135),"GD",13,MUTED)
	_text(Vector2(356,135),"%03d" % int(player.guard_meter),12,WHITE)
	_text(Vector2(470,43), "S O L O   T R A I N I N G", 13, CYAN)
	_text(Vector2(470,72), "MOUNTAIN SANCTUARY", 20, WHITE)
	_text(Vector2(470,94), "01  /  One fighter. Every move.", 12, Color("d4e2e8"))
	_panel(Rect2(951,24,303,113), CYAN)
	_text(Vector2(970,49), "TRAINING CRYSTAL", 15, WHITE)
	var last_move_label: String = crystal.last_move.replace("AIR_", "JUMP ").replace("_", " ")
	_text(Vector2(970,72), "LAST  %s  /  %d DMG" % [last_move_label,crystal.last_damage], 13, PURPLE)
	_text(Vector2(970,94), "TOTAL  %03d    HITS  %02d" % [crystal.total_damage,crystal.hit_count], 13, MUTED)
	var target_bound: bool = crystal.is_movement_locked()
	_text(Vector2(970,116), "BOUND  %.2f s" % crystal.movement_lock.remaining if target_bound else "COMBO  %02d" % crystal.combo, 13, PURPLE if target_bound else CYAN)
	# Compact state card keeps the center of the arena open.
	_panel(Rect2(26,155,207,117), Color("677eaa"))
	_text(Vector2(42,178), "MOVE / " + ("LEFT" if player.facing < 0 else "RIGHT"), 12, MUTED)
	var move_label: String = player.state_name.replace("AIR_", "JUMP ").replace("_", " ")
	if player.fighter_profile == "BLACK_COAT" and SkillBook.SHORT_NAMES.has(player.state_name): move_label = SkillBook.SHORT_NAMES[player.state_name]
	if player.combo_step > 0 and player.action_timer > 0.0:
		move_label = "%s %d/3" % [player.combo_family, player.combo_step]
	_text(Vector2(42,207), move_label, 23, WHITE)
	var phase: String = player.attack_phase()
	_text(Vector2(42,229), player.rig.renderer_name() if phase == "READY" else phase, 12, CYAN if phase == "ACTIVE" else PURPLE)
	if player.combo_step > 0:
		_text(Vector2(42,251), "NEXT INPUTS: %d  /  %s" % [player.combo_buffer, "J" if player.combo_family == "PUNCH" else "K"], 11, MUTED)
	else:
		var practiced: Dictionary = {}
		for move: String in player.visited:
			var base: String = move.trim_prefix("AIR_").get_slice("_",0) if player.specials_enabled else move
			var counted: bool = base in player.rig.CLIPS if player.specials_enabled else base not in ["BOUND","TRANSFORM","CHARGE","GUARD_BREAK"]
			if counted and move not in ["CHARGE","GUARD_BREAK"]:
				practiced[base] = true
		_text(Vector2(42,251), "%d / %d POSES PRACTICED" % [practiced.size(),12 if player.specials_enabled else 16], 11, MUTED)
	# Target label and health stay near the target rather than obscuring it.
	var target_x: float = crystal.position.x
	_text(Vector2(target_x-57,403), "PRACTICE TARGET", 11, Color("293c59"))
	if target_bound:
		_panel(Rect2(target_x-78,334,156,29),PURPLE)
		_text(Vector2(target_x-66,354),"BOUND  %.2f s" % crystal.movement_lock.remaining,15,WHITE)
	draw_rect(Rect2(target_x-42,414,84,4), Color("344b61"))
	draw_rect(Rect2(target_x-42,414,84*crystal.health/100.0,4), Color("d6bfef"))
	if player.charging or player.defense_feedback_time > 0:
		_text(Vector2(player.position.x-80,player.position.y-190),"CHARGING +7 MP/S" if player.charging else player.defense_feedback,15,CYAN)
	_text(Vector2(470,117),Gamepads.source_label("")+" / Q or LT: CHARGE 7 MP/S",12,CYAN)
	if player.message_time > 0.0:
		_text(Vector2(302,166), player.message, 13, WHITE)
	if stage.showcase:
		_panel(Rect2(445,203,390,46), PURPLE)
		_text(Vector2(463,232), "SHOWCASE  %02d / %02d   %s" % [stage.showcase_index+1, stage.SEQUENCE.size(), stage.SEQUENCE[maxi(0,stage.showcase_index)].replace("_", " ")], 16, WHITE)
	# Footer is inside the safe screen area, with every control visible.
	_panel(Rect2(26,634,1228,68),Color("69728c"))
	SkillBar.draw_bar(self,player,Rect2(34,638,680,46))
	_text(Vector2(730,655),"A/D MOVE  SPACE JUMP  J/K COMBO  L GUARD",11,WHITE)
	_text(Vector2(730,673),"Q/LT CHARGE  F1 HELP  F7 SETTINGS  F8 MENU",11,MUTED)
	_text(Vector2(42,696),"PAD: RT:1 | DOWN+X:2 | DOWN+B:3 | DOWN+LB:4 | DOWN+RB:5 | Y:ULT | TAB SWITCH | R RESET",10,MUTED)
	if player.debug_hitboxes:
		_text(Vector2(1021,627), "HITBOXES ON", 12, CYAN)
	if stage.show_help:
		_draw_move_list()
	if stage.paused:
		draw_rect(Rect2(0,0,1280,720), Color(0.02,0.025,0.06,0.72))
		_text(Vector2(537,338), "PAUSED", 44, WHITE)
		_text(Vector2(520,377), "ESC  /  Return to training", 16, PURPLE)

func _draw_move_list() -> void:
	_panel(Rect2(343,174,640,480), PURPLE)
	_text(Vector2(367,210), "MOVE LIST / " + player.display_name, 23, WHITE)
	var rows: Array = [
		["A/D + Shift","Walk / run",""],["Space + J/K","Jump attacks",""],
		["JJJ / KKK","Three-hit normal combos",""],["L / LB","Guard; timed press: Perfect Guard","GD 100"],
		["Q / LT","Charge mana; rounds start at 50","7 MP/s"]
	]
	var keys: Array[String] = SkillBook.keys(player.fighter_profile)
	var moves: Array = SkillBook.ROSTER[player.fighter_profile]
	for slot in range(6):
		if moves[slot].is_empty(): continue
		var action: String = player.slot_action(slot)
		rows.append([keys[slot],SkillBook.NAMES[action],"%d MP" % player.skill_mana_cost(action)])
	rows.append(["PAD","RT / Down+X / Down+B / Down+LB / Down+RB / Y",""])
	rows.append(["S+L / Down+LB","PHU: hit shuriken first / ASS: shove or bottle",""])
	rows.append(["E / L3","PHU Blink: free/no cooldown during stand","5 MP base"])
	rows.append(["Tab / R","Switch fighter / reset (50 MP)",""])
	rows.append(["F7 / R3","Assign and remap controllers",""])
	for i in range(rows.size()):
		var y: float = 241+i*18
		_text(Vector2(368,y), rows[i][0], 13, PURPLE)
		_text(Vector2(472,y), rows[i][1], 11, WHITE)
		_text(Vector2(787,y), rows[i][2], 11, CYAN)
	_text(Vector2(368,612), "Pad: A jump / X punch / B kick / Y ult / LB guard / RB run / LT charge / RT skill", 12, MUTED)

func _panel(rect: Rect2, accent: Color) -> void:
	draw_rect(rect, Color(0.025,0.045,0.085,0.93))
	draw_rect(rect, Color(0.39,0.46,0.6,0.5), false, 1)
	draw_rect(Rect2(rect.position,Vector2(rect.size.x,2)), accent)

func _bar(point: Vector2, width: float, value: float, color: Color) -> void:
	draw_rect(Rect2(point,Vector2(width,16)), Color("202b42"))
	draw_rect(Rect2(point+Vector2(2,2),Vector2((width-4)*clampf(value/100,0,1),12)), color)
	draw_line(point+Vector2(3,3),point+Vector2((width-4)*clampf(value/100,0,1),3),color.lightened(0.3),1)

func _text(point: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
