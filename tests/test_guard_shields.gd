extends SceneTree
var samples: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(512,360)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	floor_shape.shape = RectangleShape2D.new()
	floor_shape.shape.size = Vector2(700,20)
	floor_body.position = Vector2(256,320)
	floor_body.add_child(floor_shape)
	view.add_child(floor_body)
	for profile: String in ["PHUZASHI","RED_CAP","MUAY_THAI"]:
		for direction: int in [-1,1]:
			for crouched: bool in [false,true]:
				var fighter: PhuzashiCharacter = load("res://scenes/phuzashi.tscn").instantiate()
				view.add_child(fighter)
				fighter.select_fighter(profile)
				fighter.rig.set_clear_enabled(true)
				fighter.position = Vector2(256,310)
				fighter.facing = direction
				Input.action_press("guard")
				if crouched: Input.action_press("crouch")
				await frames(18)
				fighter.effects.visible = false
				await process_frame
				await RenderingServer.frame_post_draw
				var base: Image = view.get_texture().get_image()
				fighter.effects.visible = true
				fighter.effects.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var rendered: Image = view.get_texture().get_image()
				var added: int = 0
				for y in range(360):
					for x in range(512):
						var pixel: Color = rendered.get_pixel(x,y)
						if pixel.a > 0.08 and pixel != base.get_pixel(x,y): added += 1
				if not fighter.can_guard() or added < 150:
					failures += 1
					push_error("Shield missing: "+profile+" dir="+str(direction)+" crouch="+str(crouched)+" pixels="+str(added))
				samples += 1
				Input.action_release("guard")
				Input.action_release("crouch")
				fighter.queue_free()
				await frames(2)
	view.queue_free()
	await process_frame
	print("GUARD SHIELD RENDER: %d samples, %d failures" % [samples,failures])
	quit(1 if failures else 0)
