extends SceneTree
var samples: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func inspect(viewport: SubViewport, label: String, alpha_threshold: float = 0.5) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(viewport.get_texture().get_image(),alpha_threshold)
	var large: int = 0
	var clipped: bool = false
	for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(0,0,512,360),0.2):
		var area: float = 0
		for i in range(polygon.size()):
			area += polygon[i].cross(polygon[(i+1)%polygon.size()])
			clipped = clipped or polygon[i].x <= 1 or polygon[i].x >= 511 or polygon[i].y <= 1
		if absf(area)*0.5 > 500: large += 1
	if large < 1 or clipped:
		failures += 1
		push_error("Roster render "+label+" body="+str(large)+" clipped="+str(clipped))
	samples += 1
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512,360)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rig: Node2D = load("res://scripts/character/phuzashi_rig.gd").new()
	viewport.add_child(rig)
	rig.position = Vector2(256,310)
	rig.set_character_profile("MUAY_THAI")
	for direction: int in [-1,1]:
		for clip: StringName in rig.draft_animation.sprite_frames.get_animation_names():
			for index in range(8):
				rig.animate(clip,1.0/60,direction,float(index)/8)
				rig.draft_animation.frame = index
				await inspect(viewport,"MUAY "+clip+"/"+str(index)+" dir="+str(direction))
	for profile: String in ["BLACK_COAT","PHUZASHI_CHILL"]:
		rig.set_character_profile(profile)
		for direction: int in [-1,1]:
			for clip: StringName in rig.draft_animation.sprite_frames.get_animation_names():
				for index in range(rig.draft_animation.sprite_frames.get_frame_count(clip)):
					rig.animate(clip,1.0/60,direction,float(index)/rig.draft_animation.sprite_frames.get_frame_count(clip))
					rig.draft_animation.frame = index
					await inspect(viewport,profile+" "+clip+"/"+str(index)+" dir="+str(direction),0.05 if clip == "BLINK" and index == 6 else 0.5)
	rig.set_clear_enabled(true)
	rig.set_character_profile("PHUZASHI")
	for direction: int in [-1,1]:
		for index in range(8):
			rig.animate("WALK",1.0/60,direction,float(index)/8)
			await inspect(viewport,"WALK "+str(index)+" dir="+str(direction))
	rig.queue_free()
	await process_frame
	for bank: String in ["fino_ultimate","cheer_assist","chill_fino"]:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = load("res://assets/characters/"+("phuzashi_chill/fino_ultimate" if bank == "chill_fino" else "phuzashi_clear/"+bank)+"_frames.res")
		sprite.centered = false
		viewport.add_child(sprite)
		var factor: float = (148.0 if bank == "cheer_assist" else 188.0)/float(sprite.sprite_frames.get_meta("source_height"))
		for direction: int in [-1,1]:
			sprite.scale = Vector2(factor*direction,factor)
			sprite.position = Vector2(256,310)-Vector2(512*direction,960)*factor
			for clip: StringName in sprite.sprite_frames.get_animation_names():
				sprite.animation = clip
				for index in range(sprite.sprite_frames.get_frame_count(clip)):
					sprite.frame = index
					await inspect(viewport,bank+"/"+clip+"/"+str(index))
		sprite.queue_free()
		await process_frame
	for bank: String in ["side_guardians","blood_door"]:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = load("res://assets/effects/"+bank+"_frames.res")
		sprite.centered = false
		viewport.add_child(sprite)
		for clip: StringName in sprite.sprite_frames.get_animation_names():
			var factor: float = (252.0 if clip == "GOLD" else 230.0)/float(sprite.sprite_frames.get_meta("heights")[clip])
			for direction: int in [-1,1]:
				sprite.scale = Vector2(factor*direction,factor)
				sprite.position = Vector2(256,310)-Vector2(512*direction,960)*factor
				sprite.animation = clip
				for index in range(sprite.sprite_frames.get_frame_count(clip)):
					sprite.frame = index
					await inspect(viewport,bank+"/"+clip+"/"+str(index))
		sprite.queue_free()
		await process_frame
	var grapple := AnimatedSprite2D.new()
	grapple.sprite_frames = load("res://assets/effects/ninja_grapple_frames.res")
	grapple.centered = false
	grapple.animation = "GRIP"
	viewport.add_child(grapple)
	for direction: int in [-1,1]:
		var factor: float = 116.0/float(grapple.sprite_frames.get_meta("height"))
		grapple.scale = Vector2(direction*factor,factor)
		grapple.position = Vector2(256,310)-Vector2(direction*512,960)*factor
		for index in range(8):
			grapple.frame = index
			await inspect(viewport,"COMPACT REAR NINJA/"+str(index)+"/"+str(direction))
	grapple.queue_free()
	var caster := AnimatedSprite2D.new()
	caster.sprite_frames = load("res://assets/characters/ninja_cast/cast_frames.res")
	caster.centered = false
	viewport.add_child(caster)
	for clip: StringName in caster.sprite_frames.get_animation_names():
		var factor: float = 156.0/float(caster.sprite_frames.get_meta("heights")[clip])
		caster.animation = clip
		for direction: int in [-1,1]:
			caster.scale = Vector2(direction*factor,factor)
			caster.position = Vector2(256,310)-Vector2(direction*512,960)*factor
			for index in range(8):
				caster.frame = index
				await inspect(viewport,"CAST/"+clip+"/"+str(index)+"/"+str(direction))
	caster.queue_free()
	viewport.queue_free()
	await process_frame
	print("ROSTER RENDER RESULT: %d samples, %d failures" % [samples,failures])
	quit(1 if failures else 0)
