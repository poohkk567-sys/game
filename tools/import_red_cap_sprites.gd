extends SceneTree
## Import whole connected drawings, retaining the seven generated PNGs unchanged.
const CANVAS := Vector2i(1024,1024)
const PIVOT := Vector2i(512,960)
const SHEETS: Dictionary = {
 "idle_walk": ["IDLE","WALK"], "run_jump": ["RUN","JUMP"],
 "crouch_guard": ["CROUCH","GUARD"], "punch_kick": ["PUNCH","KICK"],
 "punch_combo": ["PUNCH_2","PUNCH_3"], "kick_combo": ["KICK_2","KICK_3"],
 "hit_fall": ["HIT","FALL"]
}

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var scales: Dictionary = {}
	var manifest: Dictionary = {"canvas":[CANVAS.x,CANVAS.y], "pivot":[PIVOT.x,PIVOT.y], "frames":[]}
	for sheet: String in SHEETS:
		var source: Texture2D = load("res://assets/characters/red_cap/%s.png" % sheet)
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
			drawings.append({"region":region,"order":row * image.get_width()+region.get_center().x})
		drawings.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.order < b.order)
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
				for other: Dictionary in drawings:
					if region != other.region and region.intersects(other.region):
						push_error("Overlapping source silhouettes: %s frame %d" % [clip,index])
						quit(1)
						return
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
				atlas.margin = Rect2(Vector2(PIVOT.x-(anchor-region.position.x),PIVOT.y-region.size.y),Vector2(CANVAS-region.size))
				atlas.filter_clip = true
				frames.add_frame(clip,atlas)
				manifest.frames.append({"clip":clip,"frame":index,"source":"res://assets/characters/red_cap/%s.png" % sheet,"region":[region.position.x,region.position.y,region.size.x,region.size.y],"foot_x":anchor,"floor_y":region.end.y})
			print("Imported ",clip,": 8 complete figures, scale ",scales[clip])
	frames.set_meta("scales",scales)
	frames.set_meta("pivot",Vector2(PIVOT))
	manifest["scales"] = scales
	var error: Error = ResourceSaver.save(frames,"res://assets/characters/red_cap/red_cap_frames.res",ResourceSaver.FLAG_COMPRESS)
	var file := FileAccess.open("res://assets/characters/red_cap/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("RED CAP IMPORT: 14 animations / 112 complete figures")
	quit(0 if error == OK else 1)
