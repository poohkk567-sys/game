extends "res://scripts/character/draft_sprite_animation.gd"
## New fighter owns every basic drawing. No borrowed PHUZASHI body frames.
const OWN_FRAMES: SpriteFrames = preload("res://assets/characters/black_coat/black_coat_frames.res")
const ALIASES := {"AIR_PUNCH":"PUNCH","AIR_KICK":"KICK","BOUND":"HIT"}
func _ready() -> void:
	sprite_frames = OWN_FRAMES.duplicate(true)
	for clip: String in ALIASES:
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_loop(clip,false)
		for i in range(8): sprite_frames.add_frame(clip,OWN_FRAMES.get_frame_texture(ALIASES[clip],i))
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
	var factor: float = float(OWN_FRAMES.get_meta("scales").get(source,1.0))
	scale = Vector2.ONE*FRAME_SCALE*factor
	position = -Vector2(512,960)*FRAME_SCALE*factor
	return supported
