extends AnimatedSprite2D
## Complete illustrated frames for all twelve states, with gameplay-timed contact.
const FRAMES: SpriteFrames = preload("res://assets/characters/spritesheets/phuzashi_frames.res")
const CUTOUT: Shader = preload("res://assets/characters/drafts/alpha_cutout.gdshader")
const FRAME_SCALE: float = 52.0/286.0
const PIVOT := Vector2(256,360)
const CONTACT_PHASES: Dictionary = {
	"PUNCH":[0.0,0.12,0.26,0.34,0.48,0.62,0.78,0.90],
	"KICK":[0.0,0.14,0.25,0.40,0.48,0.66,0.82,0.94],
	"SPECIAL":[0.0,0.12,0.25,0.42,0.50,0.65,0.82,0.94],
	"ULTIMATE":[0.0,0.10,0.25,0.36,0.48,0.64,0.82,0.94],
	"HIT":[0.0,0.08,0.18,0.35,0.50,0.68,0.82,0.94],
	"FALL":[0.0,0.10,0.22,0.40,0.60,0.74,0.84,0.94],
	"JUMP":[0.0,0.06,0.22,0.40,0.55,0.72,0.88,0.98]
}
var last_state: String = ""

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

func show_state(state: String, enabled: bool, progress: float = -1.0) -> bool:
	var supported: bool = enabled and sprite_frames.has_animation(state)
	var entering: bool = not visible or last_state != state
	visible = supported
	if supported:
		if entering:
			play(state)
		last_state = state
		if progress >= 0.0:
			pause()
			frame = frame_at_progress(state,progress)
			frame_progress = 0.0
	else:
		stop()
		last_state = ""
	return supported

func frame_at_progress(state: String, progress: float) -> int:
	var boundaries: Array = CONTACT_PHASES.get(state,[0.0,0.125,0.25,0.375,0.5,0.625,0.75,0.875])
	var result: int = 0
	for i in range(boundaries.size()):
		if progress >= float(boundaries[i]):
			result = i
	return result

func restart() -> void:
	stop()
	last_state = ""
	frame = 0
	frame_progress = 0.0
