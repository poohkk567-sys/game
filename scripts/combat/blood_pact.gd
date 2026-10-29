extends Node2D
## Self sacrifice is a timed status, independent of hit stun and attack damage.
const BLEED_DURATION: float = 5.0
const BLEED_TOTAL: float = 20.0
const BUFF_DURATION: float = 10.0
@onready var fighter: Node2D = get_parent()
var buff_remaining: float = 0
var bleed_remaining: float = 0
var self_damage: float = 0
var committed: bool = false
var door: AnimatedSprite2D
var flash: float = 0
var clock: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 1
	door = AnimatedSprite2D.new()
	door.sprite_frames = load("res://assets/effects/blood_door_frames.res")
	door.centered = false
	door.z_index = -1
	door.visible = false
	add_child(door)

func begin() -> void:
	committed = false
	self_damage = 0
	flash = 0

func commit() -> void:
	if committed or fighter.fighter_profile != "BLACK_COAT" or fighter.health <= 0: return
	committed = true
	bleed_remaining = BLEED_DURATION
	buff_remaining = BUFF_DURATION
	flash = 0.45
	fighter.hit_shake = 0.18
	fighter.hit_shake_power = 4
	fighter.announce("DEMON PACT / +30% DAMAGE 10s / -20 HP OVER 5s")
	fighter.effects.play_defense_sound("GUARD BREAK")

func reset() -> void:
	buff_remaining = 0
	bleed_remaining = 0
	self_damage = 0
	committed = false
	flash = 0
	if is_instance_valid(door): door.visible = false
	queue_redraw()

func advance(delta: float) -> void:
	# Consume only the remaining bleed time; low HP never goes below one.
	if fighter.fighter_profile != "BLACK_COAT" or fighter.health <= 0:
		reset()
		return
	buff_remaining = maxf(0,buff_remaining-delta)
	if bleed_remaining > 0:
		var amount: float = minf(delta,bleed_remaining)*BLEED_TOTAL/BLEED_DURATION
		bleed_remaining = maxf(0,bleed_remaining-delta)
		var removed: float = minf(amount,maxf(0,fighter.health-1.0))
		fighter.health -= removed
		self_damage += removed
	flash = maxf(0,flash-delta)

func _physics_process(delta: float) -> void:
	clock += delta
	advance(delta)
	present()
	queue_redraw()

func present() -> void:
	if not is_instance_valid(door): return
	door.visible = fighter.fighter_profile == "BLACK_COAT" and fighter.health > 0 and fighter.action_name == "BLOOD_PACT" and fighter.action_timer > 0
	if not door.visible: return
	var factor: float = 220.0/float(door.sprite_frames.get_meta("source_height"))
	door.scale = Vector2(factor*fighter.facing,factor)
	door.position = Vector2(-fighter.facing*112,0)-Vector2(512*fighter.facing,960)*factor
	door.animation = "DOOR"
	door.frame = mini(15,floori(fighter.action_progress()*16))

func _draw() -> void:
	if fighter.fighter_profile != "BLACK_COAT" or fighter.health <= 0: return
	if flash > 0:
		var fade: float = flash/0.45
		draw_line(Vector2(-48*fighter.facing,-145),Vector2(48*fighter.facing,-58),Color(1,0.12,0.25,fade),5)
		for i in range(12):
			var q: float = 1-fade
			var p := Vector2((i%4-1.5)*13*fighter.facing+sin(i*2.4)*q*65,-97+cos(i*2.1)*q*55+q*q*38)
			draw_rect(Rect2(p,Vector2(3,5)),Color(0.88,0.025,0.10,fade))
	if bleed_remaining > 0:
		for i in range(4):
			var q: float = fmod(clock*1.8+i*0.25,1)
			draw_rect(Rect2(Vector2((i-1.5)*9,-95+q*88),Vector2(2,4)),Color(0.8,0.02,0.07,(1-q)*0.8))
	if buff_remaining > 0:
		draw_string(ThemeDB.fallback_font,Vector2(-59,-178),"PACT +30%% / %.1fs" % buff_remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ff718a"))
