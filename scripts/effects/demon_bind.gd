extends Node2D
## A small standing ninja teleports behind the victim and pulls foreground chains.
const FRAMES: SpriteFrames = preload("res://assets/effects/ninja_grapple_frames.res")
const EDGES: Shader = preload("res://assets/effects/side_guardians/spectral_aura.gdshader")
const Smoke = preload("res://scripts/effects/ninja_smoke.gd")
const Chains = preload("res://scripts/effects/bind_chains.gd")
const LOCK_TIME: float = 0.7
const SUMMON_TIME: float = 0.12
const FLIGHT_TIME: float = 0.22 # Hidden teleport interval; not a travelling projectile.
const RELEASE_TIME: float = 0.22
const REAR_OFFSET: float = 104
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
var chains: Node2D

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
	# The victim used to cover this effect because it was ordered behind them.
	# Keep the small ninja separate in space AND above the fighter draw layer.
	guardian.z_index = 1
	add_child(guardian)
	sprite = guardian
	chains = Chains.new()
	chains.z_index = 2
	chains.visible = false
	add_child(chains)
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
		_update_visual()
		Smoke.spawn(get_parent(),global_position+grip_position,100)
		if is_instance_valid(caster): caster.announce("NINJA BIND / TARGET LOCKED %.1fs" % lock_time)
	else:
		begin_release()
		if is_instance_valid(caster): caster.announce("NINJA BIND / MISSED")

func begin_release() -> void:
	if phase == "RELEASE": return
	phase = "RELEASE"
	phase_age = 0
	if caught: Smoke.spawn(get_parent(),global_position+grip_position,90)

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
	# Both face the same way. Stand apart from the victim and pull the chains.
	grip_position = Vector2(-direction*REAR_OFFSET,78)
	var atlas: AtlasTexture = FRAMES.get_frame_texture("GRIP",guardian.frame)
	var ink: Rect2 = atlas.get_meta("ink_bounds")
	var left: float = global_position.x+grip_position.x+(atlas.margin.position.x+ink.position.x-512)*factor*direction
	var right: float = left+ink.size.x*factor*direction
	# At arena edges keep the complete small body on screen, still on the rear
	# side. Its independent foreground layer prevents the victim hiding it.
	grip_position.x += maxf(0,12-minf(left,right))-maxf(0,maxf(left,right)-1268)
	guardian.position = grip_position-Vector2(512*direction,960)*factor
	guardian.modulate = Color(1,1,1,alpha*0.94)
	var spectral: ShaderMaterial = guardian.material
	spectral.set_shader_parameter("region_origin",atlas.region.position/atlas.atlas.get_size())
	spectral.set_shader_parameter("region_extent",atlas.region.size/atlas.atlas.get_size())

func visual_bounds() -> Rect2:
	var atlas: AtlasTexture = FRAMES.get_frame_texture("GRIP",guardian.frame)
	var ink: Rect2 = atlas.get_meta("ink_bounds")
	var start: Vector2 = guardian.to_global(atlas.margin.position+ink.position)
	var end: Vector2 = guardian.to_global(atlas.margin.position+ink.end)
	return Rect2(Vector2(minf(start.x,end.x),minf(start.y,end.y)),(end-start).abs())

func _draw() -> void:
	if phase != "HOLD": return
	# Rear halves sit behind the target; the separate foreground draws the front.
	for row in range(3):
		var points := PackedVector2Array()
		for step in range(16):
			var theta: float = PI+step*PI/15
			points.append(Vector2(cos(theta)*34,Chains.TORSO_OFFSET-23+row*28+sin(theta)*10))
		Chains.path(self,points,0.45)
