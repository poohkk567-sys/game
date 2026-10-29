extends SceneTree
## Preserve source art. Fit cell edges in empty gutters and align the core per frame.
const ROOT := "res://assets/effects/side_guardians/"
const SHEETS := {"PURPLE":"shadow_shinobi","RED":"crimson_grin","GOLD":"golden_lotus"}
func _initialize() -> void: call_deferred("build")
func build() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var heights: Dictionary = {}
	var cores: Dictionary = {}
	for kind: String in SHEETS:
		var texture: Texture2D = load(ROOT+SHEETS[kind]+".png")
		var picture: Image = texture.get_image()
		var size: Vector2i = picture.get_size()
		frames.add_animation(kind)
		frames.set_animation_loop(kind,true)
		frames.set_animation_speed(kind,8)
		var middle: int = gutter(picture,true,size.y/2,Rect2i(Vector2i.ZERO,size),int(size.y*0.035))
		var core_points: Array[Vector2] = []
		var reference_offset := Vector2.ZERO
		var height: float = 0
		for row in range(2):
			var top: int = 0 if row == 0 else middle
			var bottom: int = middle if row == 0 else size.y
			var row_rect := Rect2i(0,top,size.x,bottom-top)
			var cuts: Array[int] = [0]
			for column in range(1,4): cuts.append(gutter(picture,false,roundi(column*size.x/4.0),row_rect,int(size.x*0.025)))
			cuts.append(size.x)
			for column in range(4):
				var cell := Rect2i(cuts[column],top,cuts[column+1]-cuts[column],bottom-top)
				var low := cell.end
				var high := cell.position
				for y in range(cell.position.y,cell.end.y):
					for x in range(cell.position.x,cell.end.x):
						if picture.get_pixel(x,y).a > 0.15:
							low = Vector2i(mini(low.x,x),mini(low.y,y))
							high = Vector2i(maxi(high.x,x+1),maxi(high.y,y+1))
				assert(high.y > low.y,"Empty guardian frame: "+kind)
				height = maxf(height,high.y-low.y)
				var core: Vector2 = find_core(picture,cell,kind)
				if row == 0 and column == 0:
					reference_offset = Vector2(cell.position)+Vector2(cell.size.x*0.65,cell.size.y)-core
				var anchor: Vector2 = core+reference_offset
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(cell)
				atlas.margin = Rect2(Vector2(512,960)-(anchor-Vector2(cell.position)),Vector2(1024,1024)-Vector2(cell.size))
				atlas.filter_clip = true
				atlas.set_meta("core",core-Vector2(cell.position))
				frames.add_frame(kind,atlas)
				core_points.append(core-Vector2(cell.position))
		heights[kind] = height
		cores[kind] = core_points
		print("IMPORTED ",kind," 8 side-facing frames, stable head/chest core, height=",height)
	frames.set_meta("heights",heights)
	frames.set_meta("cores",cores)
	frames.set_meta("pivot",Vector2(512,960))
	assert(ResourceSaver.save(frames,"res://assets/effects/side_guardians_frames.res",ResourceSaver.FLAG_COMPRESS) == OK)
	quit()

func gutter(picture: Image, horizontal: bool, expected: int, bounds: Rect2i, radius: int) -> int:
	var best: int = expected
	var score: float = INF
	for line in range(expected-radius,expected+radius+1):
		var value: float = 0
		for other in range(bounds.position.x if horizontal else bounds.position.y,bounds.end.x if horizontal else bounds.end.y):
			var color: Color = picture.get_pixel(other,line) if horizontal else picture.get_pixel(line,other)
			value += color.a*color.a
		value += absf(line-expected)*0.025
		if value < score:
			score = value
			best = line
	return best

func find_core(picture: Image, cell: Rect2i, kind: String) -> Vector2:
	var roi: Rect2 = Rect2(0.68,0.22,0.23,0.18) if kind == "PURPLE" else (Rect2(0.68,0.19,0.24,0.21) if kind == "RED" else Rect2(0.51,0.44,0.19,0.24))
	var start: Vector2i = cell.position+Vector2i((Vector2(cell.size)*roi.position).floor())
	var end: Vector2i = cell.position+Vector2i((Vector2(cell.size)*roi.end).ceil())
	var sum := Vector2.ZERO
	var weights: float = 0
	for y in range(start.y,end.y):
		for x in range(start.x,end.x):
			var color: Color = picture.get_pixel(x,y)
			var light: float = minf(color.r,minf(color.g,color.b))
			var threshold: float = 0.35 if kind == "GOLD" else 0.55
			var weight: float = pow(maxf(0,light-threshold),2)*color.a
			sum += Vector2(x,y)*weight
			weights += weight
	assert(weights > 0,"Missing identity highlight: "+kind)
	return sum/weights
