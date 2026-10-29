extends Node2D
## Full 16-frame sprite VFX, drawn separately from the approved fighter artwork.
const PULSE: Texture2D = preload("res://assets/effects/dark_pulse_vfx.png")
const CARROT_HEAD: Texture2D = preload("res://assets/effects/carrot_headbutt_vfx.png")
const CARROT_BARRAGE: Texture2D = preload("res://assets/effects/carrot_barrage_vfx.png")
const DRAGON: Texture2D = preload("res://assets/effects/violet_dragon_vfx.png")
var defense_player: AudioStreamPlayer
var defense_sounds: Dictionary = {}
@onready var fighter: PhuzashiCharacter = get_parent()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	defense_player = AudioStreamPlayer.new()
	defense_player.volume_db = -15.0
	add_child(defense_player)

func play_defense_sound(kind: String) -> void:
	if not defense_sounds.has(kind):
		var sound := AudioStreamWAV.new()
		sound.format = AudioStreamWAV.FORMAT_16_BITS
		sound.mix_rate = 22050
		var length: float = 0.16 if kind == "PERFECT GUARD" else 0.25
		var data := PackedByteArray()
		data.resize(int(length*22050)*2)
		for i in range(data.size()/2):
			var t: float = float(i)/22050.0
			var pitch: float = (1250.0 if kind == "PERFECT GUARD" else 280.0)*(1.0-0.5*t/length)
			var noise: float = sin(i*12.9898)*sin(i*78.233)
			var sample: float = (sin(TAU*pitch*t)*0.6+noise*(0.15 if kind == "PERFECT GUARD" else 0.65))*pow(1.0-t/length,2)
			data.encode_s16(i*2,int(clampf(sample,-1,1)*26000))
		sound.data = data
		defense_sounds[kind] = sound
	defense_player.stream = defense_sounds[kind]
	defense_player.play()

func _cell(sheet: Texture2D, index: int, center: Vector2, dimensions: Vector2, opacity: float = 1.0) -> void:
	var col: int = index % 4
	var row: int = floori(float(index) / 4.0)
	var size: Vector2 = sheet.get_size()
	var upper := Vector2(floorf(float(col) * size.x / 4.0), floorf(float(row) * size.y / 4.0))
	var lower := Vector2(floorf(float(col + 1) * size.x / 4.0), floorf(float(row + 1) * size.y / 4.0))
	var region := Rect2(upper, lower - upper)
	draw_texture_rect_region(sheet, Rect2(center - dimensions * 0.5, dimensions), region, Color(1, 1, 1, clampf(opacity, 0.0, 1.0)), false, true)

func _draw() -> void:
	if not is_instance_valid(fighter):
		return
	var d: float = float(fighter.facing)
	var t: float = fighter.elapsed
	if fighter.charging:
		var accent: Color = Color("c394ff") if fighter.specials_enabled else Color("ffd77c")
		for i in range(12):
			var y: float = -fmod(t*95+i*17,180.0)
			var x: float = sin(i*12.3)*48+sin(t*4+i)*6
			draw_rect(Rect2(Vector2(x,y),Vector2(3,7)),Color(accent,0.55))
		draw_set_transform(Vector2(0,-2),0,Vector2(1,0.25))
		draw_arc(Vector2.ZERO,52+sin(t*9)*4,0,TAU,36,Color(accent,0.8),3,false)
		draw_set_transform(Vector2.ZERO)
	if fighter.defense_feedback_time > 0:
		var perfect: bool = fighter.defense_feedback == "PERFECT GUARD"
		var remaining: float = fighter.defense_feedback_time/(0.45 if perfect else 1.0)
		var center := Vector2(d*22,-90)
		for i in range(12):
			var ray := Vector2.from_angle(i*TAU/12.0)
			var distance: float = 22+(1.0-remaining)*75
			draw_line(center+ray*distance,center+ray*(distance+15),Color(Color("a5ffff") if perfect else Color("ff9b74"),remaining),3,false)
		if perfect:
			draw_arc(center,66+(1.0-remaining)*25,0,TAU,32,Color(0.7,1,1,remaining),4,false)
	if fighter.state_name == "GUARD":
		draw_arc(Vector2(d * 20, -87), 66, -1.3 if d > 0 else PI - 1.3, 1.3 if d > 0 else PI + 1.3, 24, Color(0.66, 0.45, 1, 0.7), 3, false)
	if fighter.blink_timer > 0.0:
		return
	if fighter.action_timer <= 0.0:
		return
	var p: float = clampf(fighter.action_progress(), 0.0, 1.0)
	var envelope: float = sin(p * PI)
	match fighter.action_name:
		"CARROT_HEADBUTT":
			var index: int = mini(3,floori(p/0.18*4)) if p < 0.18 else (4+mini(7,floori((p-0.18)/0.49*8)) if p < 0.67 else 12+mini(3,floori((p-0.67)/0.33*4)))
			draw_set_transform(Vector2.ZERO,0,Vector2(d,1))
			_cell(CARROT_HEAD,index,Vector2(-12,-85),Vector2(260,220),0.88)
			draw_set_transform(Vector2.ZERO)
		"CARROT_RUSH":
			var index: int = mini(3,floori(p/0.20*4)) if p < 0.20 else (4+mini(7,floori((p-0.20)/0.51*8)) if p < 0.71 else 12+mini(3,floori((p-0.71)/0.29*4)))
			draw_set_transform(Vector2.ZERO,0,Vector2(d,1))
			_cell(CARROT_BARRAGE,index,Vector2(85,-88),Vector2(270,230),0.88)
			draw_set_transform(Vector2.ZERO)
		"TRANSFORM":
			# A short golden completion accent; the bottle and clothes are drawn frames.
			if p > 0.86:
				var glow: float = sin((p-0.86)/0.14*PI)
				draw_arc(Vector2(0,-75),80,0,TAU,36,Color(1,0.82,0.30,glow*0.65),3,false)
		"PUNCH_3":
			if not fighter.specials_enabled and p > 0.20 and p < 0.70:
				draw_arc(Vector2(d*35,-98),57,-0.4 if d > 0 else PI-2.0,1.5 if d > 0 else PI-0.1,20,Color(1,0.94,0.78,envelope*0.85),5,false)
		"PUNCH", "PUNCH_2", "AIR_PUNCH":
			var strike_y: float = -80.0 if fighter.is_air_attack() else -104.0
			if p > 0.20 and p < 0.7:
				for i in range(3):
					draw_line(Vector2(d * 45, strike_y + i * 9), Vector2(d * (95 + envelope * 30), strike_y + i * 9), Color(1, 0.91, 0.7, envelope * 0.8), 3 + maxi(0,fighter.combo_step-1), false)
			if fighter.combo_step == 3 and fighter.attack_phase() == "ACTIVE":
				_finisher(Vector2(d * 104, -88), p)
		"KICK", "KICK_2", "KICK_3", "AIR_KICK":
			if p > 0.3 and p < 0.75:
				var start: float = -1.4 if d > 0 else PI - 1.0
				draw_arc(Vector2(d * 25, -65), 92 + fighter.combo_step * 3, start, start + 1.9, 25, Color(0.75, 0.92, 1, envelope * 0.9), 5 + maxi(0,fighter.combo_step-1), false)
			if fighter.combo_step == 3 and fighter.attack_phase() == "ACTIVE":
				_finisher(Vector2(d * 135, -70), p)
		"HIT":
			var center := Vector2(d * 24, -99)
			for i in range(8):
				var ray := Vector2.from_angle(float(i) * TAU / 8.0)
				draw_line(center + ray * (8 + p * 20), center + ray * (18 + p * 40), Color(1, 0.65, 0.55, 1 - p), 3, false)
		"SPECIAL":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(d, 1))
			_special(p, t)
			draw_set_transform(Vector2.ZERO)
		"ULTIMATE":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(d, 1))
			_ultimate(p, t)
			draw_set_transform(Vector2.ZERO)

func _finisher(center: Vector2, progress: float) -> void:
	var accent: Color = Color(0.78,0.43,1,0.8) if fighter.specials_enabled else Color(1,0.92,0.75,0.8)
	for i in range(8):
		var ray := Vector2.from_angle(float(i) * TAU / 8.0 + progress * 3.0)
		draw_line(center + ray * 10, center + ray * (24 + progress * 20), accent, 4, false)
		draw_line(center + ray * 11, center + ray * (20 + progress * 18), Color(0.96, 0.84, 1, 0.95), 1.5, false)

func _special(p: float, t: float) -> void:
	var hand := Vector2(49, -88)
	if p < 0.42:
		var q: float = p / 0.42
		_cell(PULSE, mini(3, floori(q * 4)), hand, Vector2(132, 132))
		for i in range(3):
			draw_arc(hand, 25 + i * 10 + q * 10, -t * (3 + i), -t * (3 + i) + PI * 1.4, 26, Color(0.7, 0.18, 1, (0.3 + q * 0.4) / (i + 1)), 3, false)
	elif p < 0.63:
		var q: float = (p - 0.42) / 0.21
		_cell(PULSE, 4 + mini(3, floori(q * 4)), hand + Vector2(q * 30, 0), Vector2(172, 144), 1.0 - q * 0.2)
	else:
		var fade: float = maxf(0.0, (1.0 - p) / 0.37)
		for i in range(10):
			var pos := hand + Vector2(12 + i * 7, sin(t * 17 + i * 2.0) * (8 + i))
			draw_rect(Rect2(pos, Vector2(3 + i % 2, 4)), Color(0.72, 0.2, 1, fade * 0.65))

func _ultimate(p: float, t: float) -> void:
	var power: float = sin(p * PI)
	# Ground rune and ascending sparks keep the character grounded while charging.
	draw_set_transform(Vector2(0, -2), 0, Vector2(1, 0.28))
	for i in range(3):
		draw_arc(Vector2.ZERO, 72 + i * 17 + power * 18, t * (i + 1), t * (i + 1) + PI * 1.7, 48, Color(0.65, 0.15, 1, power * 0.65), 4, false)
	draw_set_transform(Vector2.ZERO)
	for i in range(22):
		var x: float = sin(i * 8.1) * 72
		var y: float = -fmod(t * 145 + i * 19, 220)
		draw_rect(Rect2(Vector2(x, y), Vector2(3 + i % 3, 7 + i % 6)), Color(0.68, 0.14, 1, power * 0.7))
	if p < 0.35:
		var q: float = p / 0.35
		_cell(DRAGON, mini(3, floori(q * 4)), Vector2(5, -92), Vector2(220, 230))
	elif p < 0.49:
		var q: float = (p - 0.35) / 0.14
		_cell(DRAGON, 4 + mini(3, floori(q * 4)), Vector2(105, -145), Vector2(340, 280))
	elif p < 0.80:
		var q: float = (p - 0.49) / 0.31
		_cell(DRAGON, 8 + mini(3, floori(q * 4)), Vector2(245 + q * 65, -153), Vector2(590, 340))
		var trail := PackedVector2Array()
		for i in range(32):
			var u: float = float(i) / 31.0
			trail.append(Vector2(58 + u * (100 + q * 470), -106 - sin(u * TAU * 1.2 - t * 7) * (15 + u * 30)))
		draw_polyline(trail, Color(0.56, 0.11, 1, 0.32), 28, false)
		draw_polyline(trail, Color(0.92, 0.69, 1, 0.42), 8, false)
	else:
		var q: float = (p - 0.80) / 0.20
		_cell(DRAGON, 12 + mini(3, floori(q * 4)), Vector2(395, -155), Vector2(620, 345), 1.0 - q * 0.25)
