extends RefCounted
## One authoritative damage path for melee, waves and thrown bottles.

static func apply(source: Node2D, target: Node2D, damage: int, move: String, launch: bool = false, push: float = 150) -> int:
	if not is_instance_valid(source) or not is_instance_valid(target): return -1
	if target.has_method("can_be_hit_by") and not target.can_be_hit_by(source): return -1
	var victim: Node2D = target.get_parent() if target.has_method("was_last_hit_blocked") else target
	if victim == source: return -1
	var amount: int = damage
	if target.has_method("receive_attack"):
		amount = target.receive_attack(damage,move,source)
	elif target.has_method("take_hit"):
		target.take_hit(damage,move,source)
	else: return -1
	if amount < 0: return -1
	var blocked: bool = target.was_last_hit_blocked() if target.has_method("was_last_hit_blocked") else false
	if victim.has_method("bind_lock_duration"):
		if not blocked:
			victim.skills.push_velocity = load("res://scripts/combat/combat_reaction.gd").direction(victim,source)*push
			victim.skills.push_remaining = 0.45 if move == "CAPPED_SHOVE" else 0.14
			victim.velocity.x = victim.skills.push_velocity
			if launch and not victim.launched_once:
				victim.launched_once = true
				victim.velocity.y = -470
				victim.action_duration = maxf(victim.action_duration,0.55)
				victim.action_timer = maxf(victim.action_timer,0.55)
	source.target_struck.emit(amount)
	return amount

static func query(source: Node2D, rect: Rect2) -> Array[Node2D]:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = Transform2D(0,rect.get_center())
	params.collision_mask = 4
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var result: Array[Node2D] = []
	for hit: Dictionary in source.get_world_2d().direct_space_state.intersect_shape(params):
		result.append(hit.collider)
	return result
