extends Sprite3D
## Original AtlasTextures, their virtual foot pivot and per-clip scale stay intact.
const Rules = preload("res://scripts/coop/coop_rules.gd")
const CHILL: SpriteFrames = preload("res://assets/characters/phuzashi_chill/chill_frames.res")
const ASS: SpriteFrames = preload("res://assets/characters/red_cap/red_cap_frames.res")
var frames: SpriteFrames
var profile: String = "PHUZASHI_CHILL"
var current_clip: String = "IDLE"
var current_frame: int = 0

func configure(value: String) -> void:
	profile = value
	frames = CHILL if profile == "PHUZASHI_CHILL" else ASS
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.5
	shaded = false
	double_sided = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	render_priority = 0
	show_pose("IDLE",0,1)

func show_pose(state: String, phase: float, facing: int) -> void:
	var clip: String = {"AIR_PUNCH":"PUNCH","AIR_KICK":"KICK","DOWN":"FALL","STUN":"HIT","REVIVE":"CROUCH","DASH":"RUN"}.get(state,state)
	if not frames.has_animation(clip): clip = "IDLE"
	current_clip = clip
	current_frame = Rules.frame_for(clip,phase) if clip in Rules.TIMING else mini(7,floori(clampf(phase,0,0.999)*8))
	texture = frames.get_frame_texture(clip,current_frame)
	var factor: float = float(frames.get_meta("scales").get(clip,1))
	pixel_size = 2.6/286.0*factor
	# A centred 1024x1024 atlas has its original foot pivot at (512,960).
	position = Vector3(0,448*pixel_size,0)
	flip_h = facing < 0
