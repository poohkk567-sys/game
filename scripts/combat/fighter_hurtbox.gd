extends Area2D
## Separate layer-four hurtbox; the body still collides only with the floor.
@onready var fighter: PhuzashiCharacter = get_parent()
var shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	add_child(shape)
	_sync()

func _physics_process(_delta: float) -> void:
	_sync()

func _sync() -> void:
	var low: bool = fighter.state_name in ["CROUCH","FALL"]
	var height: float = fighter.low_height() if low else fighter.standing_height()
	shape.shape.size = Vector2(50,height)
	shape.position = Vector2(0,-height*0.5)

func can_be_hit_by(attacker: Node2D) -> bool:
	return attacker != fighter and fighter.health > 0.0 and not fighter.blink_invulnerable()

func receive_attack(damage: int, move_name: String, attacker: Node2D) -> int:
	return fighter.receive_attack(damage,move_name,attacker)

func was_last_hit_blocked() -> bool:
	return fighter.last_hit_blocked
