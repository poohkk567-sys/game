extends Node2D
## Cosmetic homing spirit; immobilization belongs to the target's status component.
const SHEET: Texture2D = preload("res://assets/effects/demon_bind/demon_bind.png")
const EDGES: Shader = preload("res://assets/effects/shadow_blink/atlas_edges.gdshader")
const LOCK_TIME: float = 0.7
const SUMMON_TIME: float = 0.12
const FLIGHT_TIME: float = 0.22
const RELEASE_TIME: float = 0.22
var caster: Node2D
var target: Node2D
var origin: Vector2
var fallback: Vector2
var direction: int = 1
var phase: String = "SUMMON"
var phase_age: float = 0.0
var age: float = 0.0
var caught: bool = false
var sprite: Sprite2D
var cells: Array[AtlasTexture] = []
var regions: Array[Rect2] = []

func configure(source: Node2D, victim: Node2D) -> void:
	caster = source
	target = victim
	direction = source.facing
	origin = source.global_position+Vector2(direction*54,-88)
	fallback = source.get_parent().to_global(Vector2(clampf(source.position.x+direction*620,75,1205),source.position.y-78))
	global_position = origin

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("demon_bind_effects")
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var material_edges := ShaderMaterial.new()
	material_edges.shader = EDGES
	sprite.material = material_edges
	add_child(sprite)
	for index in range(16):
		var size: Vector2 = SHEET.get_size()
		var col: int = index%4
		var row: int = index/4
		var upper := Vector2(roundf(col*size.x/4.0),roundf(row*size.y/4.0))
		var lower := Vector2(roundf((col+1)*size.x/4.0),roundf((row+1)*size.y/4.0))
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = Rect2(upper,lower-upper)
		atlas.filter_clip = true
		cells.append(atlas)
		regions.append(atlas.region)
	_update_visual()

func _physics_process(delta: float) -> void:
	age += delta
	phase_age += delta
	match phase:
		"SUMMON":
			if phase_age >= SUMMON_TIME:
				phase = "FLIGHT"
				phase_age = 0.0
		"FLIGHT":
			var q: float = clampf(phase_age/FLIGHT_TIME,0.0,1.0)
			global_position = origin.lerp(_target_anchor(),q)+Vector2(0,-sin(q*PI)*24)
			if q >= 1.0:
				_arrive()
		"HOLD":
			if not is_instance_valid(target) or not target.is_movement_locked():
				begin_release()
			else:
				global_position = _target_anchor()
		"RELEASE":
			if phase_age >= RELEASE_TIME:
				queue_free()
				return
	_update_visual()
	queue_redraw()

func _target_anchor() -> Vector2:
	if not is_instance_valid(target):
		return fallback
	return target.get_bind_anchor() if target.has_method("get_bind_anchor") else target.global_position

func _arrive() -> void:
	if is_instance_valid(target) and target.apply_movement_lock(LOCK_TIME):
		caught = true
		# Refresh the status without accumulating duplicate holding demons.
		for other: Node in get_tree().get_nodes_in_group("demon_bind_effects"):
			if other != self and other.target == target and other.phase == "HOLD":
				other.begin_release()
		phase = "HOLD"
		phase_age = 0.0
		global_position = _target_anchor()
		if is_instance_valid(caster):
			caster.announce("DEMON BIND / TARGET LOCKED 0.7s")
	else:
		begin_release()
		if is_instance_valid(caster):
			caster.announce("DEMON BIND / MISSED")

func begin_release() -> void:
	phase = "RELEASE"
	phase_age = 0.0

func _update_visual() -> void:
	var index: int = 0
	var extent: float = 130.0
	var opacity: float = 1.0
	match phase:
		"SUMMON":
			var q: float = clampf(phase_age/SUMMON_TIME,0.0,0.9999)
			index = mini(3,floori(q*4))
			extent = lerpf(88,145,q)
			opacity = lerpf(0.45,0.9,q)
		"FLIGHT":
			index = 4+mini(3,floori(clampf(phase_age/FLIGHT_TIME,0.0,0.9999)*4))
			extent = 158
		"HOLD":
			index = 8+floori(phase_age*12.0)%4
			extent = 238
		"RELEASE":
			var q: float = clampf(phase_age/RELEASE_TIME,0.0,0.9999)
			index = 12+mini(3,floori(q*4))
			extent = 238 if caught else 158
			opacity = 1.0-smoothstep(0.25,1.0,q)
	sprite.texture = cells[index]
	sprite.scale = Vector2(direction*extent/regions[index].size.x,extent/regions[index].size.y)
	# Shift the spirit upward: its open chain loop surrounds the target's body.
	sprite.position.y = -20 if phase in ["HOLD","RELEASE"] and caught else 0
	sprite.modulate = Color(1,1,1,opacity)
	var shader_edges: ShaderMaterial = sprite.material
	shader_edges.set_shader_parameter("region_origin",regions[index].position/SHEET.get_size())
	shader_edges.set_shader_parameter("region_extent",regions[index].size/SHEET.get_size())
	shader_edges.set_shader_parameter("feather",Vector2(0.055,0.055))
	sprite.set_meta("atlas_frame",index)

func _draw() -> void:
	if phase != "HOLD":
		return
	var pulse: float = 0.7+sin(age*28)*0.15
	for i in range(2):
		draw_set_transform(Vector2(0,67-i*25),0,Vector2(1,0.25))
		draw_arc(Vector2.ZERO,54+i*9,-age*(2+i),TAU-age*(2+i),40,Color(0.74,0.25,1,pulse*0.7),2,false)
	draw_set_transform(Vector2.ZERO)
