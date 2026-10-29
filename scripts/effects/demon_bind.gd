extends Node2D
## Smoke teleport, then a compact rear grapple. The victim owns the real lock.
const FRAMES: SpriteFrames = preload("res://assets/effects/ninja_grapple_frames.res")
const EDGES: Shader = preload("res://assets/effects/side_guardians/spectral_aura.gdshader")
const Smoke = preload("res://scripts/effects/ninja_smoke.gd")
const LOCK_TIME: float = 0.7
const SUMMON_TIME: float = 0.12
const FLIGHT_TIME: float = 0.22 # Hidden teleport interval; not a travelling projectile.
const RELEASE_TIME: float = 0.22
const REAR_OFFSET: float = 64
var lock_time: float = LOCK_TIME
var caster: Node2D
var target: Node2D
var origin: Vector2
var fallback: Vector2
var direction: int = 1
var phase: String = "SUMMON"
var phase_age: float = 0
var age: float = 0
var caught: bool = false
var empowered: bool = false
var guardian: AnimatedSprite2D
var sprite: AnimatedSprite2D
var visual_height: float = 0
var grip_position: Vector2

func configure(source: Node2D, victim: Node2D) -> void:
	caster = source
	empowered = source.uses_dark_pulse() and source.cheer_buff > 0
	lock_time = source.bind_lock_duration()
	target = victim
	direction = source.facing
	origin = source.global_position+Vector2(direction*54,-78)
	fallback = source.get_parent().to_global(Vector2(clampf(source.position.x+direction*620,75,1205),source.position.y-78))
	global_position = origin

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("demon_bind_effects")
	guardian = AnimatedSprite2D.new()
	guardian.sprite_frames = FRAMES
	guardian.centered = false
	guardian.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var spectral := ShaderMaterial.new()
	spectral.shader = EDGES
	guardian.material = spectral
	add_child(guardian)
	sprite = guardian
	Smoke.spawn(get_parent(),origin+Vector2(0,78),90)
	_update_visual()

func _physics_process(delta: float) -> void:
	age += delta
	phase_age += delta
	match phase:
		"SUMMON":
			if phase_age >= SUMMON_TIME:
				phase = "FLIGHT"
				phase_age = 0
		"FLIGHT":
			# No visible tween through the arena: snap to the victim at arrival.
			if phase_age >= FLIGHT_TIME: _arrive()
		"HOLD":
			if not is_instance_valid(target) or not target.is_movement_locked():
				begin_release()
			else:
				global_position = _target_anchor()
				direction = int(target.facing) if "facing" in target else direction
		"RELEASE":
			if phase_age >= RELEASE_TIME:
				queue_free()
				return
	_update_visual()
	queue_redraw()

func _target_anchor() -> Vector2:
	if not is_instance_valid(target): return fallback
	return target.get_bind_anchor() if target.has_method("get_bind_anchor") else target.global_position

func _arrive() -> void:
	global_position = _target_anchor()
	if is_instance_valid(target) and target.apply_movement_lock(lock_time):
		caught = true
		direction = int(target.facing) if "facing" in target else direction
		for other: Node in get_tree().get_nodes_in_group("demon_bind_effects"):
			if other != self and other.target == target and other.phase == "HOLD": other.begin_release()
		phase = "HOLD"
		phase_age = 0
		Smoke.spawn(get_parent(),global_position+Vector2(-direction*REAR_OFFSET,78),120)
		if is_instance_valid(caster): caster.announce("NINJA BIND / TARGET LOCKED %.1fs" % lock_time)
	else:
		begin_release()
		if is_instance_valid(caster): caster.announce("NINJA BIND / MISSED")

func begin_release() -> void:
	if phase == "RELEASE": return
	phase = "RELEASE"
	phase_age = 0
	if caught: Smoke.spawn(get_parent(),global_position+Vector2(-direction*REAR_OFFSET,78),90)

func _update_visual() -> void:
	guardian.visible = phase != "FLIGHT" and (phase != "RELEASE" or caught)
	if not guardian.visible: return
	visual_height = 116 if empowered else 100
	var alpha: float = smoothstep(0,0.09,phase_age) if phase == "HOLD" else 0.65
	if phase == "RELEASE": alpha = 1-smoothstep(0,RELEASE_TIME,phase_age)
	guardian.animation = "GRIP"
	guardian.frame = floori(age*10)%8
	var factor: float = visual_height/float(FRAMES.get_meta("height"))
	guardian.scale = Vector2(direction*factor,factor)
	# Both ninja and victim face the same way: the ninja hugs from the BACK.
	grip_position = Vector2(-direction*REAR_OFFSET,78)
	guardian.position = grip_position-Vector2(512*direction,960)*factor
	guardian.modulate = Color(1,1,1,alpha*0.94)
	var atlas: AtlasTexture = FRAMES.get_frame_texture("GRIP",guardian.frame)
	var spectral: ShaderMaterial = guardian.material
	spectral.set_shader_parameter("region_origin",atlas.region.position/atlas.atlas.get_size())
	spectral.set_shader_parameter("region_extent",atlas.region.size/atlas.atlas.get_size())

func _draw() -> void:
	if phase != "HOLD": return
	var pulse: float = 0.7+sin(age*28)*0.15
	for i in range(2):
		draw_set_transform(Vector2(0,67-i*25),0,Vector2(1,0.25))
		draw_arc(Vector2.ZERO,34+i*5,-age*(2+i),TAU-age*(2+i),32,Color(0.74,0.25,1,pulse*0.7),2,false)
	draw_set_transform(Vector2.ZERO)
	# Small cuffs connect the creature's grip to the victim's calves.
	for side in [-1,1]:
		var cuff := Vector2(side*13,58)
		draw_arc(cuff,9,0,TAU,12,Color(0.91,0.67,1,pulse),2,false)
		var chain := PackedVector2Array([Vector2(-direction*27,28),Vector2(-direction*18,40),cuff])
		draw_polyline(chain,Color(0.73,0.35,1,pulse),2,false)
		if empowered:
			for link in range(4):
				var point: Vector2 = chain[0].lerp(cuff,link/3.0)
				draw_arc(point,4,0,TAU,8,Color(0.96,0.78,1,pulse),1,false)
