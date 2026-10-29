extends SceneTree
## Import intact connected bodies into virtual canvases. Save using Godot 4.2.2.
const ROOT := "res://assets/characters/phuzashi_chill/"
const PAIRS := {"idle_walk":["IDLE","WALK"],"run_jump":["RUN","JUMP"],"crouch_guard":["CROUCH","GUARD"],"punch_kick":["PUNCH","KICK"],"punch_combo":["PUNCH_2","PUNCH_3"],"kick_combo":["KICK_2","KICK_3"],"hit_fall":["HIT","FALL"],"powers":["SPECIAL","ULTIMATE"]}
func _initialize() -> void: call_deferred("build")
func build() -> void:
	var bank := SpriteFrames.new()
	bank.remove_animation("default")
	var scales: Dictionary = {}
	for sheet: String in PAIRS:
		var source: Texture2D = load(ROOT+sheet+".png")
		var picture: Image = source.get_image()
		var bodies: Array = whole_figures(picture,8)
		if bodies.size() != 16:
			push_error("Need16complete bodies: "+sheet+" got"+str(bodies.size()))
			quit(1)
			return
		for half in range(2):
			var clip: String = PAIRS[sheet][half]
			bank.add_animation(clip)
			bank.set_animation_loop(clip,clip in ["IDLE","WALK","RUN"])
			bank.set_animation_speed(clip,8 if clip == "IDLE" else 12)
			var standing: Rect2i = bodies[0 if clip in ["JUMP","FALL"] else half*8]
			scales[clip] = 286.0/standing.size.y
			for i in range(8):
				var box: Rect2i = bodies[half*8+i]
				var anchor: float = box.get_center().x
				if clip not in ["WALK","RUN","JUMP","FALL"]:
					var low: int = 100000
					var high: int = 0
					for y in range(box.end.y-int(box.size.y*0.12),box.end.y):
						for x in range(box.position.x,box.end.x):
							if picture.get_pixel(x,y).a > 0.5:
								low = mini(low,x)
								high = maxi(high,x)
					anchor = (low+high)*0.5
				bank.add_frame(clip,atlas(source,box,anchor,box.end.y))
	bank.set_meta("pivot",Vector2(512,960))
	bank.set_meta("scales",scales)
	assert(ResourceSaver.save(bank,ROOT+"chill_frames.res",ResourceSaver.FLAG_COMPRESS) == OK)
	build_fino()
	print("CHILL ART: 128 complete fighter poses +16 Fino duo frames")
	quit()

func build_fino() -> void:
	var source: Texture2D = load(ROOT+"fino_ultimate.png")
	var picture: Image = source.get_image()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("FINO")
	frames.set_animation_loop("FINO",false)
	var source_height: float = 0
	for i in range(16):
		var lo := Vector2i(roundi((i%4)*picture.get_width()/4.0),roundi((i/4)*picture.get_height()/4.0))
		var hi := Vector2i(roundi((i%4+1)*picture.get_width()/4.0),roundi((i/4+1)*picture.get_height()/4.0))
		var cell := Rect2i(lo,hi-lo)
		var low := Vector2i(100000,100000)
		var high := Vector2i.ZERO
		for y in range(cell.position.y,cell.end.y):
			for x in range(cell.position.x,cell.end.x):
				if picture.get_pixel(x,y).a > 0.5:
					low = Vector2i(mini(low.x,x),mini(low.y,y))
					high = Vector2i(maxi(high.x,x+1),maxi(high.y,y+1))
		var region := Rect2i(low,high-low)
		var tire_left: int = 100000
		var tire_right: int = 0
		var tire_floor: int = 0
		for y in range(region.position.y+int(region.size.y*0.70),region.end.y):
			for x in range(region.position.x,region.end.x):
				var c: Color = picture.get_pixel(x,y)
				if c.a > 0.5 and c.r < 0.45 and absf(c.r-c.g) < 0.10 and absf(c.b-c.g) < 0.10:
					tire_left = mini(tire_left,x)
					tire_right = maxi(tire_right,x)
					tire_floor = maxi(tire_floor,y+1)
		var anchor: float = (tire_left+tire_right)*0.5 if tire_right > tire_left else cell.get_center().x
		var baseline: float = tire_floor if tire_floor > 0 else region.end.y
		if i == 0: source_height = region.size.y
		frames.add_frame("FINO",atlas(source,region,anchor,baseline))
	frames.set_meta("source_height",source_height)
	frames.set_meta("heights",{"FINO":source_height})
	assert(ResourceSaver.save(frames,ROOT+"fino_ultimate_frames.res",ResourceSaver.FLAG_COMPRESS) == OK)

func atlas(source: Texture2D,box: Rect2i,anchor: float,baseline: float) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = source
	result.region = Rect2(box)
	result.margin = Rect2(Vector2(512-(anchor-box.position.x),960-(baseline-box.position.y)),Vector2(1024-box.size.x,1024-box.size.y))
	result.filter_clip = true
	return result

func whole_figures(picture: Image, columns: int) -> Array:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(picture,0.5)
	var parts: Array = []
	for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,picture.get_size()),0.15):
		var lo := Vector2(INF,INF)
		var hi := Vector2(-INF,-INF)
		var area: float = 0
		for i in range(polygon.size()):
			lo = Vector2(minf(lo.x,polygon[i].x),minf(lo.y,polygon[i].y))
			hi = Vector2(maxf(hi.x,polygon[i].x),maxf(hi.y,polygon[i].y))
			area += polygon[i].cross(polygon[(i+1)%polygon.size()])
		if absf(area)*0.5 > 1800: parts.append({"region":Rect2i(Vector2i(lo.floor()),Vector2i(hi.ceil()-lo.floor())),"area":absf(area)*0.5})
	parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.area > b.area)
	parts = parts.slice(0,16)
	if parts.size() != 16: return []
	parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().y < b.region.get_center().y if columns == 8 else a.region.end.y < b.region.end.y)
	var result: Array = []
	for row in range(16/columns):
		var group: Array = parts.slice(row*columns,row*columns+columns)
		group.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().x < b.region.get_center().x)
		for part: Dictionary in group: result.append(part.region)
	return result
