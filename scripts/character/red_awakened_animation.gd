extends "res://scripts/character/draft_sprite_animation.gd"
## Bald shirtless form. Own complete drawings for every normal and reaction.
const AWAKENED_FRAMES: SpriteFrames = preload("res://assets/characters/red_awakened/awakened_frames.res")
const ALIASES: Dictionary = {"AIR_PUNCH":"PUNCH", "AIR_KICK":"KICK", "BOUND":"HIT"}

func _ready() -> void:
	sprite_frames = AWAKENED_FRAMES.duplicate(true)
	for clip: String in ALIASES:
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_loop(clip,false)
		for i in range(8):
			sprite_frames.add_frame(clip,AWAKENED_FRAMES.get_frame_texture(ALIASES[clip],i))
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout := ShaderMaterial.new()
	cutout.shader = CUTOUT
	material = cutout
	visible = false

func show_state(state: String, enabled: bool, progress: float = -1.0) -> bool:
	# Crouch and guard enter then hold their final pose instead of cycling back.
	if progress < 0.0 and state in ["CROUCH","GUARD"]:
		var rig: Node2D = get_parent()
		progress = minf(rig.clock / 0.35,0.999)
	var supported: bool = super.show_state(state,enabled,progress)
	var source: String = ALIASES.get(state,state)
	var factor: float = float(AWAKENED_FRAMES.get_meta("scales").get(source,1.0))
	var pivot: Vector2 = AWAKENED_FRAMES.get_meta("pivot")
	scale = Vector2.ONE * FRAME_SCALE * factor
	position = -pivot * FRAME_SCALE * factor
	return supported

func frame_at_progress(state: String, progress: float) -> int:
	var boundaries: Array = []
	if state == "KICK":
		boundaries = [0.0,0.10,0.20,0.28,0.40,0.65,0.82,0.94]
	elif state == "KICK_2":
		boundaries = [0.0,0.10,0.20,0.30,0.64,0.73,0.83,0.94]
	if boundaries.is_empty():
		return super.frame_at_progress(state,progress)
	var result: int = 0
	for i in range(boundaries.size()):
		if progress >= float(boundaries[i]):
			result = i
	return result
