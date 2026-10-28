extends "res://scripts/character/draft_sprite_animation.gd"
## Approved fair-skin outfit, complete frames, original gameplay/VFX timing.
const CLEAR_FRAMES: SpriteFrames = preload("res://assets/characters/phuzashi_clear/clear_frames.res")
const ALIASES: Dictionary = {"AIR_PUNCH":"PUNCH","AIR_KICK":"KICK","BOUND":"HIT","DEMON_BIND":"SPECIAL"}
const CLEAR_FIST: Array[Vector2] = [
	Vector2(0.70,0.40),Vector2(0.72,0.58),Vector2(0.78,0.35),Vector2(0.70,0.07),
	Vector2(0.57,0.05),Vector2(0.76,0.32),Vector2(0.72,0.40),Vector2(0.72,0.40)
]

func _ready() -> void:
	sprite_frames = CLEAR_FRAMES.duplicate(true)
	for clip: String in ALIASES:
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_loop(clip,false)
		for i in range(8):
			sprite_frames.add_frame(clip,CLEAR_FRAMES.get_frame_texture(ALIASES[clip],i))
	sprite_frames.add_animation("BLINK")
	sprite_frames.set_animation_loop("BLINK",false)
	for pose: Array in BLINK_POSES:
		sprite_frames.add_frame("BLINK",CLEAR_FRAMES.get_frame_texture(pose[0],pose[1]))
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout := ShaderMaterial.new()
	cutout.shader = CUTOUT
	material = cutout
	visible = false

func show_state(state: String, enabled: bool, progress: float = -1.0) -> bool:
	if progress < 0 and state in ["CROUCH","GUARD"]:
		var rig: Node2D = get_parent()
		progress = minf(rig.clock/0.35,0.999)
	var supported: bool = super.show_state(state,enabled,progress)
	var source: String = ALIASES.get(state,state)
	if state == "BLINK":
		source = BLINK_POSES[clampi(frame,0,11)][0]
	var factor: float = float(CLEAR_FRAMES.get_meta("scales").get(source,1.0))
	var pivot: Vector2 = CLEAR_FRAMES.get_meta("pivot")
	scale = Vector2.ONE * FRAME_SCALE * factor
	position = -pivot * FRAME_SCALE * factor
	return supported

func combo_fist_global_position() -> Vector2:
	var atlas: AtlasTexture = sprite_frames.get_frame_texture("PUNCH_3",clampi(frame,0,7))
	return to_global(atlas.margin.position+atlas.region.size*CLEAR_FIST[clampi(frame,0,7)])

func frame_at_progress(state: String, progress: float) -> int:
	# New kick drawings retain the original attack windows, damage and effects.
	var timing: Dictionary = {
	 "PUNCH":[0.0,0.12,0.26,0.34,0.62,0.74,0.84,0.94],
	 "AIR_PUNCH":[0.0,0.05,0.15,0.24,0.62,0.74,0.84,0.94],
	 "KICK":[0.0,0.10,0.20,0.30,0.66,0.76,0.85,0.94],
	 "AIR_KICK":[0.0,0.05,0.12,0.20,0.66,0.76,0.85,0.94],
	 "KICK_2":[0.0,0.10,0.20,0.30,0.64,0.73,0.83,0.94]
	}
	if timing.has(state):
		var result: int = 0
		var boundaries: Array = timing[state]
		for i in range(boundaries.size()):
			if progress >= float(boundaries[i]):
				result = i
		return result
	return super.frame_at_progress(state,progress)
