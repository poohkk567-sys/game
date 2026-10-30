extends SceneTree
## Whole sprites anchored to tires/feet; never cut a character into movable limbs.
func _initialize() -> void: call_deferred("build")
func build() -> void:
	for spec: Array in [["characters/phuzashi_clear/fino_ultimate","FINO"],["characters/muay_thai/motion_smooth","MUAY"],["effects/carrot_cyclone","CYCLONE"]]:
		var path: String = "res://assets/"+spec[0]+".png"
		var source: Texture2D = load(path)
		var picture: Image = source.get_image()
		var muay_regions: Array = whole_figures(picture) if spec[1] == "MUAY" else []
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for clip: String in (["IDLE","DASH"] if spec[1] == "MUAY" else [spec[1]]):
			frames.add_animation(clip)
			frames.set_animation_loop(clip,clip == "IDLE")
			frames.set_animation_speed(clip,8 if clip == "IDLE" else 16)
		var heights: Array[float] = []
		for index in range(16):
			var col: int = index%4
			var row: int = index/4
			var left := Vector2i(roundi(col*picture.get_width()/4.0),roundi(row*picture.get_height()/4.0))
			var right := Vector2i(roundi((col+1)*picture.get_width()/4.0),roundi((row+1)*picture.get_height()/4.0))
			var cell := Rect2i(left,right-left)
			var low := Vector2i(100000,100000)
			var high := Vector2i.ZERO
			for y in range(cell.position.y,cell.end.y):
				for x in range(cell.position.x,cell.end.x):
					if picture.get_pixel(x,y).a > 0.5:
						low.x = mini(low.x,x)
						low.y = mini(low.y,y)
						high.x = maxi(high.x,x+1)
						high.y = maxi(high.y,y+1)
			if high.y <= low.y:
				push_error("Empty sprite: "+path+" / "+str(index))
				quit(1)
				return
			var region := Rect2i(low,high-low)
			if spec[1] == "MUAY": region = muay_regions[index]
			var anchor: float = cell.get_center().x
			var baseline: float = region.end.y
			if spec[1] == "FINO":
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
				if tire_right > tire_left:
					anchor = (tire_left+tire_right)*0.5
					baseline = tire_floor
			elif spec[1] == "MUAY" and index < 8:
				var foot_left: int = 100000
				var foot_right: int = 0
				for y in range(region.end.y-int(region.size.y*0.12),region.end.y):
					for x in range(region.position.x,region.end.x):
						if picture.get_pixel(x,y).a > 0.5:
							foot_left = mini(foot_left,x)
							foot_right = maxi(foot_right,x)
				anchor = (foot_left+foot_right)*0.5
			var atlas := AtlasTexture.new()
			atlas.atlas = source
			atlas.region = Rect2(region)
			atlas.margin = Rect2(Vector2(512-(anchor-region.position.x),960-(baseline-region.position.y)),Vector2(1024-region.size.x,1024-region.size.y))
			atlas.filter_clip = true
			atlas.set_meta("original_source",path)
			atlas.set_meta("source_cell",cell)
			frames.add_frame(("IDLE" if index < 8 else "DASH") if spec[1] == "MUAY" else spec[1],atlas)
			heights.append(region.size.y)
		frames.set_meta("pivot",Vector2(512,960))
		frames.set_meta("source_height",heights.max() if spec[1] == "CYCLONE" else heights[0])
		if ResourceSaver.save(frames,"res://assets/"+spec[0]+"_frames.res",ResourceSaver.FLAG_COMPRESS) != OK:
			quit(1)
			return
		print("IMPORTED ",spec[1]," / 16 complete frames")
	quit()

func whole_figures(picture: Image) -> Array:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(picture,0.5)
	var parts: Array = []
	for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,picture.get_size()),0.15):
		var low := Vector2(INF,INF)
		var high := Vector2(-INF,-INF)
		var area: float = 0
		for i in range(polygon.size()):
			low = Vector2(minf(low.x,polygon[i].x),minf(low.y,polygon[i].y))
			high = Vector2(maxf(high.x,polygon[i].x),maxf(high.y,polygon[i].y))
			area += polygon[i].cross(polygon[(i+1)%polygon.size()])
		if absf(area)*0.5 > 2500: parts.append({"region":Rect2i(Vector2i(low.floor()),Vector2i(high.ceil()-low.floor())),"area":absf(area)*0.5})
	parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.area > b.area)
	parts = parts.slice(0,16)
	assert(parts.size() == 16,"Muay motion needs 16 connected complete bodies")
	parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.end.y < b.region.end.y)
	var result: Array = []
	for row in range(4):
		var group: Array = parts.slice(row*4,row*4+4)
		group.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().x < b.region.get_center().x)
		for part: Dictionary in group: result.append(part.region)
	return result
