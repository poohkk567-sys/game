extends "res://scripts/character/draft_sprite_animation.gd"
## Complete taller Muay Thai drawings; normal attacks include elbow and knee.
var muay_frames: SpriteFrames
var motion_frames: SpriteFrames
const ALIASES: Dictionary = {"AIR_PUNCH":"PUNCH","AIR_KICK":"KICK","BOUND":"HIT"}
func _ready() -> void:
	muay_frames = load("res://assets/characters/muay_thai/muay_frames.res")
	sprite_frames = muay_frames.duplicate(true)
	motion_frames = load("res://assets/characters/muay_thai/motion_smooth_frames.res")
	for clip: String in ["IDLE","DASH"]:
		if sprite_frames.has_animation(clip): sprite_frames.clear(clip)
		else: sprite_frames.add_animation(clip)
		sprite_frames.set_animation_loop(clip,clip == "IDLE")
		sprite_frames.set_animation_speed(clip,8 if clip == "IDLE" else 25)
		for i in range(8):
			var index: int = [0,1,2,3,2,1,0,1][i] if clip == "IDLE" else i
			sprite_frames.add_frame(clip,motion_frames.get_frame_texture(clip,index))
	for clip: String in ALIASES:
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_loop(clip,false)
		for i in range(8):
			sprite_frames.add_frame(clip,muay_frames.get_frame_texture(ALIASES[clip],i))
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout := ShaderMaterial.new()
	cutout.shader = CUTOUT
	material = cutout
	visible = false
func show_state(state: String, enabled: bool, progress: float = -1) -> bool:
	if progress < 0 and state in ["CROUCH","GUARD"]:
		progress = minf(get_parent().clock/0.35,0.999)
	var supported: bool = super.show_state(state,enabled,progress)
	if state in ["IDLE","DASH"]:
		var factor: float = 62.4/float(motion_frames.get_meta("source_height"))
		scale = Vector2.ONE*factor
		position = -Vector2(motion_frames.get_meta("pivot"))*factor
		return supported
	var source: String = ALIASES.get(state,state)
	var factor: float = float(muay_frames.get_meta("scales").get(source,1.0))*1.20
	scale = Vector2.ONE*FRAME_SCALE*factor
	position = -Vector2(muay_frames.get_meta("pivot"))*FRAME_SCALE*factor
	return supported

func frame_at_progress(state: String, progress: float) -> int:
	if state == "CROUCH":
		return mini(5,floori(clampf(progress,0,0.999)*6))
	var timing: Dictionary = {
	 "PUNCH":[0.0,0.18,0.34,0.61,0.72,0.82,0.90,0.95],
	 "KICK":[0.0,0.20,0.40,0.66,0.76,0.84,0.91,0.96],
	 "AIR_PUNCH":[0.0,0.10,0.24,0.61,0.72,0.82,0.90,0.95],
	 "AIR_KICK":[0.0,0.12,0.30,0.67,0.78,0.86,0.93,0.97]
	}
	if not timing.has(state):
		return super.frame_at_progress(state,progress)
	var result: int = 0
	for i in range(8):
		if progress >= float(timing[state][i]): result = i
	return result
