extends Node3D
const Rules = preload("res://scripts/coop/coop_rules.gd")
const Player = preload("res://scripts/coop/coop_player.gd")
const Boss = preload("res://scripts/coop/coop_boss.gd")
const World = preload("res://scripts/coop/coop_world.gd")
const V = preload("res://scripts/coop/coop_visuals.gd")
const Fx = preload("res://scripts/coop/coop_hit_fx.gd")
const Hud = preload("res://scripts/coop/coop_hud.gd")
var team: Array[CharacterBody3D] = []
var boss: CharacterBody3D
var camera: Camera3D
var hud: Control
var state: String = "READY"
var state_time: float = 0
var elapsed: float = 0
var paused: bool = false
var pause_reason: String = ""
var show_help: bool = false
var shake: float = 0
var shake_power: float = 0
var clock: float = 0
var camera_target := Vector3.ZERO
var framing := Vector2.ZERO
var audio: AudioStreamPlayer
var sounds: Dictionary = {}

func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	preload("res://scripts/character/input_setup.gd").install()
	preload("res://scripts/coop/coop_input.gd").install()
	process_priority = 10
	for property: Dictionary in get_property_list():
		if property.name == "process_physics_priority": set("process_physics_priority",10)

func _ready() -> void:
	get_tree().paused = false
	World.build(self)
	for i in range(2):
		var player := Player.new()
		player.name = "PHUZASHI_CHILL" if i == 0 else "ASSJIRO"
		player.player_id = i
		player.profile = Rules.PROFILES[i]
		player.spawn = Vector3(-3+i*2.2,0.05,2.0+i*1.2)
		team.append(player)
		add_child(player)
	boss = Boss.new()
	boss.name = "ObsidianWarden"
	add_child(boss)
	camera = Camera3D.new()
	camera.name = "SharedCamera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16.5
	camera.near = 0.1
	camera.far = 120
	camera.current = true
	add_child(camera)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -17
	audio.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(audio)
	var layer := CanvasLayer.new()
	layer.name = "CoopHUD"
	add_child(layer)
	hud = Hud.new()
	hud.arena = self
	layer.add_child(hud)
	Gamepads.set_context("COOP")
	Gamepads.pause_requested.connect(toggle_pause)
	Gamepads.help_requested.connect(toggle_help)
	Gamepads.device_changed.connect(controller_changed)
	restart()
	update_camera(1)

func restart() -> void:
	paused = false
	get_tree().paused = false
	pause_reason = ""
	show_help = false
	state = "READY"
	state_time = 0
	elapsed = 0
	shake = 0
	for player: Node3D in team: player.reset(player.spawn)
	boss.reset()
	for effect: Node in get_tree().get_nodes_in_group("coop_hit_fx"): effect.queue_free()
	Gamepads.suspend_until_neutral()

func toggle_pause() -> void:
	if Gamepads.settings_open: return
	if state in ["VICTORY","DEFEAT"]:
		restart()
		return
	paused = not paused
	pause_reason = ""
	Gamepads.suspend_until_neutral()
	get_tree().paused = paused

func toggle_help() -> void:
	if not Gamepads.settings_open: show_help = not show_help

func controller_changed() -> void:
	paused = true
	pause_reason = "CHECK P1 / P2 CONTROLLERS, THEN RESUME"
	get_tree().paused = true

func return_to_menu() -> void:
	get_tree().paused = false
	Gamepads.suspend_until_neutral()
	get_tree().change_scene_to_file("res://scenes/title_menu.tscn")

func _exit_tree() -> void:
	var manager: Node = get_node_or_null("/root/Gamepads")
	if is_instance_valid(manager): manager.set_context("VERSUS")

func _input(event: InputEvent) -> void:
	if Gamepads.settings_open: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: toggle_pause()
			KEY_F1: toggle_help()
			KEY_F8: return_to_menu()
			KEY_R: restart()

func _physics_process(delta: float) -> void:
	if paused: return
	clock += delta
	state_time += delta
	shake = maxf(0,shake-delta)
	if state == "READY" and state_time >= 1.8:
		state = "FIGHT"
		state_time = 0
	elif state == "FIGHT":
		elapsed += delta
		update_revive(delta)
		if boss.health <= 0:
			state = "VICTORY"
			state_time = 0
		elif team.all(func(player: Node3D) -> bool: return player.downed):
			state = "DEFEAT"
			state_time = 0
	if is_instance_valid(boss.tell):
		var fill: StandardMaterial3D = boss.tell.get_meta("fill")
		var danger: bool = boss.state == "ACTIVE" or boss.state_time > boss.windup_time*0.70
		fill.albedo_color = Color(1,0.12 if danger else 0.53,0.10,0.15+sin(clock*13)*0.045)
	update_camera(delta)

func update_revive(delta: float) -> void:
	for player: Node3D in team: player.reviving = false
	for down: Node3D in team:
		if not down.downed: continue
		var helper: Node3D = team[1-down.player_id]
		var can_help: bool = not helper.downed and helper.stun <= 0 and helper.guard_break <= 0 and not helper.guarding and helper.movement_axis().length() < 0.1 and helper.action.is_empty() and helper.is_on_floor() and helper.dash_remaining <= 0 and helper.pressed("coop_revive") and Rules.flat(helper.global_position-down.global_position).length() <= Rules.REVIVE_RANGE
		if can_help:
			helper.reviving = true
			down.revive_progress += delta
			if down.revive_progress >= Rules.REVIVE_TIME:
				down.revive()
				helper.reviving = false
		else: down.revive_progress = 0

func update_camera(delta: float) -> void:
	var center: Vector3 = (team[0].position+team[1].position+boss.position)/3
	center = Vector3(clampf(center.x,-2.6,2.6),0,clampf(center.z,-1.0,1.0))
	camera_target = camera_target.lerp(center,1-exp(-delta*3.0))
	var target: Vector3 = camera_target+Vector3(0,1.8,0)
	camera.position = camera_target+Vector3(0,11.5,20)
	camera.look_at(target)
	var inverse: Basis = camera.global_basis.inverse()
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	for actor: Node3D in [team[0],team[1],boss]:
		for height: float in [0.0,5.7 if actor == boss else 2.9]:
			var point: Vector3 = inverse*(actor.global_position+Vector3(0,height,0)-target)
			min_x = minf(min_x,point.x-1.7)
			max_x = maxf(max_x,point.x+1.7)
			min_y = minf(min_y,point.y-0.5)
			max_y = maxf(max_y,point.y+0.5)
	var aspect: float = get_viewport().get_visible_rect().size.aspect()
	var desired: float = clampf(maxf((max_y-min_y)/0.63,(max_x-min_x)/maxf(1,aspect)/0.90),17.0,23.5)
	camera.size = lerpf(camera.size,desired,1-exp(-delta*2.8))
	framing = framing.lerp(Vector2((max_x+min_x)*0.5,(max_y+min_y)*0.5+desired*0.035),1-exp(-delta*3.5))
	camera.position += camera.global_basis.x*framing.x+camera.global_basis.y*framing.y
	if shake > 0:
		camera.position += Vector3(sin(clock*137),cos(clock*111),0)*shake_power*shake/0.18

func make_telegraph(kind: String, origin: Vector3, aim: Vector2, center: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "BossTelegraph"
	root.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(root)
	root.position = center if kind == "SLAM" else origin
	root.position.y = 0.06
	var fill: StandardMaterial3D = V.material(Color(1,0.5,0.1,0.18),0,true)
	root.set_meta("fill",fill)
	if kind == "SLAM":
		var disc := CylinderMesh.new()
		disc.height = 0.006
		disc.top_radius = Rules.RADIUS.SLAM
		disc.bottom_radius = Rules.RADIUS.SLAM
		disc.radial_segments = 64
		V.mesh(root,disc,fill)
		V.ring(root,Rules.RADIUS.SLAM,0.07,Color("ffb45d"))
	elif kind == "SWEEP":
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var start: float = atan2(aim.y,aim.x)-PI*0.5
		for i in range(32):
			var a: float = start+PI*i/32
			var b: float = start+PI*(i+1)/32
			V.triangle(builder,Vector3.ZERO,Vector3(cos(a),0,sin(a))*Rules.RADIUS.SWEEP,Vector3(cos(b),0,sin(b))*Rules.RADIUS.SWEEP)
		V.mesh(root,builder.commit(),fill)
		V.ring(root,Rules.RADIUS.SWEEP,0.07,Color("ffb45d"),start,PI)
	else:
		root.rotation.y = atan2(aim.x,aim.y)
		var lane := PlaneMesh.new()
		lane.size = Vector2(Rules.CHARGE_HALF_WIDTH*2,Rules.CHARGE_LENGTH)
		V.mesh(root,lane,fill,Vector3(0,0,Rules.CHARGE_LENGTH*0.5))
		for side: int in [-1,1]:
			var border := V.block(root,Vector3(0.055,0.008,Rules.CHARGE_LENGTH),Vector3(side*Rules.CHARGE_HALF_WIDTH,0.01,Rules.CHARGE_LENGTH*0.5),V.material(Color("ffb45d"),0.5),0.001)
			border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

func impact(point: Vector3, amount: int, player_id: int, heavy: bool, received: bool = false, perfect: bool = false) -> void:
	# Presentation has no gameplay side effects; dedicated/headless servers omit it.
	if DisplayServer.get_name() == "headless": return
	var effect := Fx.new()
	effect.position = point
	effect.damage = amount
	effect.heavy = heavy
	effect.perfect = perfect
	effect.tint = Color("a4f8ff") if perfect else (Color("ff6d56") if received else (Color("c99bff") if player_id == 0 else Color("ffce79")))
	add_child(effect)
	shake = maxf(shake,0.18)
	shake_power = maxf(shake_power,0.12 if heavy else 0.045)
	play_sound(heavy,perfect)
	var device: int = int(Gamepads.assignments.get("p%d_" % (player_id+1),-1))
	if device in Input.get_connected_joypads(): Input.start_joy_vibration(device,0.18,0.45 if heavy else 0.18,0.08)

func play_sound(heavy: bool, perfect: bool) -> void:
	var kind: int = 2 if perfect else (1 if heavy else 0)
	if not sounds.has(kind):
		var sound := AudioStreamWAV.new()
		sound.format = AudioStreamWAV.FORMAT_16_BITS
		sound.mix_rate = 22050
		var duration: float = 0.18 if heavy else 0.09
		var data := PackedByteArray()
		data.resize(int(duration*22050)*2)
		for i in range(data.size()/2):
			var t: float = float(i)/22050
			var frequency: float = 1100 if perfect else (85 if heavy else 190)
			var sample: float = (sin(TAU*frequency*t*(1-t/duration*0.3))*0.65+sin(i*12.9898)*sin(i*78.233)*0.30)*pow(1-t/duration,2)*minf(1,t/0.005)
			data.encode_s16(i*2,int(sample*22000))
		sound.data = data
		sounds[kind] = sound
	audio.stream = sounds[kind]
	audio.play()
