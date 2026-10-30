extends Node2D
## One confirmed shuriken mark, a visible hand seal, rear strike and safe return.
const Hit = preload("res://scripts/combat/skill_hit.gd")
const Smoke = preload("res://scripts/effects/ninja_smoke.gd")
const CAST: SpriteFrames = preload("res://assets/characters/ninja_cast/cast_frames.res")
@onready var fighter: Node2D = get_parent()
var marked: WeakRef
var victim: WeakRef
var active: bool = false
var away: bool = false
var returned: bool = false
var connected: bool = false
var origin: Vector2
var origin_facing: int = 1
var seal: AnimatedSprite2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	seal = AnimatedSprite2D.new()
	seal.sprite_frames = CAST
	seal.centered = false
	seal.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://assets/characters/drafts/alpha_cutout.gdshader")
	seal.material = cutout
	seal.visible = false
	add_child(seal)

func _live(ref: WeakRef) -> Node2D:
	if ref == null: return null
	var body: Object = ref.get_ref()
	if not is_instance_valid(body) or body.is_queued_for_deletion() or not body.is_inside_tree(): return null
	if "health" in body and body.health <= 0: return null
	return body as Node2D

func target() -> Node2D:
	return _live(marked)

func confirm(hitbox: Node2D) -> void:
	if not fighter.uses_dark_pulse() or fighter.health <= 0: return
	var body: Node2D = hitbox.get_parent() if hitbox.has_method("was_last_hit_blocked") else hitbox
	if body == fighter: return
	marked = weakref(body)
	if target() != null: fighter.announce("SHURIKEN MARK / SHADOW RETURN READY")

func begin() -> void:
	victim = marked
	marked = null
	active = true
	away = false
	returned = false
	connected = false
	origin = fighter.global_position
	origin_facing = fighter.facing

func reset(restore_home: bool = false) -> void:
	if restore_home: cancel()
	active = false
	away = false
	marked = null
	victim = null
	if is_instance_valid(seal): seal.visible = false
	queue_redraw()

func cancel() -> void:
	if away: _return_home()
	active = false
	if is_instance_valid(seal): seal.visible = false

func _physics_process(_delta: float) -> void:
	if marked != null and target() == null: marked = null
	if fighter.health <= 0 or (fighter.duel_mode and not fighter.controls_enabled):
		reset(true)
		return
	if active:
		if fighter.action_name != "SHADOW_RETURN" or fighter.action_timer <= 0 or fighter.is_movement_locked():
			cancel()
		elif fighter.impact_pause <= 0:
			var p: float = fighter.action_progress()
			if not away and not returned and p >= 0.35: _depart()
			if away and p >= 0.48 and p < 0.65: _strike()
			if away and p >= 0.75: _return_home()
	present()
	queue_redraw()

func _depart() -> void:
	var body: Node2D = _live(victim)
	if body == null:
		cancel()
		fighter.action_timer = 0
		return
	var look: int = int(body.facing) if "facing" in body else -origin_facing
	var x: float = body.global_position.x-look*100
	# At a wall use the open side instead of overlapping or leaving the camera.
	if x < 75 or x > 1205: x = body.global_position.x+look*100
	Smoke.spawn(fighter.get_parent(),fighter.global_position,155)
	fighter.global_position = Vector2(clampf(x,75,1205),body.global_position.y if body.has_method("standing_height") else origin.y)
	fighter.facing = 1 if body.global_position.x > fighter.global_position.x else -1
	fighter.velocity = Vector2.ZERO
	away = true
	Smoke.spawn(fighter.get_parent(),fighter.global_position,155)

func _strike() -> void:
	if connected: return
	var body: Node2D = _live(victim)
	if body == null: return
	var center: Vector2 = fighter.global_position+Vector2(fighter.facing*95,-82)
	for hitbox: Node2D in Hit.query(fighter,Rect2(center-Vector2(85,75),Vector2(170,150))):
		var hit_body: Node2D = hitbox.get_parent() if hitbox.has_method("was_last_hit_blocked") else hitbox
		if hit_body != body: continue
		if Hit.apply(fighter,hitbox,26,"SHADOW_RETURN",false,230) >= 0:
			connected = true
			return

func _return_home() -> void:
	Smoke.spawn(fighter.get_parent(),fighter.global_position,150)
	var home: Vector2 = origin
	if fighter.duel_mode and is_instance_valid(fighter.opponent):
		var other: Node2D = fighter.opponent
		if absf(other.global_position.y-home.y) < 90 and absf(other.global_position.x-home.x) < 88:
			var options: Array[float] = [other.global_position.x-88,other.global_position.x+88]
			var distance: float = INF
			for x: float in options:
				if x >= 75 and x <= 1205 and absf(x-origin.x) < distance:
					home.x = x
					distance = absf(x-origin.x)
	fighter.global_position = home
	fighter.facing = origin_facing
	fighter.velocity = Vector2.ZERO
	if fighter.is_movement_locked(): fighter.movement_lock.anchor = home
	away = false
	returned = true
	Smoke.spawn(fighter.get_parent(),home,150)

func present() -> void:
	seal.visible = active and fighter.action_name == "SHADOW_RETURN" and fighter.action_timer > 0 and fighter.action_progress() < 0.35
	if not seal.visible: return
	var clip: String = "SEAL_CHILL" if fighter.fighter_profile == "PHUZASHI_CHILL" else "SEAL_CLASSIC"
	seal.animation = clip
	seal.frame = mini(7,floori(fighter.action_progress()/0.35*8))
	var factor: float = 156.0/float(CAST.get_meta("heights")[clip])
	seal.scale = Vector2(fighter.facing*factor,factor)
	seal.position = -Vector2(fighter.facing*512,960)*factor
	fighter.rig.visible = false

func _draw() -> void:
	var body: Node2D = target()
	if body == null: return
	var point: Vector2 = to_local(body.global_position+Vector2(0,-body.standing_height()-18 if body.has_method("standing_height") else -82))
	for i in range(4):
		var angle: float = fighter.elapsed*2+i*PI/2
		var tip: Vector2 = point+Vector2.from_angle(angle)*11
		draw_line(point+Vector2.from_angle(angle)*4,tip,Color(0.85,0.5,1,0.95),3,false)
	draw_arc(point,15,0,TAU,20,Color(0.69,0.25,1,0.75),1,false)
