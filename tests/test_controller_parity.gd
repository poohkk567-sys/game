extends "res://tests/test_contact_controls.gd"
## Compare real keyboard events with normal and remapped controller buttons.
var pads: Node

func prepare(profile: String, second: bool, remapped: bool = false) -> PhuzashiCharacter:
	await setup(profile)
	var actor: PhuzashiCharacter = a
	if second:
		b.select_fighter(profile)
		b.energy = 100
		if profile == "RED_CAP":
			b.red_awakened = true
			b.rig.set_red_awakened(true)
		actor = b
		await frames(3)
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	if remapped:
		var prefix: String = "p2_" if second else "p1_"
		Profile.remap(pads.profile.bindings[prefix],"kick",Profile.button(JOY_BUTTON_A))
		Profile.remap(pads.profile.bindings[prefix],"guard",Profile.button(JOY_BUTTON_Y))
	pads.waiting_neutral = false
	pads._apply_layout()
	return actor

func run() -> void:
	stage = load("res://scenes/versus_school.tscn").instantiate()
	root.add_child(stage)
	await frames(8)
	a = stage.p1
	b = stage.p2
	pads = root.get_node("Gamepads")
	pads.profile.preferences = {"p1_":{"mode":"auto"},"p2_":{"mode":"auto"}}
	pads.configure_devices([2,5],{2:{"guid":"parity1","name":"Pad1"},5:{"guid":"parity2","name":"Pad2"}})
	for profile: String in Book.ROSTER:
		for second: bool in [false,true]:
			for slot in range(1,5):
				var actor: PhuzashiCharacter = await prepare(profile,second)
				var down: int = KEY_DOWN if second else KEY_S
				var code: int = ([KEY_KP_1,KEY_KP_2,KEY_KP_3,KEY_CTRL] if second else [KEY_J,KEY_K,KEY_L,KEY_SHIFT])[slot-1]
				key(down,true)
				await frames(2)
				key(code,true)
				await frames(2)
				var keyboard_action: String = actor.action_name
				check(keyboard_action == Book.ROSTER[profile][slot],"Keyboard reference cast "+profile+" slot="+str(slot+1))
				for remapped: bool in [false,true]:
					actor = await prepare(profile,second,remapped)
					var device: int = 5 if second else 2
					var codes: Array = [JOY_BUTTON_X,JOY_BUTTON_A,JOY_BUTTON_Y,JOY_BUTTON_RIGHT_SHOULDER] if remapped else [JOY_BUTTON_X,JOY_BUTTON_B,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]
					button(device,JOY_BUTTON_DPAD_DOWN,true)
					await frames(2)
					button(device,codes[slot-1],true)
					await frames(2)
					check(actor.action_name == keyboard_action,"Controller matches keyboard: %s P%d slot%d remapped=%s" % [profile,2 if second else 1,slot+1,str(remapped)])
					var other: PhuzashiCharacter = a if second else b
					check(other.action_name == "","Controller cast does not trigger the other player")
			var jumper: PhuzashiCharacter = await prepare(profile,second)
			var device: int = 5 if second else 2
			button(device,JOY_BUTTON_DPAD_DOWN,true)
			await frames(2)
			button(device,JOY_BUTTON_A,true)
			await frames(2)
			check(jumper.action_name == "" and jumper.energy == 100 and jumper.is_on_floor(),"Down+jump no longer steals the kick skill: "+profile)
			button(device,JOY_BUTTON_DPAD_DOWN,false)
			await frames(3)
			check(jumper.is_on_floor() and jumper.jump_buffer == 0,"Crouching jump never leaves an accidental buffered jump")
	release()
	pads.configure_devices([])
	stage.queue_free()
	await frames(3)
	set_meta("clear_training",true)
	var training: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(training)
	await frames(6)
	training.phuzashi.energy = 100
	pads.profile.bindings = {"p1_":Profile.defaults(),"p2_":Profile.defaults()}
	pads.configure_devices([2],{2:{"guid":"solo-parity","name":"Solo Pad"}})
	pads.waiting_neutral = false
	pads._apply_layout()
	button(2,JOY_BUTTON_DPAD_DOWN,true)
	await frames(2)
	button(2,JOY_BUTTON_B,true)
	await frames(2)
	check(training.phuzashi.action_name == "CHEER" and training.phuzashi.energy == 70,"Solo down+kick starts the same 30-MP cheer as S+K")
	release()
	await frames(55)
	check(get_nodes_in_group("cheer_assists").size() == 1 and training.phuzashi.cheer_buff > 7,"Controller cheer actually summons the girl and grants her buff")
	pads.configure_devices([])
	training.queue_free()
	await frames(3)
	print("CONTROLLER PARITY RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
