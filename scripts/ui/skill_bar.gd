extends RefCounted
const Book = preload("res://scripts/combat/skill_book.gd")
const READY := Color("d5b2ff")
const DIM := Color("797f94")

static func draw_bar(canvas: CanvasItem, fighter: Node2D, rect: Rect2, second: bool = false) -> void:
	var moves: Array = Book.ROSTER[fighter.fighter_profile]
	var keys: Array[String] = Book.keys(fighter.fighter_profile,second)
	var width: float = rect.size.x/6
	for slot in range(6):
		var move: String = fighter.slot_action(slot)
		if move.is_empty(): continue
		var cell := Rect2(rect.position+Vector2(slot*width,0),Vector2(width-4,rect.size.y))
		var cooldown: float = fighter.cheer_cooldown if move == "CHEER" else float(fighter.skills.cooldowns.get("SOY_BOMB" if move == "CAPPED_SHOVE" else move,0))
		var need_mark: bool = move == "SHADOW_RETURN" and fighter.shadow_return.target() == null
		var locked: bool = need_mark or (move == "BLOOD_PACT" and fighter.pact.buff_remaining > 0) or fighter.fighter_profile == "RED_CAP" and ((not fighter.red_awakened and slot < 5 and move != "CAPPED_SHOVE") or (fighter.red_awakened and slot == 5))
		var cost: float = fighter.skill_mana_cost(move)
		var enough: bool = fighter.energy >= cost
		var tint: Color = READY if enough and cooldown <= 0 and not locked else DIM
		canvas.draw_rect(cell,Color(0.035,0.045,0.075,0.95))
		canvas.draw_rect(cell,tint.darkened(0.45),false,1)
		var key_label: String = keys[slot]
		canvas.draw_string(ThemeDB.fallback_font,cell.position+Vector2(5,13),key_label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,tint)
		canvas.draw_string(ThemeDB.fallback_font,cell.position+Vector2(5,27),Book.SHORT_NAMES[move],HORIZONTAL_ALIGNMENT_LEFT,-1,10,tint)
		var status: String = "HIT SHURIKEN" if need_mark else ("AWAKEN FIRST" if locked and slot < 5 else ("PACT ACTIVE" if locked and move == "BLOOD_PACT" else ("ACTIVE FORM" if locked else ("%.1fs" % cooldown if cooldown > 0 else ("FREE" if cost == 0 else "%d MP" % cost)))))
		if move == "SHADOW_RETURN" and (fighter.shadow_return.active or cooldown > 0):
			status = "CASTING" if fighter.shadow_return.active else "%.1fs" % cooldown
		canvas.draw_string(ThemeDB.fallback_font,cell.position+Vector2(5,40),status,HORIZONTAL_ALIGNMENT_LEFT,-1,9,tint)
