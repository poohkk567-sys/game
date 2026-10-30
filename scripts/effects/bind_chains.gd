extends Node2D
## Foreground links wrap the victim; the standing ninja never has to overlap them.
const TORSO_OFFSET: float = 24
@onready var bind: Node2D = get_parent()

func _physics_process(_delta: float) -> void:
	visible = bind.caught and bind.phase in ["HOLD","RELEASE"]
	queue_redraw()

static func path(canvas: CanvasItem, points: PackedVector2Array, alpha: float) -> void:
	if points.size() < 2: return
	canvas.draw_polyline(points,Color(0.15,0.04,0.24,alpha),5,false)
	for i in range(points.size()-1):
		var center: Vector2 = points[i].lerp(points[i+1],0.5)
		var angle: float = (points[i+1]-points[i]).angle()
		var ring := PackedVector2Array()
		for j in range(9):
			var theta: float = j*TAU/8
			ring.append(center+Vector2(cos(theta)*4.3,sin(theta)*(2.0 if i%2 else 3.1)).rotated(angle))
		canvas.draw_polyline(ring,Color(0.17,0.04,0.29,alpha),4,false)
		canvas.draw_polyline(ring,Color(0.78,0.39,1,alpha),2,false)
		canvas.draw_line(ring[1],ring[2],Color(0.98,0.85,1,alpha),1,false)

func _draw() -> void:
	if not bind.caught or bind.phase not in ["HOLD","RELEASE"]: return
	var fade: float = 1-smoothstep(0,bind.RELEASE_TIME,bind.phase_age) if bind.phase == "RELEASE" else smoothstep(0,0.08,bind.phase_age)
	var alpha: float = fade*(0.88+sin(bind.age*22)*0.1)
	# Front halves of three loops: chest, waist and hips remain readable inside.
	for row in range(3):
		var points := PackedVector2Array()
		for step in range(16):
			var theta: float = step*PI/15
			points.append(Vector2(cos(theta)*34,TORSO_OFFSET-23+row*28+sin(theta)*10))
		path(self,points,alpha)
	# A crossed restraint joins the chest and waist loops, below the face.
	for side in [-1,1]:
		var points := PackedVector2Array()
		for step in range(13): points.append(Vector2(side*28*(1-step/6.0),TORSO_OFFSET-27+step*5))
		path(self,points,alpha)
	var hand: Vector2 = bind.grip_position+Vector2(bind.direction*22,-58)
	var tether := PackedVector2Array()
	for step in range(15):
		var q: float = step/14.0
		tether.append(hand.lerp(Vector2(-bind.direction*32,TORSO_OFFSET+5),q)+Vector2(0,sin(q*PI)*5))
	path(self,tether,alpha)
