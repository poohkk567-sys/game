extends RefCounted
## One aligned side-view bank shared by buffs, empowered bind and the Fino ride.
const FRAMES: SpriteFrames = preload("res://assets/effects/side_guardians_frames.res")
const SPECTRAL: Shader = preload("res://assets/effects/side_guardians/spectral_aura.gdshader")

static func create(parent: Node) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = FRAMES
	sprite.centered = false
	sprite.visible = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var spectral := ShaderMaterial.new()
	spectral.shader = SPECTRAL
	sprite.material = spectral
	parent.add_child(sprite)
	return sprite

static func present(sprite: AnimatedSprite2D, kind: String, clock: float, direction: int, height: float, anchor: Vector2, opacity: float) -> void:
	sprite.visible = true
	sprite.animation = kind
	sprite.frame = floori(clock*8)%FRAMES.get_frame_count(kind)
	var factor: float = height/float(FRAMES.get_meta("heights")[kind])
	sprite.scale = Vector2(factor*direction,factor)
	sprite.position = anchor-Vector2(512*direction,960)*factor
	sprite.modulate = Color(1,1,1,clampf(opacity,0,1))
	var atlas: AtlasTexture = FRAMES.get_frame_texture(kind,sprite.frame)
	var spectral: ShaderMaterial = sprite.material
	spectral.set_shader_parameter("region_origin",atlas.region.position/atlas.atlas.get_size())
	spectral.set_shader_parameter("region_extent",atlas.region.size/atlas.atlas.get_size())
