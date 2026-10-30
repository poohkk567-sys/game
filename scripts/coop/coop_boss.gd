extends CharacterBody3D
## Three readable 3D attacks with frozen telegraphs and one hit per player/cast.
const Rules = preload("res://scripts/coop/coop_rules.gd")
const Visuals = preload("res://scripts/coop/coop_visuals.gd")
var arena: Node3D
var health: float = Rules.BOSS_HEALTH
var hurt_radius: float = 1.05
var state: String = "IDLE"
var attack: String = ""
var state_time: float = 0
var windup_time: float = 1
var recovery: float = 0
var attack_index: int = 0
var aim := Vector2.DOWN
var attack_origin: Vector3
var attack_center: Vector3
var struck: Dictionary = {}
var ai_enabled: bool = true
var enraged: bool = false
var stagger: float = 0
var stagger_lock: float = 0
var pause_remaining: float = 0
var flash: float = 0
var clock: float = 0
var travelled: float = 0
var rig: Node3D
var torso: MeshInstance3D
var head: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var tell: Node3D
var pulse_ring: MeshInstance3D
var stone_material: StandardMaterial3D
var glow_material: StandardMaterial3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	arena = get_parent()
	collision_layer = 4
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = hurt_radius
	shape.height = 4.7
	collider.shape = shape
	collider.position.y = 2.35
	add_child(collider)
	build_rig()
	reset()

func build_rig() -> void:
	stone_material = Visuals.material(Color("343847"))
	var armor := Visuals.material(Color("565d70"))
	var rim := Visuals.material(Color("b09a72"))
	var dark := Visuals.material(Color("171c2a"))
	glow_material = Visuals.material(Color("ff463c"),1.7)
	rig = Node3D.new()
	add_child(rig)
	Visuals.block(rig,Vector3(1.8,0.65,1.2),Vector3(0,1.7,0),dark,0.15)
	torso = Visuals.block(rig,Vector3(2.45,2.0,1.38),Vector3(0,3.0,0),stone_material,0.24)
	Visuals.block(rig,Vector3(2.6,0.32,1.5),Vector3(0,3.75,0),rim,0.10)
	for side: int in [-1,1]:
		var leg := Node3D.new()
		leg.position = Vector3(side*0.61,1.6,0)
		rig.add_child(leg)
		Visuals.block(leg,Vector3(0.73,1.1,0.83),Vector3(0,-0.52,0),stone_material,0.15)
		Visuals.block(leg,Vector3(0.88,0.66,1.16),Vector3(0,-1.27,0.13),armor,0.13)
		Visuals.block(leg,Vector3(0.10,0.44,0.025),Vector3(side*0.13,-1.16,0.72),glow_material,0.01)
		legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(side*1.60,3.8,0)
		rig.add_child(arm)
		Visuals.block(arm,Vector3(1.18,0.90,1.48),Vector3(0,-0.15,0),armor,0.20)
		Visuals.block(arm,Vector3(1.28,0.16,1.56),Vector3(0,0.12,0),rim,0.06)
		Visuals.block(arm,Vector3(0.68,0.75,0.72),Vector3(0,-0.85,0),dark,0.13)
		Visuals.block(arm,Vector3(1.02,0.85,1.00),Vector3(0,-1.30,0.06),stone_material,0.17)
		Visuals.block(arm,Vector3(1.22,0.78,1.24),Vector3(0,-1.90,0.15),armor,0.17)
		for digit in range(3):
			Visuals.block(arm,Vector3(0.20,0.50,0.10),Vector3(-0.35+digit*0.35,-1.93,0.80),rim,0.025)
		Visuals.block(arm,Vector3(0.06,0.66,0.025),Vector3(0.22,-1.30,0.58),glow_material,0.01)
		arms.append(arm)
	head = Node3D.new()
	head.position.y = 4.6
	rig.add_child(head)
	Visuals.block(head,Vector3(1.45,1.05,1.25),Vector3.ZERO,armor,0.20)
	Visuals.block(head,Vector3(1.24,0.70,0.15),Vector3(0,-0.04,0.63),dark,0.06)
	for side: int in [-1,1]:
		var eye := Visuals.block(head,Vector3(0.39,0.11,0.07),Vector3(side*0.31,0.10,0.73),glow_material,0.015)
		eye.rotation.z = -side*0.22
		var horn := CylinderMesh.new()
		horn.top_radius = 0
		horn.bottom_radius = 0.19
		horn.height = 0.92
		horn.radial_segments = 5
		var spike := Visuals.mesh(head,horn,rim,Vector3(side*0.63,0.73,-0.13))
		spike.rotation.z = -side*0.33
	for i in range(5): Visuals.block(head,Vector3(0.12,0.10,0.06),Vector3(-0.36+i*0.18,-0.24,0.74),rim,0.01)
	var crystal := SphereMesh.new()
	crystal.radius = 0.33
	crystal.height = 0.72
	crystal.radial_segments = 8
	crystal.rings = 4
	Visuals.mesh(rig,crystal,glow_material,Vector3(0,3.05,0.78))
	for side: int in [-1,1]:
		for i in range(3):
			var slash := Visuals.block(rig,Vector3(0.38,0.045,0.04),Vector3(side*(0.47+i*0.13),3.28-i*0.25,0.73),glow_material,0.01)
			slash.rotation.z = side*0.48
	var light := OmniLight3D.new()
	light.light_color = Color("ff4b3e")
	light.light_energy = 1.3
	light.omni_range = 4.0
	light.position = Vector3(0,3,0.9)
	add_child(light)
	pulse_ring = Visuals.ring(self,1.48,0.075,Color("e76849"))

func reset() -> void:
	health = Rules.BOSS_HEALTH
	position = Vector3(2.6,0,-1.8)
	velocity = Vector3.ZERO
	state = "IDLE"
	attack = ""
	state_time = 0
	recovery = 0.8
	attack_index = 0
	stagger = 0
	stagger_lock = 0
	pause_remaining = 0
	flash = 0
	enraged = false
	struck.clear()
	if is_instance_valid(tell): tell.queue_free()
	tell = null
	present()

func nearest() -> Node3D:
	var result: Node3D
	var distance: float = INF
	for player: Node3D in arena.team:
		if player.downed: continue
		var current: float = Rules.flat(player.global_position-global_position).length_squared()
		if current < distance:
			distance = current
			result = player
	return result

func start_attack(kind: String, target: Vector3) -> bool:
	if arena.state != "FIGHT" or health <= 0 or state in ["WINDUP","ACTIVE","STAGGERED","DEAD"] or not Rules.WINDUP.has(kind): return false
	attack = kind
	state = "WINDUP"
	state_time = 0
	travelled = 0
	windup_time = float(Rules.WINDUP[kind])*(0.88 if enraged else 1)
	attack_origin = Vector3(position.x,0,position.z)
	aim = Rules.direction(attack_origin,target)
	attack_center = Vector3(clampf(target.x,-8.8,8.8),0,clampf(target.z,-5.0,5.0)) if kind == "SLAM" else attack_origin
	struck.clear()
	if is_instance_valid(tell): tell.queue_free()
	tell = arena.make_telegraph(kind,attack_origin,aim,attack_center)
	return true

func take_hit(damage: int, pressure: int, source: Node3D) -> int:
	if health <= 0 or arena.state != "FIGHT" or source not in arena.team or source.downed: return -1
	var amount: int = roundi(damage*1.2) if state == "STAGGERED" else damage
	health = maxf(0,health-amount)
	source.damage_dealt += amount
	flash = 0.14
	pause_remaining = 0.025
	if state != "STAGGERED" and stagger_lock <= 0:
		stagger += pressure
		if stagger >= 140:
			state = "STAGGERED"
			state_time = 0
			stagger = 0
			velocity.y = 0
			stagger_lock = 5
			if is_instance_valid(tell): tell.queue_free()
			tell = null
	if health < Rules.BOSS_HEALTH*0.5: enraged = true
	if health <= 0:
		state = "DEAD"
		state_time = 0
		if is_instance_valid(tell): tell.queue_free()
		tell = null
	return amount

func _physics_process(delta: float) -> void:
	clock += delta
	flash = maxf(0,flash-delta)
	if arena.state != "FIGHT":
		if state == "DEAD":
			state_time += delta
			position.y = maxf(0,position.y-delta*5)
		present()
		return
	if pause_remaining > 0:
		pause_remaining = maxf(0,pause_remaining-delta)
		present()
		return
	state_time += delta
	if health <= 0:
		present()
		return
	stagger_lock = maxf(0,stagger_lock-delta)
	if state == "STAGGERED":
		position.y = maxf(0,position.y-delta*5)
		if state_time >= 2:
			state = "IDLE"
			recovery = 0.8
		present()
		return
	if state == "WINDUP":
		if attack == "SLAM":
			var q: float = smoothstep(0.52,1,state_time/windup_time)
			position = attack_origin.lerp(attack_center,q)+Vector3(0,sin(q*PI)*2.8,0)
		if state_time >= windup_time:
			state = "ACTIVE"
			state_time = 0
			if attack == "SLAM": position = attack_center
			if attack != "CHARGE": hit_players()
	elif state == "ACTIVE":
		if attack == "CHARGE":
			var step: float = minf(14*delta,Rules.CHARGE_LENGTH-travelled)
			velocity = Rules.ground(aim)*step/maxf(delta,0.001)
			velocity.y = -2
			var previous: Vector3 = position
			move_and_slide()
			position.x = clampf(position.x,-9.2,9.2)
			position.z = clampf(position.z,-5.3,5.3)
			travelled += Rules.flat(position-previous).length()
			hit_players(previous)
		if state_time >= float(Rules.ACTIVE[attack]) or (attack == "CHARGE" and travelled >= Rules.CHARGE_LENGTH):
			state = "RECOVERY"
			state_time = 0
			if is_instance_valid(tell): tell.queue_free()
			tell = null
	elif state == "RECOVERY":
		if state_time >= (0.75 if enraged else 1.0):
			state = "IDLE"
			recovery = 0.4
			attack_index += 1
	elif ai_enabled:
		recovery = maxf(0,recovery-delta)
		var target: Node3D = nearest()
		if target != null:
			aim = Rules.direction(global_position,target.global_position)
			var distance: float = Rules.flat(target.global_position-global_position).length()
			var next: String = ["SWEEP","SLAM","CHARGE"][attack_index%3]
			if recovery <= 0 and distance < (7.3 if next == "CHARGE" else 3.2): start_attack(next,target.global_position)
			elif distance > 2.6:
				velocity = Rules.ground(aim)*(2.7 if enraged else 2.2)
				velocity.y = -2
				move_and_slide()
				position.x = clampf(position.x,-9.2,9.2)
				position.z = clampf(position.z,-5.3,5.3)
	present()

func hit_players(previous: Vector3 = Vector3.INF) -> void:
	for player: Node3D in arena.team:
		if player.downed or struck.has(player.player_id): continue
		var hit: bool = Rules.inside_attack(player.global_position,attack,attack_origin,aim,attack_center,player.position.y)
		if attack == "CHARGE":
			var start: Vector2 = Rules.flat(previous if previous.is_finite() else global_position)
			var end: Vector2 = Rules.flat(global_position)
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(Rules.flat(player.global_position),start,end)
			hit = closest.distance_to(Rules.flat(player.global_position)) < 1.45 and player.position.y < 1.2
		if hit:
			var amount: int = player.receive_hit(int(Rules.DAMAGE[attack])+(4 if enraged else 0),global_position,8 if attack == "SLAM" else 6,attack == "SLAM")
			if amount >= 0: struck[player.player_id] = true

func present() -> void:
	if not is_instance_valid(rig): return
	rig.rotation = Vector3(0,atan2(aim.x,aim.y),0)
	rig.position.y = 0
	head.rotation = Vector3.ZERO
	torso.rotation = Vector3.ZERO
	for i in range(2):
		arms[i].rotation = Vector3(sin(clock*2+i*1.4)*0.035,0,(-1 if i == 0 else 1)*0.12)
		legs[i].rotation.x = sin(clock*7+i*PI)*0.10 if state == "IDLE" and ai_enabled else 0
	if state == "WINDUP":
		var q: float = clampf(state_time/windup_time,0,1)
		if attack == "SWEEP":
			arms[1].rotation = Vector3(-1.2*q,-1.4*q,-0.4)
			torso.rotation.y = -0.35*q
		elif attack == "SLAM":
			for arm: Node3D in arms: arm.rotation.x = -2.5*minf(1,q*2)
		else:
			rig.rotation.x = 0.12*q
			for arm: Node3D in arms: arm.rotation.x = 0.4*q
	elif state == "ACTIVE":
		var q: float = clampf(state_time/float(Rules.ACTIVE[attack]),0,1)
		if attack == "SWEEP":
			arms[1].rotation = Vector3(-1.0,-1.4+q*2.8,-0.4)
			torso.rotation.y = -0.35+q*0.7
		elif attack == "SLAM":
			rig.position.y = -0.22
			torso.rotation.x = 0.20
			for arm: Node3D in arms: arm.rotation.x = -0.70
		else:
			rig.rotation.x = 0.22
			for arm: Node3D in arms: arm.rotation.x = -0.85
	elif state == "STAGGERED":
		rig.position.y = -0.5
		torso.rotation.x = 0.22
		head.rotation.z = sin(clock*11)*0.06
	elif state == "DEAD":
		rig.position.y = -minf(1.1,state_time*0.55)
		rig.rotation.x = minf(1.1,state_time*0.5)
	stone_material.albedo_color = Color("ae6a63") if flash > 0 else Color("343847")
	glow_material.emission_energy_multiplier = 2.5 if enraged else 1.7
	pulse_ring.visible = health > 0
