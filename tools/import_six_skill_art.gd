extends SceneTree
## Import connected full-body figures into a foot-anchored virtual canvas.
func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	for spec: Array in [["muay_thai/gorilla_stand","STAND"],["red_awakened/skills","ASSJIRO"]]:
		var path: String = "res://assets/characters/"+spec[0]+".png"
		var source: Texture2D = load(path)
		var picture: Image = source.get_image()
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
			if absf(area)*0.5 > 2500:
				parts.append({"region":Rect2i(Vector2i(low.floor()),Vector2i(high.ceil()-low.floor())),"area":absf(area)*0.5})
		parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.area > b.area)
		parts = parts.slice(0,16)
		if parts.size() != 16:
			push_error("Expected 16 whole bodies: "+path)
			quit(1)
			return
		parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.end.y < b.region.end.y)
		var ordered: Array = []
		for row in range(4):
			var group: Array = parts.slice(row*4,row*4+4)
			group.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().x < b.region.get_center().x)
			ordered.append_array(group)
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for clip: String in (["STAND"] if spec[1] == "STAND" else ["SOY_BOMB","CARROT_SPIN"]):
			frames.add_animation(clip)
			frames.set_animation_loop(clip,false)
			frames.set_animation_speed(clip,12)
		for index in range(16):
			var region: Rect2i = ordered[index].region
			var feet: Array[int] = []
			for y in range(region.end.y-4,region.end.y):
				for x in range(region.position.x,region.end.x):
					if picture.get_pixel(x,y).a > 0.5: feet.append(x)
			feet.sort()
			var anchor: float = region.get_center().x if spec[1] == "STAND" else (feet[feet.size()/2] if not feet.is_empty() else region.get_center().x)
			var atlas := AtlasTexture.new()
			atlas.atlas = source
			atlas.region = Rect2(region)
			atlas.margin = Rect2(Vector2(512-(anchor-region.position.x),960-region.size.y),Vector2(1024-region.size.x,1024-region.size.y))
			atlas.filter_clip = true
			atlas.set_meta("original_source",path)
			frames.add_frame("STAND" if spec[1] == "STAND" else ("SOY_BOMB" if index < 8 else "CARROT_SPIN"),atlas)
		frames.set_meta("pivot",Vector2(512,960))
		frames.set_meta("source_height",float(ordered[1 if spec[1] == "STAND" else 0].region.size.y))
		var result: Error = ResourceSaver.save(frames,"res://assets/characters/"+spec[0]+"_frames.res",ResourceSaver.FLAG_COMPRESS)
		if result != OK:
			quit(1)
			return
		print("IMPORTED ",spec[0]," / 16 whole figures")
	quit()
