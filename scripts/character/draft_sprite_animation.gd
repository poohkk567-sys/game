extends AnimatedSprite2D
## Complete illustrated frames for all twelve states, with gameplay-timed contact.
const FRAMES: SpriteFrames = preload("res://assets/characters/spritesheets/phuzashi_frames.res")
const CUTOUT: Shader = preload("res://assets/characters/drafts/alpha_cutout.gdshader")
const FRAME_SCALE: float = 52.0/286.0
const PIVOT := Vector2(256,360)
const EXTRA_CLIPS: Dictionary = {
	"PUNCH_2": "PUNCH", "PUNCH_3": "PUNCH",
	"KICK_2": "KICK", "KICK_3": "KICK",
	"AIR_PUNCH": "PUNCH", "AIR_KICK": "KICK"
}
const BLINK_POSES: Array = [
	["IDLE",0], ["CROUCH",1], ["CROUCH",3], ["RUN",1],
	["RUN",2], ["RUN",3], ["RUN",5], ["RUN",5],
	["CROUCH",4], ["CROUCH",6], ["CROUCH",7], ["IDLE",0]
]
const CONTACT_PHASES: Dictionary = {
	"PUNCH":[0.0,0.12,0.26,0.34,0.48,0.62,0.78,0.90],
	"KICK":[0.0,0.14,0.25,0.40,0.48,0.66,0.82,0.94],
	"SPECIAL":[0.0,0.12,0.25,0.42,0.50,0.65,0.82,0.94],
	"ULTIMATE":[0.0,0.10,0.25,0.36,0.48,0.64,0.82,0.94],
	"HIT":[0.0,0.08,0.18,0.35,0.50,0.68,0.82,0.94],
	"FALL":[0.0,0.10,0.22,0.40,0.60,0.74,0.84,0.94],
	"JUMP":[0.0,0.06,0.22,0.40,0.55,0.72,0.88,0.98]
}
const EXTRA_CONTACT_PHASES: Dictionary = {
	"PUNCH_2": [0.0,0.10,0.22,0.32,0.44,0.57,0.76,0.91],
	"PUNCH_3": [0.0,0.08,0.20,0.30,0.46,0.62,0.80,0.93],
	"KICK_2": [0.0,0.10,0.20,0.28,0.36,0.62,0.80,0.94],
	"KICK_3": [0.0,0.08,0.16,0.24,0.34,0.65,0.83,0.95],
	"AIR_PUNCH": [0.0,0.06,0.15,0.24,0.42,0.60,0.78,0.92],
	"AIR_KICK": [0.0,0.08,0.16,0.22,0.30,0.66,0.82,0.94]
}
var last_state: String = ""

func _ready() -> void:
	sprite_frames = FRAMES.duplicate(true)
	# Reuse intact approved drawings; attack timings select the contact frames.
	for clip: String in EXTRA_CLIPS:
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_loop(clip, false)
		for i in range(8):
			sprite_frames.add_frame(clip, FRAMES.get_frame_texture(EXTRA_CLIPS[clip], i))
	sprite_frames.add_animation("BLINK")
	sprite_frames.set_animation_speed("BLINK", 30.0)
	sprite_frames.set_animation_loop("BLINK", false)
	for pose: Array in BLINK_POSES:
		sprite_frames.add_frame("BLINK", FRAMES.get_frame_texture(pose[0], pose[1]))
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
		if state == "BLINK" and frame in [5,6,7]:
			var alpha: float = 0.12 if frame == 6 else (0.58 if frame == 5 else 0.72)
			modulate = Color(0.81, 0.63, 1.0, alpha)
		else:
			modulate = Color.WHITE
	else:
		stop()
		last_state = ""
	return supported

func frame_at_progress(state: String, progress: float) -> int:
	if state == "BLINK":
		return mini(11, floori(clampf(progress, 0.0, 0.99999) * 12.0))
	var boundaries: Array = EXTRA_CONTACT_PHASES.get(state, CONTACT_PHASES.get(state,[0.0,0.125,0.25,0.375,0.5,0.625,0.75,0.875]))
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
