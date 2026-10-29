extends SceneTree
## Render the new overlays around both intact Red Cap bodies in both directions.
var failures: int = 0
var samples: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512,360)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var fighter: PhuzashiCharacter = load("res://scenes/phuzashi.tscn").instantiate()
	viewport.add_child(fighter)
	fighter.set_physics_process(false)
	fighter.position = Vector2(256,315)
	fighter.select_fighter("RED_CAP")
	# select_fighter restores arena coordinates; place back into the isolated viewport.
	fighter.position = Vector2(256,315)
	for awakened: bool in [false,true]:
		fighter.red_awakened = awakened
		fighter.rig.set_red_awakened(awakened)
		for direction: int in [-1,1]:
			fighter.facing = direction
			for action: String in ["CARROT_HEADBUTT","CARROT_RUSH","CHARGE","PERFECT GUARD","GUARD BREAK"]:
				var count: int = 16 if action.begins_with("CARROT") else 1
				for index in range(count):
					fighter.charging = action == "CHARGE"
					fighter.defense_feedback = action
					fighter.defense_feedback_time = 0.25 if action in ["PERFECT GUARD","GUARD BREAK"] else 0.0
					fighter.action_name = action if action.begins_with("CARROT") else ""
					fighter.action_duration = 1.0
					var start: float = 0.18 if action == "CARROT_HEADBUTT" else 0.20
					var end: float = 0.67 if action == "CARROT_HEADBUTT" else 0.71
					var progress: float = (index+0.5)/4.0*start if index < 4 else (start+(index-4+0.5)/8.0*(end-start) if index < 12 else end+(index-12+0.5)/4.0*(1-end))
					fighter.action_timer = 1.0-progress if action.begins_with("CARROT") else 0.0
					fighter.rig.rotation = direction*0.25 if action == "CARROT_HEADBUTT" else 0.0
					fighter.rig.animate("RUN" if action == "CARROT_HEADBUTT" else ("PUNCH_2" if action == "CARROT_RUSH" else "GUARD"),1.0/60.0,direction,0.38)
					fighter.effects.visible = false
					fighter.queue_redraw()
					await process_frame
					await RenderingServer.frame_post_draw
					var baseline: Image = viewport.get_texture().get_image()
					fighter.effects.visible = true
					fighter.effects.queue_redraw()
					await process_frame
					await RenderingServer.frame_post_draw
					var rendered: Image = viewport.get_texture().get_image()
					var changed: int = 0
					var clipped: bool = false
					for y in range(360):
						for x in range(512):
							var pixel: Color = rendered.get_pixel(x,y)
							if pixel.a > 0.15 and pixel != baseline.get_pixel(x,y):
								changed += 1
							if (x <= 1 or x >= 510 or y <= 1) and pixel.a > 0.5:
								clipped = true
					if changed < 100 or clipped or not fighter.rig.draft_animation.visible:
						failures += 1
						push_error("New VFX render %s/%d form=%s dir=%d added=%d clipped=%s" % [action,index,awakened,direction,changed,clipped])
					samples += 1
	viewport.queue_free()
	await process_frame
	print("MANA CARROT RENDER: %d samples, %d failures" % [samples,failures])
	quit(1 if failures else 0)
