extends RefCounted
## Dedicated scarlet effects; the source atlas is preserved, never recolored.
const FRAMES: SpriteFrames = preload("res://assets/effects/black_skills/crimson_frames.res")
const CLIPS := {"BLOOD_FANG":"FANG","RAGE_DRIVE":"DRIVE","HELL_RISER":"RISE","GRIN_CRUSH":"CRUSH","CRIMSON_BURST":"BURST"}

static func frame(canvas: CanvasItem, clip: String, progress: float, center: Vector2, size: Vector2, opacity: float = 1) -> void:
	var texture: Texture2D = FRAMES.get_frame_texture(clip,mini(3,floori(clampf(progress,0,0.999)*4)))
	canvas.draw_texture_rect(texture,Rect2(center-size*0.5,size),false,Color(1,1,1,clampf(opacity,0,1)))
