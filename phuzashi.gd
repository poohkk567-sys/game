extends CharacterBody2D
class_name PhuzashiCharacter
## PHUZASHI: original 64x64 transparent PNG, displayed at 2x with no re-painting.
## Motion bob and hit effects are a proof of concept, NOT finished sprite animations.

const WALK_SPEED: float = 165.0
const RUN_SPEED: float = 285.0
const AIR_SPEED: float = 170.0
const JUMP_VELOCITY: float = -460.0
const GRAVITY: float = 1200.0
const ACCELERATION: float = 1700.0
const GROUND_Y: float = 448.0

@onready var sprite: Sprite2D = $Sprite2D

var health: float = 100.0
var energy: float = 100.0
var facing: int = 1
var state_name: String = "IDLE"
var action_name: String = ""
var action_timer: float = 0.0
var action_duration: float = 1.0
var elapsed: float = 0.0
var particle_clock: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    match key_event.physical_keycode:
        KEY_SPACE:
            if is_on_floor() and action_timer <= 0.0:
                velocity.y = JUMP_VELOCITY
        KEY_J:
            _start_action("PUNCH", 0.20, 0.0)
        KEY_K:
            _start_action("KICK", 0.28, 0.0)
        KEY_U:
            _start_action("SPECIAL", 0.45, 25.0)
        KEY_I:
            _start_action("ULTIMATE", 0.90, 60.0)
        KEY_R:
            global_position = Vector2(200.0, GROUND_Y)
            velocity = Vector2.ZERO
            health = 100.0
            energy = 100.0
            action_timer = 0.0
            state_name = "IDLE"

func _start_action(new_action: String, duration: float, cost: float) -> void:
    if action_timer > 0.0 or not is_on_floor() or energy < cost:
        return
    energy -= cost
    action_name = new_action
    action_duration = duration
    action_timer = duration
    velocity.x = 0.0

func _physics_process(delta: float) -> void:
    elapsed += delta
    particle_clock += delta
    energy = minf(100.0, energy + delta * 6.0)
    action_timer = maxf(0.0, action_timer - delta)

    var left: bool = Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
    var right: bool = Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
    var sprint: bool = Input.is_key_pressed(KEY_SHIFT)
    var crouch: bool = Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    var guard: bool = Input.is_physical_key_pressed(KEY_L)
    var move_axis: float = float(int(right) - int(left))

    if move_axis != 0.0 and action_timer <= 0.0:
        facing = 1 if move_axis > 0.0 else -1

    var on_ground: bool = is_on_floor()
    var locked: bool = action_timer > 0.0 or (on_ground and (crouch or guard))
    var target_speed: float = RUN_SPEED if sprint else WALK_SPEED
    var target_x: float = 0.0 if locked else move_axis * (target_speed if on_ground else AIR_SPEED)
    velocity.x = move_toward(velocity.x, target_x, ACCELERATION * delta)
    if not on_ground:
        velocity.y += GRAVITY * delta

    move_and_slide()
    position.x = clampf(position.x, 55.0, 905.0)

    if not is_on_floor():
        state_name = "JUMP" if velocity.y < 0.0 else "FALL"
    elif action_timer > 0.0:
        state_name = action_name
    elif crouch:
        state_name = "CROUCH"
    elif guard:
        state_name = "GUARD"
    elif absf(velocity.x) > 20.0:
        state_name = "RUN" if sprint else "WALK"
    else:
        state_name = "IDLE"

    # Gentle transform-only animation until proper per-state sprite sheets arrive.
    var bob: float = 0.0
    if state_name == "IDLE":
        bob = roundf(sin(elapsed * 3.5) * 0.6)
    elif state_name == "WALK":
        bob = roundf(absf(sin(elapsed * 12.0)) * 1.0)
    elif state_name == "RUN":
        bob = roundf(absf(sin(elapsed * 18.0)) * 2.0)
    sprite.position.y = -52.0 - bob
    sprite.flip_h = facing < 0
    sprite.modulate = Color(0.72, 0.57, 1.0) if state_name == "GUARD" else Color.WHITE
    queue_redraw()

func _draw() -> void:
    # Ground shadow, drawn behind the sprite but over the arena artwork.
    draw_ellipse_shadow()
    if action_timer <= 0.0:
        return
    var progress: float = 1.0 - action_timer / maxf(action_duration, 0.001)
    var d: float = float(facing)
    if action_name == "PUNCH":
        draw_line(Vector2(d * 15.0, -72.0), Vector2(d * 54.0, -72.0), Color(1.0, 0.86, 0.52, 0.85), 8.0, true)
        draw_circle(Vector2(d * 57.0, -72.0), 6.0 + progress * 4.0, Color(1.0, 0.91, 0.64, 1.0 - progress))
    elif action_name == "KICK":
        draw_arc(Vector2(d * 22.0, -51.0), 32.0, -1.6, 1.0, 18, Color(0.7, 0.9, 1.0, 0.9 - progress * 0.5), 7.0, true)
    elif action_name == "SPECIAL":
        var radius: float = 17.0 + progress * 75.0
        var center: Vector2 = Vector2(d * (30.0 + progress * 110.0), -65.0)
        draw_circle(center, radius * 0.48, Color(0.47, 0.11, 1.0, 0.50 * (1.0 - progress)))
        draw_arc(center, radius, 0.0, TAU, 30, Color(0.78, 0.25, 1.0, 0.85 * (1.0 - progress)), 6.0, true)
    elif action_name == "ULTIMATE":
        var radius: float = 28.0 + progress * 160.0
        var center: Vector2 = Vector2(d * 48.0, -60.0)
        draw_circle(center, radius, Color(0.45, 0.02, 0.8, 0.20 * (1.0 - progress)))
        draw_arc(center, radius, -PI / 2.0, PI * 1.25, 40, Color(0.78, 0.14, 1.0, 0.95 * (1.0 - progress)), 10.0, true)
        draw_arc(center, radius * 0.68, 0.0, TAU, 30, Color(0.94, 0.6, 1.0, 0.9 * (1.0 - progress)), 5.0, true)

func draw_ellipse_shadow() -> void:
    draw_set_transform(Vector2(0.0, 2.0), 0.0, Vector2(1.5, 0.27))
    draw_circle(Vector2.ZERO, 22.0, Color(0.015, 0.028, 0.06, 0.32))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
