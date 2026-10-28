extends AnimatedSprite2D
## Trial playback of complete illustrated frames. No bones or mesh deformation.
const FRAMES: SpriteFrames = preload("res://assets/characters/drafts/idle_walk_frames.tres")
const CUTOUT: Shader = preload("res://assets/characters/drafts/alpha_cutout.gdshader")
const FRAME_SCALE: float = 52.0/286.0
const PIVOT := Vector2(160,340)

func _ready() -> void:
	sprite_frames = FRAMES
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE*FRAME_SCALE
	position = -PIVOT*FRAME_SCALE
	var cutout := ShaderMaterial.new()
	cutout.shader = CUTOUT
	material = cutout
	visible = false

func show_state(state: String, enabled: bool) -> bool:
	var supported: bool = enabled and sprite_frames.has_animation(state)
	visible = supported
	if supported:
		if animation != state or not is_playing():
			play(state)
	else:
		stop()
	return supported

func restart() -> void:
	stop()
	frame = 0
	frame_progress = 0.0
