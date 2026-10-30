extends CharacterBody3D
## A real 3D body carrying the approved side-view character atlas.
const Rules = preload("res://scripts/coop/coop_rules.gd")
const Body = preload("res://scripts/coop/coop_sprite.gd")
const Visuals = preload("res://scripts/coop/coop_visuals.gd")
var arena: Node3D
var player_id: int = 0
var profile: String = "PHUZASHI_CHILL"
var input_prefix: String = "p1_"
var display_name: String = "PHUZASHI CHILL"
var health: float = Rules.HEALTH
var guard_meter: float = 100
var guard_age: float = 999
var guard_held: bool = false
var guard_delay: float = 0
var guard_break: float = 0
var guarding: bool = false
var invulnerability: float = 0
var stun: float = 0
var hit_pause: float = 0
var recoil: Vector2
var recoil_time: float = 0
var facing: int = 1
var aim := Vector2.RIGHT
var action: String = ""
var action_elapsed: float = 0
var combo_family: String = ""
var combo_step: int = 0
var combo_queue: int = 0
var combo_grace: float = 0
var connected: bool = false
var dash_remaining: float = 0
var dash_cooldown: float = 0
var dash_direction: Vector2
var downed: bool = false
var revive_progress: float = 0
var reviving: bool = false
var damage_dealt: int = 0
var clock: float = 0
var walk_distance: float = 0
var hit_flash: float = 0
var sprite: Sprite3D
var shadow: MeshInstance3D
var foot_ring: MeshInstance3D
var shield: Node3D
var collider: CollisionShape3D
var spawn: Vector3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	arena = get_parent()
	input_prefix = "p%d_" % (player_id+1)
	display_name = "PHUZASHI CHILL" if profile == "PHUZASHI_CHILL" else "ASSJIRO"
	collision_layer = 2
	collision_mask = 7
	floor_snap_length = 0.25
	collider = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = Rules.PLAYER_RADIUS
	shape.height = 1.65
	collider.shape = shape
	collider.position.y = 0.825
	add_child(collider)
	sprite = Body.new()
	add_child(sprite)
	sprite.configure(profile)
	shadow = Visuals.ground_mark(self,0.58,Color(0.01,0.015,0.025,0.42))
	shadow.scale.z = 0.68
	foot_ring = Visuals.ring(self,0.53,0.045,Color("bc81ff") if player_id == 0 else Color("ffb65a"))
	shield = Node3D.new()
	add_child(shield)
	var bubble := SphereMesh.new()
	bubble.radius = 0.90
	bubble.height = 1.80
	bubble.radial_segments = 24
	bubble.rings = 12
	var glass := Visuals.mesh(shield,bubble,Visuals.material(Color(0.35,0.8,1,0.12),0,true))
	glass.scale = Vector3(0.80,1.1,0.30)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rim := Visuals.ring(shield,0.9,0.035,Color(0.65,0.96,1,0.75))
	rim.rotation.x = PI*0.5
	rim.scale = Vector3(0.80,1,1.1)
	reset(spawn)

func pressed(command: String) -> bool:
	return Input.is_action_pressed(input_prefix+command)

func just_pressed(command: String) -> bool:
	return Input.is_action_just_pressed(input_prefix+command)

func movement_axis() -> Vector2:
	return Vector2(Input.get_action_strength(input_prefix+"move_right")-Input.get_action_strength(input_prefix+"move_left"),Input.get_action_strength(input_prefix+"coop_back")-Input.get_action_strength(input_prefix+"coop_forward")).limit_length(1)

func reset(point: Vector3) -> void:
	global_position = point
	velocity = Vector3.ZERO
	health = Rules.HEALTH
	collision_layer = 2
	collision_mask = 7
	guard_meter = 100
	guard_age = 999
	guard_held = false
	guard_delay = 0
	guard_break = 0
	guarding = false
	invulnerability = 0
	stun = 0
	hit_pause = 0
	recoil_time = 0
	hit_flash = 0
	action = ""
	combo_family = ""
	combo_step = 0
	combo_queue = 0
	combo_grace = 0
	action_elapsed = 0
	dash_remaining = 0
	dash_cooldown = 0
	downed = false
	reviving = false
	revive_progress = 0
	damage_dealt = 0
	facing = 1
	if is_instance_valid(collider): collider.set_deferred("disabled",false)
	present()

func request_attack(family: String) -> bool:
	if family not in ["PUNCH","KICK"] or arena.state != "FIGHT" or downed or stun > 0 or guard_break > 0 or guarding or reviving or dash_remaining > 0: return false
	if not action.is_empty():
		if combo_family == family and not action.begins_with("AIR_") and combo_step+combo_queue < 3:
			combo_queue += 1
			return true
		return false
	if not is_on_floor() or velocity.y > 0.2:
		combo_step = 0
		combo_family = ""
		begin("AIR_"+family)
		return true
	combo_step = combo_step+1 if combo_family == family and combo_grace > 0 and combo_step < 3 else 1
	combo_family = family
	combo_grace = 0
	combo_queue = 0
	begin(family if combo_step == 1 else family+"_"+str(combo_step))
	return true

func begin(move: String) -> void:
	action = move
	action_elapsed = 0
	connected = false
	if arena.boss.health > 0: aim = Rules.direction(global_position,arena.boss.global_position)
	if absf(aim.x) > 0.1: facing = 1 if aim.x > 0 else -1
	velocity.x = 0
	velocity.z = 0

func progress() -> float:
	return action_elapsed/float(Rules.NORMALS[action][0]) if Rules.NORMALS.has(action) else 0

func _physics_process(delta: float) -> void:
	clock += delta
	hit_flash = maxf(0,hit_flash-delta)
	if hit_pause > 0:
		hit_pause = maxf(0,hit_pause-delta)
		present()
		return
	invulnerability = maxf(0,invulnerability-delta)
	stun = maxf(0,stun-delta)
	var previous_break: float = guard_break
	guard_break = maxf(0,guard_break-delta)
	if previous_break > 0 and guard_break <= 0: guard_meter = maxf(50,guard_meter)
	recoil_time = maxf(0,recoil_time-delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	combo_grace = maxf(0,combo_grace-delta)
	var playing: bool = arena.state == "FIGHT" and not downed
	var axis: Vector2 = movement_axis() if playing else Vector2.ZERO
	var was_guard: bool = guard_held
	guard_held = playing and pressed("guard")
	guard_age = guard_age+delta if guard_held and was_guard else (0.0 if guard_held else 999.0)
	guarding = guard_held and action.is_empty() and stun <= 0 and guard_break <= 0 and is_on_floor() and dash_remaining <= 0 and not reviving and guard_meter > 0
	if guarding or guard_break > 0: guard_delay = 1.0
	else:
		var recovery: float = maxf(0,delta-guard_delay)
		guard_delay = maxf(0,guard_delay-delta)
		guard_meter = minf(100,guard_meter+20*recovery)
	if playing and not reviving:
		if just_pressed("coop_jump") and is_on_floor() and action.is_empty() and stun <= 0 and guard_break <= 0 and not guarding:
			velocity.y = 8.7
		if just_pressed("dash") and is_on_floor() and action.is_empty() and stun <= 0 and not guarding and guard_break <= 0 and dash_cooldown <= 0:
			dash_direction = axis.normalized() if axis.length() > 0.1 else -Rules.direction(global_position,arena.boss.global_position)
			dash_remaining = 0.24
			dash_cooldown = 0.60
		if just_pressed("punch"): request_attack("PUNCH")
		elif just_pressed("kick"): request_attack("KICK")
	if action.is_empty() and playing and arena.boss.health > 0:
		aim = Rules.direction(global_position,arena.boss.global_position)
		if absf(aim.x) > 0.1: facing = 1 if aim.x > 0 else -1
	var desired: Vector2 = axis*(5.6 if pressed("run") else 3.8)
	if not action.is_empty() or guarding or stun > 0 or guard_break > 0 or downed or reviving: desired = Vector2.ZERO
	if recoil_time > 0: desired = recoil
	elif dash_remaining > 0:
		desired = dash_direction*8.5
		dash_remaining = maxf(0,dash_remaining-delta)
	velocity.x = move_toward(velocity.x,desired.x,28*delta)
	velocity.z = move_toward(velocity.z,desired.y,28*delta)
	velocity.y -= 24*delta
	var previous: Vector3 = global_position
	move_and_slide()
	position.x = clampf(position.x,-10.2,10.2)
	position.z = clampf(position.z,-6.1,6.1)
	walk_distance += Rules.flat(global_position-previous).length()
	if not action.is_empty():
		action_elapsed += delta
		var p: float = progress()
		var config: Array = Rules.NORMALS[action]
		if not connected and p >= float(config[2]) and p <= float(config[3]):
			var offset: Vector2 = Rules.flat(arena.boss.global_position-global_position)
			var strike_height: float = global_position.y+(1.0 if action.begins_with("KICK") or action == "AIR_KICK" else 1.3)
			var overlaps_height: bool = strike_height >= arena.boss.global_position.y+0.30 and strike_height <= arena.boss.global_position.y+4.9
			if arena.boss.health > 0 and overlaps_height and offset.length() <= float(config[4])+arena.boss.hurt_radius and (offset.length() < 0.01 or offset.normalized().dot(aim) > 0.35):
				var damage: int = arena.boss.take_hit(int(config[1]),int(config[5]),self)
				if damage >= 0:
					connected = true
					hit_pause = 0.04 if action.ends_with("_3") else 0.022
					arena.impact(arena.boss.global_position+Vector3(0,1.8,0),damage,player_id,action.ends_with("_3"))
		if combo_queue > 0 and p >= 0.72 and not action.begins_with("AIR_"):
			combo_queue -= 1
			combo_step += 1
			begin(combo_family+"_"+str(combo_step))
		elif p >= 1 or (action.begins_with("AIR_") and is_on_floor()):
			action = ""
			if combo_step in [1,2]: combo_grace = 0.22
			else: combo_family = ""
	present()

func receive_hit(damage: int, origin: Vector3, impulse: float, heavy: bool = false) -> int:
	if downed or invulnerability > 0 or arena.state != "FIGHT": return -1
	var toward: Vector2 = Rules.direction(global_position,origin)
	var blocked: bool = guarding and toward.dot(aim) >= -0.1
	var perfect: bool = blocked and guard_age < 0.12
	var amount: int = 0 if perfect else (2 if blocked else damage)
	if blocked and not perfect:
		guard_meter = maxf(0,guard_meter-(40 if heavy else 24))
		guard_delay = 1
		if guard_meter <= 0:
			guard_break = 1
			guarding = false
	health = maxf(0,health-amount)
	invulnerability = 0.12 if blocked else 0.55
	hit_flash = 0.16
	hit_pause = 0.035
	recoil = -toward*(1.4 if blocked else impulse)
	recoil_time = 0.08 if blocked else 0.22
	if not blocked or guard_break > 0:
		stun = 1.0 if guard_break > 0 else 0.40
		action = ""
		combo_family = ""
		combo_queue = 0
		combo_grace = 0
		dash_remaining = 0
		reviving = false
		if heavy and not blocked: velocity.y = 3.4
	arena.impact(global_position+Vector3(0,1.1,0),amount,player_id,heavy,true,perfect)
	if health <= 0:
		downed = true
		collision_layer = 0
		collision_mask = 1
		revive_progress = 0
	present()
	return amount

func revive() -> void:
	downed = false
	collision_layer = 2
	collision_mask = 7
	health = 70
	invulnerability = 1.2
	stun = 0
	guard_break = 0
	revive_progress = 0
	collider.set_deferred("disabled",false)
	present()

func present() -> void:
	if not is_instance_valid(sprite): return
	var pose: String = "IDLE"
	var phase: float = fmod(clock*0.9,1)
	if downed:
		pose = "DOWN"
		phase = 0.98
	elif stun > 0 or guard_break > 0:
		pose = "STUN"
		phase = 0.35
	elif not action.is_empty():
		pose = action
		phase = progress()
	elif reviving:
		pose = "REVIVE"
		phase = 0.8
	elif not is_on_floor():
		pose = "JUMP"
		phase = clampf((8.7-velocity.y)/17.4,0,0.99)
	elif guarding:
		pose = "GUARD"
		phase = 0.8
	elif dash_remaining > 0 or Vector2(velocity.x,velocity.z).length() > 0.3:
		pose = "RUN" if dash_remaining > 0 or pressed("run") else "WALK"
		phase = fmod(walk_distance/(2.1 if pose == "WALK" else 2.9),1)
	shield.visible = guarding and not downed
	shield.position = Rules.ground(aim)*0.45+Vector3(0,1.1,0)
	shield.rotation.y = atan2(aim.x,aim.y)
	if hit_flash > 0 and guarding: shield.position += Vector3(sin(clock*130)*0.035,0,cos(clock*110)*0.035)
	sprite.show_pose(pose,phase,facing)
	sprite.modulate = Color(1,0.45,0.40) if hit_flash > 0 else (Color(0.7,0.95,1) if invulnerability > 0.6 else Color.WHITE)
	sprite.position.x += sin(clock*100)*0.035 if hit_flash > 0 else 0
	shadow.global_position = Vector3(global_position.x,0.025,global_position.z)
	shadow.scale = Vector3(1,1,0.68)*clampf(1-position.y*0.10,0.45,1)
	foot_ring.global_position = Vector3(global_position.x,0.042,global_position.z)
