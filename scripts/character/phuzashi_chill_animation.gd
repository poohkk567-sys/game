extends "res://scripts/character/draft_sprite_animation.gd"
## Complete redesigned body, relaxed three-hit punches; original skill timing.
const OWN_FRAMES: SpriteFrames = preload("res://assets/characters/phuzashi_chill/chill_frames.res")
const ALIASES := {"AIR_PUNCH":"PUNCH","AIR_KICK":"KICK","BOUND":"HIT","DEMON_BIND":"SPECIAL"}
func _ready() -> void:
	sprite_frames = OWN_FRAMES.duplicate(true)
	for clip: String in ALIASES:
		sprite_frames.add_animation(clip)
		sprite_frames.set_animation_loop(clip,false)
		for i in range(8): sprite_frames.add_frame(clip,OWN_FRAMES.get_frame_texture(ALIASES[clip],i))
	sprite_frames.add_animation("BLINK")
	sprite_frames.set_animation_loop("BLINK",false)
	for pose: Array in BLINK_POSES:
		sprite_frames.add_frame("BLINK",OWN_FRAMES.get_frame_texture(pose[0],pose[1]))
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://assets/characters/phuzashi_chill/chill_cutout.gdshader")
	material = cutout
	visible = false

func show_state(state: String, enabled: bool, progress: float = -1.0) -> bool:
	if progress < 0 and state in ["CROUCH","GUARD"]:
		var rig: Node2D = get_parent()
		progress = minf(rig.clock/0.35,0.999)
	var supported: bool = super.show_state(state,enabled,progress)
	var source: String = ALIASES.get(state,state)
	if state == "BLINK": source = BLINK_POSES[clampi(frame,0,11)][0]
	var factor: float = float(OWN_FRAMES.get_meta("scales").get(source,1.0))
	scale = Vector2.ONE*FRAME_SCALE*factor
	position = -Vector2(512,960)*FRAME_SCALE*factor
	return supported

func combo_fist_global_position() -> Vector2:
	var atlas: AtlasTexture = sprite_frames.get_frame_texture("PUNCH_3",clampi(frame,0,7))
	# Whole-body frames remain intact; marker follows the striking right fist.
	var marker: Vector2 = [Vector2(0.65,0.48),Vector2(0.60,0.50),Vector2(0.83,0.38),Vector2(0.96,0.36),Vector2(0.96,0.36),Vector2(0.75,0.42),Vector2(0.65,0.48),Vector2(0.65,0.48)][clampi(frame,0,7)]
	return to_global(atlas.margin.position+atlas.region.size*marker)

func frame_at_progress(state: String, progress: float) -> int:
	var timing: Dictionary = {
		"PUNCH":[0.0,0.12,0.26,0.34,0.62,0.74,0.84,0.94],
		"AIR_PUNCH":[0.0,0.05,0.15,0.24,0.62,0.74,0.84,0.94],
		"KICK":[0.0,0.10,0.20,0.30,0.66,0.76,0.85,0.94],
		"AIR_KICK":[0.0,0.05,0.12,0.20,0.66,0.76,0.85,0.94],
		"KICK_2":[0.0,0.10,0.20,0.30,0.64,0.73,0.83,0.94],
		"KICK_3":[0.0,0.08,0.14,0.28,0.66,0.76,0.86,0.95]
	}
	if timing.has(state):
		var result: int = 0
		for i in range(8):
			if progress >= float(timing[state][i]): result = i
		return result
	return super.frame_at_progress(state,progress)
