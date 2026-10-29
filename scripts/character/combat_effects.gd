extends Node2D
## Full 16-frame sprite VFX, drawn separately from the approved fighter artwork.
const Shuriken = preload("res://scripts/effects/purple_shuriken_art.gd")
const CARROT_HEAD: Texture2D = preload("res://assets/effects/carrot_headbutt_vfx.png")
const CARROT_BARRAGE: Texture2D = preload("res://assets/effects/carrot_barrage_vfx.png")
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
		var length: float = 0.16 if kind == "PERFECT GUARD" else (0.09 if kind == "GUARD" else 0.25)
		var data := PackedByteArray()
		data.resize(int(length*22050)*2)
		for i in range(data.size()/2):
			var t: float = float(i)/22050.0
			var pitch: float = (1250.0 if kind == "PERFECT GUARD" else (350.0 if kind == "GUARD" else 280.0))*(1.0-0.5*t/length)
			var noise: float = sin(i*12.9898)*sin(i*78.233)
			var sample: float = (sin(TAU*pitch*t)*0.6+noise*(0.15 if kind == "PERFECT GUARD" else (0.3 if kind == "GUARD" else 0.65)))*pow(1.0-t/length,2)
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
	if fighter.can_guard():
		var recoil: float = fighter.guard_impact/0.24
		var shield_height: float = fighter.low_height() if fighter.state_name == "CROUCH" else fighter.standing_height()
		var center := Vector2(d*42+sin(t*85)*recoil*3,-shield_height*0.59)
		var outline := PackedVector2Array()
		for i in range(33):
			var angle: float = i*TAU/32.0
			outline.append(center+Vector2(cos(angle)*28,sin(angle)*shield_height*0.54))
		draw_colored_polygon(outline,Color(0.55,0.87,1,0.10+recoil*0.18))
		draw_polyline(outline,Color(0.65,0.94,1,0.5+recoil*0.45),2+recoil*2,false)
		draw_arc(center,23,-1.2,1.2,20,Color(0.9,1,1,0.25+recoil*0.6),2,false)
		if recoil > 0:
			for i in range(6):
				var ray := Vector2.from_angle(i*TAU/6.0)
				draw_line(center+ray*12,center+ray*(24+(1-recoil)*24),Color(0.8,0.96,1,recoil),3,false)
	if fighter.dash_timer > 0:
		for i in range(5):
			draw_line(Vector2(-d*(30+i*14),-25-i*23),Vector2(-d*(80+i*18),-25-i*23),Color(1,0.72,0.36,0.45),2,false)
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
			_fino_trail(p,t)
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
		Shuriken.draw(self,Vector2(fighter.facing*hand.x,hand.y),t*24,lerpf(0.25,0.8,q),smoothstep(0,0.2,q))
		draw_set_transform(Vector2.ZERO,0,Vector2(fighter.facing,1))
		for i in range(3):
			draw_arc(hand, 25 + i * 10 + q * 10, -t * (3 + i), -t * (3 + i) + PI * 1.4, 26, Color(0.7, 0.18, 1, (0.3 + q * 0.4) / (i + 1)), 3, false)
	elif p < 0.63:
		var q: float = (p - 0.42) / 0.21
		draw_arc(hand,36+q*35,-t*24,-t*24+PI*1.5,28,Color(0.8,0.4,1,(1-q)*0.8),3,false)
	else:
		var fade: float = maxf(0.0, (1.0 - p) / 0.37)
		for i in range(10):
			var pos := hand + Vector2(12 + i * 7, sin(t * 17 + i * 2.0) * (8 + i))
			draw_rect(Rect2(pos, Vector2(3 + i % 2, 4)), Color(0.72, 0.2, 1, fade * 0.65))

func _fino_trail(p: float, t: float) -> void:
	if p < 0.32 or p > 0.83:
		return
	for i in range(12):
		var x: float = -80-i*12
		var y: float = -18+sin(t*22+i*1.8)*8
		draw_rect(Rect2(Vector2(x,y),Vector2(9,3)),Color(0.72,0.32,1,(12-i)/20.0))
