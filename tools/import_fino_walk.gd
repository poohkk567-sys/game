extends SceneTree
## Game atlas import: complete connected figures, original generated PNGs unchanged.
func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	for spec: Array in [["fino_ultimate","FINO",16,4],["walk_fixed","WALK",8,2],["cheer_assist","ASSIST",16,4]]:
		var path: String = "res://assets/characters/phuzashi_clear/"+spec[0]+".png"
		if not FileAccess.file_exists(path):
			continue
		var source: Texture2D = load(path)
		var picture: Image = source.get_image()
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(picture,0.5)
		var parts: Array = []
		for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,picture.get_size()),0.2):
			var low := Vector2(INF,INF)
			var high := Vector2(-INF,-INF)
			var area: float = 0
			for i in range(polygon.size()):
				low = Vector2(minf(low.x,polygon[i].x),minf(low.y,polygon[i].y))
				high = Vector2(maxf(high.x,polygon[i].x),maxf(high.y,polygon[i].y))
				area += polygon[i].cross(polygon[(i+1)%polygon.size()])
			if absf(area)*0.5 > 2500:
				parts.append({"region":Rect2i(Vector2i(low.floor()),Vector2i(high.ceil()-low.floor())),"polygon":polygon,"area":absf(area)*0.5})
		if spec[1] == "FINO":
			# Generated row gaps and tire-safe column boundaries, checked against source alpha.
			# Purple exhaust joins adjacent sprites; grid lines follow the empty body gaps.
			parts.clear()
			var xs: Array[int] = [0,362,720,1080,picture.get_width()]
			var ys: Array[int] = [0,325,602,848,picture.get_height()]
			for row in range(4):
				for col in range(4):
					var cell := Rect2i(xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row])
					var used: Rect2i = picture.get_region(cell).get_used_rect()
					used.position += cell.position
					parts.append({"region":used,"polygon":PackedVector2Array(),"area":float(used.get_area())})
		parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.area > b.area)
		parts = parts.slice(0,spec[2])
		if parts.size() != spec[2]:
			push_error("Incomplete whole-body sheet: "+path)
			quit(1)
			return
		parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.end.y < b.region.end.y)
		var ordered: Array = []
		for row in range(spec[3]):
			var group: Array = parts.slice(row*4,row*4+4)
			group.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().x < b.region.get_center().x)
			ordered.append_array(group)
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for clip: String in (["RUN","CHEER"] if spec[1] == "ASSIST" else [spec[1]]):
			frames.add_animation(clip)
			frames.set_animation_loop(clip,clip in ["WALK","RUN","CHEER"])
			frames.set_animation_speed(clip,12)
		for index in range(ordered.size()):
			var region: Rect2i = ordered[index].region
			var anchor: float = region.get_center().x
			var baseline: float = region.end.y
			if spec[1] == "FINO":
				baseline = region.position.y
				for y in range(region.position.y+int(region.size.y*0.8),region.end.y):
					for x in range(region.position.x,region.end.x):
						var color: Color = picture.get_pixel(x,y)
						if color.a > 0.5 and color.r < 0.45 and absf(color.r-color.g) < 0.10 and absf(color.b-color.g) < 0.10:
							baseline = maxf(baseline,y+1)
			var atlas := AtlasTexture.new()
			atlas.atlas = source
			atlas.region = Rect2(region)
			# If neighboring rectangular bounds intersect, retain only this whole silhouette.
			var overlap: bool = false
			for other: Dictionary in ordered:
				if other != ordered[index] and region.intersects(other.region):
					overlap = true
			if overlap and not ordered[index].polygon.is_empty():
				var isolated := Image.create(region.size.x,region.size.y,false,Image.FORMAT_RGBA8)
				for y in range(region.size.y):
					for x in range(region.size.x):
						if Geometry2D.is_point_in_polygon(Vector2(region.position)+Vector2(x+0.5,y+0.5),ordered[index].polygon):
							isolated.set_pixel(x,y,picture.get_pixel(region.position.x+x,region.position.y+y))
				atlas.atlas = ImageTexture.create_from_image(isolated)
				atlas.region = Rect2(Vector2.ZERO,Vector2(region.size))
			atlas.set_meta("original_source",path)
			atlas.margin = Rect2(Vector2(512-(anchor-region.position.x),960-(baseline-region.position.y)),Vector2(1024-region.size.x,1024-region.size.y))
			atlas.filter_clip = true
			frames.add_frame(("RUN" if index < 8 else "CHEER") if spec[1] == "ASSIST" else spec[1],atlas)
		frames.set_meta("pivot",Vector2(512,960))
		frames.set_meta("source_height",float(ordered[0].region.size.y))
		frames.set_meta("scales",{str(spec[1]):286.0/ordered[0].region.size.y})
		var result: Error = ResourceSaver.save(frames,"res://assets/characters/phuzashi_clear/"+spec[0]+"_frames.res",ResourceSaver.FLAG_COMPRESS)
		if result != OK:
			quit(1)
			return
		print("IMPORTED ",spec[1]," / ",ordered.size()," complete figures")
	quit()
