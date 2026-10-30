extends Node
## Reusable per-target lock. Other actors/AI keep ticking; only this body is pinned.
signal released
var remaining: float = 0.0
var anchor: Vector2 = Vector2.ZERO
var applied_frame: int = -1

func _ready() -> void:
	# Run after the owner's AI/physics so an attempted move cannot escape the lock.
	process_priority = 100
	add_to_group("movement_locks")

func apply(seconds: float) -> void:
	remaining = maxf(remaining,seconds)
	anchor = get_parent().global_position
	applied_frame = Engine.get_physics_frames()
	_pin()

func is_locked() -> bool:
	return remaining > 0.0

func clear() -> void:
	remaining = 0.0

func _physics_process(delta: float) -> void:
	if remaining <= 0.0:
		return
	_pin()
	if Engine.get_physics_frames() != applied_frame:
		remaining = maxf(0.0,remaining-delta)
		if remaining < 0.00001:
			remaining = 0.0
			released.emit()

func _pin() -> void:
	var owner_body: Node2D = get_parent()
	owner_body.global_position = anchor
	if owner_body is CharacterBody2D:
		(owner_body as CharacterBody2D).velocity = Vector2.ZERO
