extends Node2D
## World-anchored departure, travelling energy and arrival from the approved art.
## The visual tail outlives the 0.4-second move without extending invulnerability.
const SHEET: Texture2D = preload("res://assets/effects/shadow_blink/shadow_blink_approved.png")
const EDGES: Shader = preload("res://assets/effects/shadow_blink/atlas_edges.gdshader")
const LIFETIME: float = 0.72
const PORTAL_SCALE: float = 0.74
# The illustration has uneven spacing; authored bounds avoid neighbouring frames.
# x, y, width, height, pivot x, pivot y (all in original image pixels).
const CELLS: Array = [
	[20,132,290,180,150,168], [330,64,280,248,138,236],
	[640,22,275,290,145,278], [954,10,290,302,152,290],
	[15,312,290,312,155,298], [325,312,295,312,152,298],
	[628,370,294,250,282,144], [925,423,329,180,311,96],
	[2,687,319,200,307,105], [316,705,339,178,331,92],
	[651,730,347,154,336,75], [1002,624,244,276,122,266],
	[0,896,365,322,180,309], [365,904,285,310,135,301],
	[665,960,280,258,140,245], [975,1000,255,218,145,205]
]

var fighter: Node2D
var departure: Vector2
var destination: Vector2
var direction: int = 1
var age: float = 0.0
var departure_sprite: Sprite2D
var dash_sprite: Sprite2D
var arrival_sprite: Sprite2D
var ghosts: Array[Sprite2D] = []
var ghost_births: Array[float] = []
var ghost_index: int = 0

func configure(actor: Node2D) -> void:
	fighter = actor
	direction = actor.blink_direction
	departure = actor.global_position
	var target_x: float = clampf(actor.blink_origin + direction * actor.BLINK_DISTANCE, 75.0, 1205.0)
	destination = actor.get_parent().to_global(Vector2(target_x, actor.position.y))

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("shadow_blink_effects")
	departure_sprite = _make_sprite("DepartureRift")
	dash_sprite = _make_sprite("TravellingEnergy")
	arrival_sprite = _make_sprite("ArrivalRift")
	_update_art()

func _make_sprite(label: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = label
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var edge_material := ShaderMaterial.new()
	edge_material.shader = EDGES
	sprite.material = edge_material
	add_child(sprite)
	return sprite

func _show_cell(sprite: Sprite2D, index: int, anchor: Vector2, opacity: float) -> void:
	var cell: Array = CELLS[clampi(index, 0, 15)]
	var region := Rect2(cell[0], cell[1], cell[2], cell[3])
	var texture := AtlasTexture.new()
	texture.atlas = SHEET
	texture.region = region
	texture.filter_clip = true
	sprite.texture = texture
	sprite.offset = -Vector2(cell[4], cell[5])
	sprite.global_position = anchor
	sprite.scale = Vector2(direction * PORTAL_SCALE, PORTAL_SCALE)
	sprite.modulate = Color(1, 1, 1, clampf(opacity, 0.0, 1.0))
	var edge_material: ShaderMaterial = sprite.material
	edge_material.set_shader_parameter("region_origin", region.position / SHEET.get_size())
	edge_material.set_shader_parameter("region_extent", region.size / SHEET.get_size())
	edge_material.set_shader_parameter("feather", Vector2(5, 5) / region.size)
	sprite.set_meta("atlas_frame", index)

func _process(delta: float) -> void:
	age += delta
	if not is_instance_valid(fighter) or age >= LIFETIME:
		queue_free()
		return
	_update_art()
	if ghost_index < 3 and age >= 0.14 + ghost_index * 0.055 and age < 0.32:
		_capture_ghost()
		ghost_index += 1
	for i in range(ghosts.size()):
		var fade: float = 1.0 - clampf((age - ghost_births[i]) / 0.24, 0.0, 1.0)
		ghosts[i].modulate = Color(0.66, 0.35, 1.0, fade * 0.26)

func _update_art() -> void:
	departure_sprite.visible = age < 0.31
	if departure_sprite.visible:
		var index: int = mini(5, floori(age / 0.17 * 6.0))
		var fade: float = 1.0 - smoothstep(0.18, 0.31, age)
		_show_cell(departure_sprite, index, departure + Vector2(0, 3), fade)
	dash_sprite.visible = age >= 0.15 and age < 0.33
	if dash_sprite.visible:
		var q: float = clampf((age - 0.15) / 0.15, 0.0, 0.9999)
		var travel: float = clampf((age / 0.4 - 0.24) / 0.49, 0.0, 1.0)
		travel = travel * travel * (3.0 - 2.0 * travel)
		var head: Vector2 = departure.lerp(destination, travel) + Vector2(direction * 32, -77)
		_show_cell(dash_sprite, 6 + floori(q * 5), head, 1.0 - smoothstep(0.28, 0.33, age))
	arrival_sprite.visible = age >= 0.28
	if arrival_sprite.visible:
		var q: float = clampf((age - 0.28) / 0.41, 0.0, 0.9999)
		var index: int = 11 + mini(4, floori(q * 5))
		var opacity: float = smoothstep(0.28, 0.31, age) * (1.0 - smoothstep(0.48, LIFETIME, age))
		_show_cell(arrival_sprite, index, destination + Vector2(0, 3), opacity)

func _capture_ghost() -> void:
	var source: AnimatedSprite2D = fighter.rig.draft_animation
	if not source.visible:
		return
	var ghost := Sprite2D.new()
	ghost.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	ghost.centered = source.centered
	ghost.offset = source.offset
	ghost.material = source.material
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(ghost)
	ghost.global_transform = source.global_transform
	move_child(ghost, 0)
	ghosts.append(ghost)
	ghost_births.append(age)
