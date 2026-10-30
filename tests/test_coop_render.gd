extends "res://tests/test_roster_render.gd"
const Sprite = preload("res://scripts/coop/coop_sprite.gd")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512,360)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.5
	camera.position = Vector3(0,2.8,8)
	viewport.add_child(camera)
	camera.look_at(Vector3(0,1.35,0))
	camera.current = true
	var sprite := Sprite.new()
	viewport.add_child(sprite)
	for profile: String in ["PHUZASHI_CHILL","RED_CAP"]:
		sprite.configure(profile)
		for direction: int in [-1,1]:
			for clip: String in ["IDLE","WALK","RUN","JUMP","GUARD","PUNCH","PUNCH_2","PUNCH_3","KICK","KICK_2","KICK_3","HIT","FALL"]:
				for index in range(8):
					sprite.show_pose(clip,(index+0.01)/8.0,direction)
					sprite.texture = sprite.frames.get_frame_texture(clip,index)
					await inspect(viewport,"3D / "+profile+" / "+clip+" / "+str(index)+" / "+str(direction))
	viewport.queue_free()
	await process_frame
	print("COOP RENDER RESULT: %d samples, %d failures" % [samples,failures])
	quit(1 if failures else 0)
