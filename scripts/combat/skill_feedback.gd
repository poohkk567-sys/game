extends Camera2D
## World-only camera shake and short synthesized impact sounds; HUD stays still.
var shake_time: float = 0
var strength: float = 0
var clock: float = 0
var player: AudioStreamPlayer
var sounds: Dictionary = {}

static func obtain(stage: Node) -> Node:
	var current: Node = stage.get_node_or_null("SkillFeedback")
	if current != null: return current
	var node: Camera2D = load("res://scripts/combat/skill_feedback.gd").new()
	node.name = "SkillFeedback"
	node.position = Vector2(640,360)
	stage.add_child(node)
	return node

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -17
	add_child(player)

func impact(power: float, kind: String = "HIT") -> void:
	shake_time = maxf(shake_time,0.13)
	strength = maxf(strength,power)
	if not sounds.has(kind):
		var sound := AudioStreamWAV.new()
		sound.format = AudioStreamWAV.FORMAT_16_BITS
		sound.mix_rate = 22050
		var duration: float = 0.42 if kind == "ROAR" else 0.18
		var data := PackedByteArray()
		data.resize(int(duration*22050)*2)
		for i in range(data.size()/2):
			var t: float = float(i)/22050
			var envelope: float = pow(1-t/duration,2)*minf(1,t/0.005)
			var noise: float = sin(i*12.9898)*sin(i*78.233)
			var tone: float = sin(TAU*(85-45*t/duration)*t)
			if kind == "ROAR": tone = sin(TAU*65*t)*(0.6+0.4*sin(t*85))
			data.encode_s16(i*2,int(clampf((tone*0.65+noise*0.3)*envelope,-1,1)*24000))
		sound.data = data
		sounds[kind] = sound
	player.stream = sounds[kind]
	player.play()

func _physics_process(delta: float) -> void:
	clock += delta
	shake_time = maxf(0,shake_time-delta)
	offset = Vector2(sin(clock*173),cos(clock*139))*strength*shake_time/0.13
	if shake_time <= 0: strength = 0
