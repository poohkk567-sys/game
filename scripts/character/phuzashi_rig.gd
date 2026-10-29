extends Node2D
## A welded textured skin follows the original-pixel joint rig without cut seams.
## Original texture, rigid face and footwear; joint transitions share vertices.
## At the rest pose the pieces reconstruct the approved master exactly.

const DraftAnimation = preload("res://scripts/character/draft_sprite_animation.gd")
const RedCapAnimation = preload("res://scripts/character/red_cap_animation.gd")
const RedAwakenedAnimation = preload("res://scripts/character/red_awakened_animation.gd")
const MuayAnimation = preload("res://scripts/character/muay_thai_animation.gd")
const ClearAnimation = preload("res://scripts/character/clear_phuzashi_animation.gd")
var fighter_profile: String = "PHUZASHI"
var use_clear_model: bool = false
var red_awakened: bool = false
@export var use_draft_spritesheet: bool = false
var draft_animation: AnimatedSprite2D

const MASTER: Texture2D = preload("res://assets/characters/PHUZASHI_MASTER_SHOES_APPROVED.png")
const CLIPS: Array[String] = ["IDLE", "WALK", "RUN", "JUMP", "CROUCH", "GUARD", "PUNCH", "KICK", "HIT", "FALL", "SPECIAL", "ULTIMATE"]
const LENGTHS: Dictionary = {"IDLE": 1.2, "WALK": 0.72, "RUN": 0.48, "JUMP": 0.8, "CROUCH": 0.4, "GUARD": 0.6, "PUNCH": 0.42, "KICK": 0.58, "HIT": 0.48, "FALL": 1.4, "SPECIAL": 0.9, "ULTIMATE": 1.8}
# Pose channels: hip x/y, torso/head, back arm/forearm, front arm/forearm,
# back thigh/shin, front thigh/shin, whole body rotation. Angles are degrees.
const REST: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
const PIVOTS: Dictionary = {
	"torso": Vector2(32, 42), "head": Vector2(32, 28),
	"back_arm": Vector2(27, 30), "back_hand": Vector2(24, 36),
	"front_arm": Vector2(37, 31), "front_hand": Vector2(38, 36),
	"back_thigh": Vector2(29, 42), "back_shin": Vector2(25, 49),
	"front_thigh": Vector2(36, 42), "front_shin": Vector2(39, 49)
}
var joints: Dictionary = {}
var pieces: Dictionary = {}
var hip: Node2D
var clock: float = 0.0
var current_clip: String = "IDLE"
var animation_progress: float = -1.0
var displayed_pose: Array = REST.duplicate()
var pixel_count: int = 0
var timelines: Dictionary = {}
var lowest_point: float = 0.0
var skin: MeshInstance2D
var skin_mesh := ArrayMesh.new()
var source_vertices := PackedVector2Array()
var skin_vertices := PackedVector2Array()
var skin_uvs := PackedVector2Array()
var skin_indices := PackedInt32Array()
var skin_weights: Array[Dictionary] = []
var vertex_lookup: Dictionary = {}
var vertex_groups: Array[Array] = []
# Weld actual anatomical joints only. A fist touching trousers in the source
# must be free to move away; joining those contact edges would stretch clothing.
const LINKS: Array = [
	["torso", "head", Vector2(32,28), 5.0],
	["torso", "back_arm", Vector2(27,30), 3.6],
	["back_arm", "back_hand", Vector2(24,36), 4.0],
	["torso", "front_arm", Vector2(37,31), 3.6],
	["front_arm", "front_hand", Vector2(38,36), 4.0],
	["torso", "back_thigh", Vector2(29,43), 4.0],
	["back_thigh", "back_shin", Vector2(25,49), 5.0],
	["torso", "front_thigh", Vector2(36,43), 4.0],
	["front_thigh", "front_shin", Vector2(39,49), 5.0]
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_rig()
	_build_skin()
	_build_timelines()
	draft_animation = AnimatedSprite2D.new()
	draft_animation.name = "DraftSpriteAnimation"
	draft_animation.set_script(DraftAnimation)
	add_child(draft_animation)
	apply_pose(REST)

static func pixel_owner(x: int, y: int) -> String:
	if y < 28:
		return "head"
	if y < 43:
		if x < 29 and y >= 29:
			return "back_arm" if y < 36 else "back_hand"
		if x >= 37 and y >= 30:
			return "front_arm" if y < 36 else "front_hand"
		return "torso"
	if x < 33:
		return "back_thigh" if y < 49 else "back_shin"
	return "front_thigh" if y < 49 else "front_shin"

func _build_rig() -> void:
	hip = Node2D.new()
	hip.name = "Hip"
	add_child(hip)
	var source: Image = MASTER.get_image()
	var images: Dictionary = {}
	for part: String in PIVOTS:
		images[part] = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var color: Color = source.get_pixel(x, y)
			if color.a > 0.0:
				images[pixel_owner(x, y)].set_pixel(x, y, color)
				pixel_count += 1
	for part: String in PIVOTS:
		var joint := Node2D.new()
		joint.name = part
		joints[part] = joint
		var picture := Sprite2D.new()
		picture.name = "OriginalPixels"
		picture.texture = ImageTexture.create_from_image(images[part])
		picture.visible = false # Source ownership/debug only; render the welded skin.
		picture.centered = false
		picture.position = -PIVOTS[part]
		joint.add_child(picture)
		pieces[part] = picture
	# Rear limbs first, then torso/head, then front limbs.
	_attach("back_thigh", "", Vector2(32, 42))
	_attach("back_shin", "back_thigh", PIVOTS.back_thigh)
	_attach("torso", "", Vector2(32, 42))
	_attach("back_arm", "torso", PIVOTS.torso)
	_attach("back_hand", "back_arm", PIVOTS.back_arm)
	joints.torso.move_child(joints.back_arm, 0)
	_attach("head", "torso", PIVOTS.torso)
	_attach("front_thigh", "", Vector2(32, 42))
	_attach("front_shin", "front_thigh", PIVOTS.front_thigh)
	_attach("front_arm", "torso", PIVOTS.torso)
	_attach("front_hand", "front_arm", PIVOTS.front_arm)

func _build_skin() -> void:
	# One indexed mesh replaces independently clipped sprites. Anatomical seam
	# corners share one destination; incidental hand/trouser contacts stay free.
	skin = MeshInstance2D.new()
	skin.name = "ContinuousOriginalSkin"
	skin.texture = MASTER
	skin.mesh = skin_mesh
	add_child(skin)
	var source: Image = MASTER.get_image()
	for y in range(64):
		for x in range(64):
			if source.get_pixel(x, y).a <= 0.0:
				continue
			var owner: String = pixel_owner(x,y)
			var quad := PackedInt32Array()
			for offset: Vector2i in [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
				var point := Vector2i(x,y) + offset
				var group: Array = joint_group(point, owner)
				var key := Vector3i(point.x, point.y, PIVOTS.keys().find(group[0]))
				if not vertex_lookup.has(key):
					vertex_lookup[key] = source_vertices.size()
					vertex_groups.append(group)
					source_vertices.append(Vector2(point))
					skin_uvs.append(Vector2(point) / 64.0)
					skin_weights.append(_weights_at(point, source, group))
				quad.append(vertex_lookup[key])
			skin_indices.append_array(PackedInt32Array([quad[0],quad[1],quad[2],quad[0],quad[2],quad[3]]))

func joint_group(point: Vector2i, owner: String) -> Array:
	var group: Array = [owner]
	if point.y <= 27 or point.y >= 54:
		return group
	for _iteration in range(LINKS.size()):
		for link: Array in LINKS:
			if Vector2(point).distance_to(link[2]) > float(link[3]):
				continue
			if group.has(link[0]) and not group.has(link[1]):
				group.append(link[1])
			if group.has(link[1]) and not group.has(link[0]):
				group.append(link[0])
	group.sort()
	return group

func _weights_at(point: Vector2i, source: Image, group: Array) -> Dictionary:
	if group.size() == 1:
		return {group[0]: 1.0}
	var weights: Dictionary = {}
	var total: float = 0.0
	for dy in range(-2, 2):
		for dx in range(-2, 2):
			var x: int = clampi(point.x + dx, 0, 63)
			var y: int = clampi(point.y + dy, 0, 63)
			var part: String = pixel_owner(x,y)
			if source.get_pixel(x,y).a <= 0.0 or not group.has(part):
				continue
			var distance: float = Vector2(dx + 0.5, dy + 0.5).length()
			var weight: float = maxf(0.0, 2.5 - distance)
			weights[part] = float(weights.get(part, 0.0)) + weight
			total += weight
	if total <= 0.0:
		return {group[0]: 1.0}
	for part: String in weights:
		weights[part] /= total
	return weights

func _update_skin(plant_on_floor: bool) -> void:
	var transforms: Dictionary = {}
	var inverse: Transform2D = global_transform.affine_inverse()
	for part: String in pieces:
		transforms[part] = inverse * pieces[part].global_transform
	skin_vertices.resize(source_vertices.size())
	lowest_point = -INF
	for i in range(source_vertices.size()):
		var point := Vector2.ZERO
		for part: String in skin_weights[i]:
			point += (transforms[part] * source_vertices[i]) * float(skin_weights[i][part])
		skin_vertices[i] = point
		lowest_point = maxf(lowest_point, point.y)
	if plant_on_floor:
		for i in range(skin_vertices.size()):
			skin_vertices[i].y -= lowest_point
		hip.position.y -= lowest_point
		lowest_point = 0.0
	var vertices := PackedVector3Array()
	vertices.resize(skin_vertices.size())
	for i in range(skin_vertices.size()):
		vertices[i] = Vector3(skin_vertices[i].x, skin_vertices[i].y, 0.0)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = skin_uvs
	arrays[Mesh.ARRAY_INDEX] = skin_indices
	skin_mesh.clear_surfaces()
	skin_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func _attach(part: String, parent_part: String, parent_pivot: Vector2) -> void:
	var parent_node: Node2D = hip if parent_part.is_empty() else joints[parent_part]
	parent_node.add_child(joints[part])
	joints[part].position = PIVOTS[part] - parent_pivot

func _build_timelines() -> void:
	# Each clip has authored anticipation, contact and recovery poses.
	timelines = {
		"IDLE": [[0.0, REST], [0.5, [0,-0.6,-1,1,-3,-4,3,-5,0,0,0,0,0]], [1.0, REST]],
		"WALK": [[0.0,[0,0,3,-3,22,-20,-20,-20,-24,15,20,5,0]], [0.25,[0,-1,2,-2,0,-25,0,-30,0,35,0,0,0]], [0.5,[0,0,3,-3,-20,-20,22,-20,20,5,-24,15,0]], [0.75,[0,-1,2,-2,0,-30,0,-25,0,0,0,35,0]], [1.0,[0,0,3,-3,22,-20,-20,-20,-24,15,20,5,0]]],
		"RUN": [[0.0,[0,-2,14,-10,65,-65,-55,-60,-45,55,50,40,0]], [0.25,[0,-4,14,-10,0,-85,0,-80,0,90,0,10,0]], [0.5,[0,-2,14,-10,-55,-60,65,-65,50,40,-45,55,0]], [0.75,[0,-4,14,-10,0,-80,0,-85,0,10,0,90,0]], [1.0,[0,-2,14,-10,65,-65,-55,-60,-45,55,50,40,0]]],
		"JUMP": [[0.0,[0,2,8,-5,-15,-30,10,-30,-15,25,10,20,0]], [0.25,[0,0,-5,5,125,-25,-120,-30,-25,70,30,65,0]], [0.6,[0,0,4,-4,80,-45,-65,-50,-20,55,20,45,0]], [1.0,[0,2,8,-5,15,-25,-10,-25,-15,25,10,20,0]]],
		"CROUCH": [[0.0,REST], [0.45,[0,8,12,-12,-25,-55,20,-70,-55,85,48,-60,0]], [1.0,[0,8,12,-12,-25,-55,20,-70,-55,85,48,-60,0]]],
		"GUARD": [[0.0,REST], [0.25,[0,1,-6,4,-45,-110,-50,-125,-5,8,8,-8,0]], [0.7,[0,1,-5,3,-47,-110,-52,-125,-5,8,8,-8,0]], [1.0,[0,1,-6,4,-45,-110,-50,-125,-5,8,8,-8,0]]],
		"PUNCH": [[0.0,REST], [0.22,[-1,0,-8,5,5,-80,-40,-100,0,0,0,0,0]], [0.42,[2,0,9,-7,-10,-75,-80,-15,-8,10,8,-8,0]], [0.6,[2,0,8,-7,-10,-75,-80,-15,-8,10,8,-8,0]], [1.0,REST]],
		"KICK": [[0.0,REST], [0.25,[-1,0,-8,5,-30,-80,-35,-85,0,0,-65,100,0]], [0.48,[-2,-1,-15,10,-35,-85,35,-80,4,-4,-105,0,0]], [0.65,[-2,-1,-15,10,-35,-85,35,-80,4,-4,-105,0,0]], [0.82,[0,0,-5,5,0,-50,0,-50,0,0,-45,90,0]], [1.0,REST]],
		"HIT": [[0.0,REST], [0.18,[-2,1,-18,12,35,-10,25,-20,8,-10,-8,20,-5]], [0.55,[-2,2,-14,10,25,-15,20,-20,5,-5,-5,15,-3]], [1.0,REST]],
		"FALL": [[0.0,REST], [0.2,[-3,-4,-10,10,70,-20,-50,-30,10,10,-20,30,-35]], [0.43,[-8,11,0,0,10,-10,-10,-10,-30,16,23,-9,-90]], [0.72,[-8,11,0,0,10,-10,-10,-10,-30,16,23,-9,-90]], [0.88,[0,8,25,-20,10,-50,-20,-60,-50,80,40,-50,-12]], [1.0,REST]],
		"SPECIAL": [[0.0,REST], [0.22,[-2,3,-12,10,-10,-70,-45,-110,-15,20,15,-20,0]], [0.44,[2,1,10,-8,-50,-40,-85,-10,-15,15,10,-10,0]], [0.72,[2,1,10,-8,-50,-40,-85,-10,-15,15,10,-10,0]], [1.0,REST]],
		"ULTIMATE": [[0.0,REST], [0.18,[0,5,15,-10,-35,-90,30,-100,-35,45,30,-40,0]], [0.38,[0,1,-10,5,145,-35,-140,-40,-10,15,10,-15,0]], [0.55,[2,3,15,-10,-65,-30,-90,-10,-25,35,20,-25,0]], [0.8,[2,3,15,-10,-65,-30,-90,-10,-25,35,20,-25,0]], [1.0,REST]]
	}

func animate(state: String, delta: float, facing: int, progress: float = -1.0) -> void:
	if state != current_clip:
		clock = 0.0
		current_clip = state
	clock += delta
	animation_progress = progress
	var phase: float = fmod(clock / float(LENGTHS.get(state, 1.0)), 1.0)
	if progress >= 0.0:
		phase = clampf(progress, 0.0, 1.0)
	elif state == "CROUCH" or state == "GUARD":
		phase = minf(clock / float(LENGTHS[state]), 0.95)
	var pose: Array = sample_pose(state, phase)
	var smoothing: float = minf(1.0, delta * 28.0)
	for i in range(REST.size()):
		displayed_pose[i] = lerpf(float(displayed_pose[i]), float(pose[i]), smoothing)
	scale = Vector2(3.0 * facing, 3.0)
	apply_pose(displayed_pose, state != "JUMP" and not state.begins_with("AIR_"))

func sample_pose(state: String, phase: float) -> Array:
	var base: String = state.trim_prefix("AIR_").get_slice("_", 0)
	var frames: Array = timelines.get(state, timelines.get(base, timelines.IDLE))
	for i in range(frames.size() - 1):
		var a: Array = frames[i]
		var b: Array = frames[i + 1]
		if phase <= float(b[0]):
			var weight: float = clampf((phase - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			weight = smoothstep(0.0, 1.0, weight)
			var result: Array = []
			for j in range(REST.size()):
				result.append(lerpf(float(a[1][j]), float(b[1][j]), weight))
			return result
	return frames[-1][1].duplicate()

func apply_pose(pose: Array, plant_on_floor: bool = true) -> void:
	hip.position = Vector2(float(pose[0]), -17.0 + float(pose[1]))
	hip.rotation_degrees = float(pose[12])
	var order: Array[String] = ["torso", "head", "back_arm", "back_hand", "front_arm", "front_hand", "back_thigh", "back_shin", "front_thigh", "front_shin"]
	for i in range(order.size()):
		joints[order[i]].rotation_degrees = float(pose[i + 2])

	_update_skin(plant_on_floor)
	_sync_presentation()

func set_draft_enabled(enabled: bool) -> void:
	use_draft_spritesheet = enabled or fighter_profile != "PHUZASHI" or use_clear_model
	_sync_presentation()

func set_character_profile(profile: String) -> void:
	fighter_profile = profile
	var old: AnimatedSprite2D = draft_animation
	remove_child(old)
	old.queue_free()
	draft_animation = AnimatedSprite2D.new()
	draft_animation.name = "DraftSpriteAnimation"
	draft_animation.set_script(MuayAnimation if profile == "MUAY_THAI" else ((RedAwakenedAnimation if red_awakened else RedCapAnimation) if profile == "RED_CAP" else (ClearAnimation if use_clear_model else DraftAnimation)))
	add_child(draft_animation)
	use_draft_spritesheet = true
	reset_pose()

func set_clear_enabled(enabled: bool) -> void:
	use_clear_model = enabled
	set_character_profile(fighter_profile)

func set_red_awakened(enabled: bool) -> void:
	red_awakened = enabled
	set_character_profile(fighter_profile)

func _sync_presentation() -> void:
	if not is_instance_valid(draft_animation):
		return
	var supported: bool = draft_animation.show_state(current_clip,use_draft_spritesheet,animation_progress)
	skin.visible = not supported and fighter_profile == "PHUZASHI"

func renderer_name() -> String:
	return "SPRITESHEET" if is_instance_valid(draft_animation) and draft_animation.visible else "MASTER RIG"

func reset_pose() -> void:
	clock = 0.0
	current_clip = "IDLE"
	animation_progress = -1.0
	displayed_pose = REST.duplicate()
	draft_animation.restart()
	apply_pose(REST)
