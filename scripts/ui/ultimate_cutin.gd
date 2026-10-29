extends CanvasLayer
## A short left-side portrait card. Concurrent casts queue; gameplay never pauses.
const PORTRAITS: Texture2D = preload("res://assets/ui/ultimate_portraits.png")
const CHILL_PORTRAIT: Texture2D = preload("res://assets/ui/phuzashi_chill_portrait.png")
const BLACK_PORTRAIT: Texture2D = preload("res://assets/ui/black_coat_portrait.png")
const Book = preload("res://scripts/combat/skill_book.gd")
var cards: Array[Dictionary] = []
var current: Dictionary = {}
var history: Array[String] = []
var age: float = 0
var panel: Control
const DURATION: float = 0.72

static func play_for(fighter: Node2D) -> void:
	var service: Node = fighter.get_parent().get_node_or_null("UltimateCutins")
	if service == null:
		service = load("res://scripts/ui/ultimate_cutin.gd").new()
		service.name = "UltimateCutins"
		fighter.get_parent().add_child(service)
	service.enqueue(fighter.fighter_profile,fighter.display_name,fighter.input_prefix)

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("ultimate_cutins")
	panel = Control.new()
	panel.size = Vector2(360,210)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	add_child(panel)
	panel.draw.connect(_draw_card)

func enqueue(profile: String, label: String, player: String) -> void:
	cards.append({"profile":profile,"label":label,"player":"P2" if player == "p2_" else "P1"})
	if current.is_empty(): _next()

func _next() -> void:
	current = cards.pop_front() if not cards.is_empty() else {}
	age = 0
	panel.visible = not current.is_empty()
	if panel.visible: history.append(current.profile)

func clear() -> void:
	cards.clear()
	current.clear()
	if is_instance_valid(panel): panel.visible = false

func _process(delta: float) -> void:
	if current.is_empty(): return
	age += delta
	if age >= DURATION:
		_next()
		return
	var enter: float = smoothstep(0,0.11,age)
	var leave: float = smoothstep(0.58,DURATION,age)
	panel.position = Vector2(-370+394*enter-394*leave,204)
	panel.modulate.a = 1-leave
	panel.queue_redraw()

func _draw_card() -> void:
	if current.is_empty(): return
	var profile: String = current.profile
	var color: Color = {"PHUZASHI":Color("b544ff"),"RED_CAP":Color("ffac38"),"MUAY_THAI":Color("ff4fa9"),"BLACK_COAT":Color("ff3559"),"PHUZASHI_CHILL":Color("b544ff")}[profile]
	panel.draw_rect(Rect2(0,0,360,210),Color("090b16"))
	for i in range(9):
		var x: float = fmod(age*330+i*70,520)-160
		panel.draw_colored_polygon(PackedVector2Array([Vector2(x,0),Vector2(x+34,0),Vector2(x-90,210),Vector2(x-124,210)]),Color(color,0.15))
	var size: Vector2 = PORTRAITS.get_size()
	var region: Rect2
	match profile:
		"PHUZASHI": region = Rect2(0,0,size.x*0.306,size.y)
		"RED_CAP": region = Rect2(size.x*0.309,0,size.x*0.335,size.y)
		_: region = Rect2(size.x*0.644,0,size.x*0.356,size.y)
	if profile == "PHUZASHI_CHILL":
		panel.draw_texture_rect(CHILL_PORTRAIT,Rect2(65,-12,285,285),false)
	elif profile == "BLACK_COAT":
		panel.draw_texture_rect(BLACK_PORTRAIT,Rect2(65,-12,285,285),false)
	else:
		panel.draw_texture_rect_region(PORTRAITS,Rect2(88,-4,245,267),region)
	panel.draw_rect(Rect2(0,153,360,57),Color(0.02,0.025,0.05,0.88))
	panel.draw_rect(Rect2(1,1,358,208),color,false,3)
	panel.draw_line(Vector2(2,3),Vector2(358,3),Color("f6eaff"),2)
	panel.draw_line(Vector2(2,207),Vector2(358*(1-age/DURATION),207),color.lightened(0.6),3)
	panel.draw_string(ThemeDB.fallback_font,Vector2(14,23),current.player+"  /  ULTIMATE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,color.lightened(0.6))
	panel.draw_string(ThemeDB.fallback_font,Vector2(14,177),current.label,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("fff6ff"))
	var action: String = Book.ROSTER[profile][5]
	panel.draw_string(ThemeDB.fallback_font,Vector2(15,197),Book.NAMES[action],HORIZONTAL_ALIGNMENT_LEFT,-1,11,color.lightened(0.6))
