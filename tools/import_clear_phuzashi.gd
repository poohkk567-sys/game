extends SceneTree
## Import whole connected drawings, retaining the eight generated PNGs unchanged.
const CANVAS := Vector2i(1024,1024)
const PIVOT := Vector2i(512,960)
const SHEETS: Dictionary = {
 "idle_walk": ["IDLE","WALK"], "run_jump": ["RUN","JUMP"],
 "crouch_guard": ["CROUCH","GUARD"], "punch_kick": ["PUNCH","KICK"],
 "punch_combo": ["PUNCH_2","PUNCH_3"], "kick_combo": ["KICK_2","KICK_3"],
 "hit_fall": ["HIT","FALL"], "powers":["SPECIAL","ULTIMATE"]
}

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var scales: Dictionary = {}
	var manifest: Dictionary = {"canvas":[CANVAS.x,CANVAS.y], "pivot":[PIVOT.x,PIVOT.y], "frames":[]}
	for sheet: String in SHEETS:
		var source: Texture2D = load("res://assets/characters/phuzashi_clear/%s.png" % sheet)
		var image: Image = source.get_image()
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image,0.5)
		var drawings: Array = []
		for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),0.1):
			var area: float = 0.0
			var low := Vector2(INF,INF)
			var high := Vector2(-INF,-INF)
			for i in range(polygon.size()):
				area += polygon[i].cross(polygon[(i+1)%polygon.size()])
				low.x = minf(low.x,polygon[i].x)
				low.y = minf(low.y,polygon[i].y)
				high.x = maxf(high.x,polygon[i].x)
				high.y = maxf(high.y,polygon[i].y)
			if absf(area) * 0.5 < 1000.0:
				continue
			var region := Rect2i(Vector2i(low.floor()),Vector2i(high.ceil()-low.floor()))
			var row: int = floori(float(region.get_center().y) / (image.get_height()/4.0))
			drawings.append({"region":region,"polygon":polygon,"order":row * image.get_width()+region.get_center().x})
		# Use the four source-row baselines, not figure centers: seated/lying
		# bodies have lower centers than standing figures in the same row.
		drawings.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.end.y < b.region.end.y)
		var ordered: Array = []
		for row in range(4):
			var group: Array = drawings.slice(row*4,(row+1)*4)
			group.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().x < b.region.get_center().x)
			ordered.append_array(group)
		drawings = ordered
		if drawings.size() != 16:
			push_error("Expected sixteen connected whole figures for %s, found %d" % [sheet,drawings.size()])
			quit(1)
			return
		for group in range(2):
			var clip: String = SHEETS[sheet][group]
			var guard_height: float = drawings[group*8].region.size.y
			scales[clip] = 286.0 / guard_height
			frames.add_animation(clip)
			frames.set_animation_loop(clip,clip in ["IDLE","WALK","RUN"])
			frames.set_animation_speed(clip, {"IDLE":6.0,"WALK":11.0,"RUN":16.0,"CROUCH":20.0,"GUARD":20.0}.get(clip,16.0))
			for index in range(8):
				var region: Rect2i = drawings[group*8+index].region
				var overlapping: bool = false
				for other: Dictionary in drawings:
					if region != other.region and region.intersects(other.region):
						overlapping = true
				var feet: Array[int] = []
				for y in range(region.end.y-5,region.end.y):
					for x in range(region.position.x,region.end.x):
						if image.get_pixel(x,y).a >= 0.5:
							feet.append(x)
				feet.sort()
				var anchor: int = feet[feet.size()/2]
				var atlas := AtlasTexture.new()
				atlas.atlas = source
				atlas.region = Rect2(region)
				if overlapping:
					# Bounding boxes can intersect while the silhouettes remain separate.
					# Embed the COMPLETE connected figure; never trim feet or borrow pixels.
					var isolated := Image.create(region.size.x,region.size.y,false,Image.FORMAT_RGBA8)
					var polygon: PackedVector2Array = drawings[group*8+index].polygon
					for y in range(region.size.y):
						for x in range(region.size.x):
							var point := Vector2(region.position)+Vector2(x+0.5,y+0.5)
							if Geometry2D.is_point_in_polygon(point,polygon):
								isolated.set_pixel(x,y,image.get_pixel(region.position.x+x,region.position.y+y))
					atlas.atlas = ImageTexture.create_from_image(isolated)
					atlas.region = Rect2(Vector2.ZERO,Vector2(region.size))
					atlas.set_meta("original_source","res://assets/characters/phuzashi_clear/%s.png" % sheet)
					print("Isolated whole connected figure: ",clip,"/",index)
				atlas.margin = Rect2(Vector2(PIVOT.x-(anchor-region.position.x),PIVOT.y-region.size.y),Vector2(CANVAS-region.size))
				atlas.filter_clip = true
				frames.add_frame(clip,atlas)
				manifest.frames.append({"clip":clip,"frame":index,"source":"res://assets/characters/phuzashi_clear/%s.png" % sheet,"region":[region.position.x,region.position.y,region.size.x,region.size.y],"foot_x":anchor,"floor_y":region.end.y})
			print("Imported ",clip,": 8 complete figures, scale ",scales[clip])
	frames.set_meta("scales",scales)
	frames.set_meta("pivot",Vector2(PIVOT))
	manifest["scales"] = scales
	var error: Error = ResourceSaver.save(frames,"res://assets/characters/phuzashi_clear/clear_frames.res",ResourceSaver.FLAG_COMPRESS)
	var file := FileAccess.open("res://assets/characters/phuzashi_clear/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("CLEAR PHUZASHI IMPORT: 16 animations / 128 complete figures")
	quit(0 if error == OK else 1)
