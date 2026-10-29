extends SceneTree
## Preserve whole body and held props, including detached cap/shirt pixels.
const SOURCE := "res://assets/characters/red_awakened/transform.png"
const CANVAS := Vector2i(1024,1024)
const PIVOT := Vector2i(512,960)

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var source: Texture2D = load(SOURCE)
	var image: Image = source.get_image()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image,0.5)
	var parts: Array = []
	for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),0.1):
		var area: float = 0
		var low := Vector2(INF,INF)
		var high := Vector2(-INF,-INF)
		for i in range(polygon.size()):
			area += polygon[i].cross(polygon[(i+1)%polygon.size()])
			low.x = minf(low.x,polygon[i].x)
			low.y = minf(low.y,polygon[i].y)
			high.x = maxf(high.x,polygon[i].x)
			high.y = maxf(high.y,polygon[i].y)
		area = absf(area)*0.5
		if area < 16:
			continue
		var bounds := Rect2i(Vector2i(low.floor()),Vector2i(high.ceil()-low.floor()))
		parts.append({"region":bounds,"polygon":polygon,"area":area})
	parts.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.area > b.area)
	if parts.size() < 16:
		push_error("Transformation requires sixteen whole bodies; found "+str(parts.size()))
		quit(1)
		return
	var bodies: Array = parts.slice(0,16)
	bodies.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.end.y < b.region.end.y)
	var ordered: Array = []
	for row in range(4):
		var figures: Array = bodies.slice(row*4,(row+1)*4)
		figures.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().x < b.region.get_center().x)
		ordered.append_array(figures)
	bodies = ordered
	for body: Dictionary in bodies:
		body["parts"] = [body.polygon]
		body["union"] = body.region
	# Assign props to the nearest head/upper torso, not to a figure in the row above.
	for prop: Dictionary in parts.slice(16):
		var best: int = -1
		var distance: float = INF
		for index in range(16):
			var region: Rect2i = bodies[index].region
			var anchor := Vector2(region.get_center().x,region.position.y+region.size.y*0.22)
			var candidate: float = anchor.distance_squared_to(Vector2(prop.region.get_center()))
			if candidate < distance:
				distance = candidate
				best = index
		bodies[best].parts.append(prop.polygon)
		bodies[best].union = bodies[best].union.merge(prop.region)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("TRANSFORM")
	frames.set_animation_loop("TRANSFORM",false)
	frames.set_animation_speed("TRANSFORM",5.0)
	var manifest: Dictionary = {"canvas":[1024,1024],"pivot":[512,960],"frames":[]}
	for index in range(16):
		var body: Dictionary = bodies[index]
		var region: Rect2i = body.union
		var isolated := Image.create(region.size.x,region.size.y,false,Image.FORMAT_RGBA8)
		for y in range(region.size.y):
			for x in range(region.size.x):
				var point := Vector2(region.position)+Vector2(x+0.5,y+0.5)
				for polygon: PackedVector2Array in body.parts:
					if Geometry2D.is_point_in_polygon(point,polygon):
						isolated.set_pixel(x,y,image.get_pixel(region.position.x+x,region.position.y+y))
						break
		var feet: Array[int] = []
		for y in range(body.region.end.y-5,body.region.end.y):
			for x in range(body.region.position.x,body.region.end.x):
				if image.get_pixel(x,y).a >= 0.5 and Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),body.polygon):
					feet.append(x)
		feet.sort()
		var foot_x: int = feet[feet.size()/2]
		var atlas := AtlasTexture.new()
		atlas.atlas = ImageTexture.create_from_image(isolated)
		atlas.region = Rect2(Vector2.ZERO,Vector2(region.size))
		atlas.margin = Rect2(Vector2(PIVOT.x-(foot_x-region.position.x),PIVOT.y-(body.region.end.y-region.position.y)),Vector2(CANVAS-region.size))
		atlas.filter_clip = true
		atlas.set_meta("original_source",SOURCE)
		frames.add_frame("TRANSFORM",atlas)
		manifest.frames.append({"frame":index,"source":SOURCE,"region":[region.position.x,region.position.y,region.size.x,region.size.y],"foot_x":foot_x,"floor_y":body.region.end.y,"parts":body.parts.size()})
	var factor: float = 286.0/float(bodies[0].region.size.y)
	frames.set_meta("scale",factor)
	frames.set_meta("pivot",Vector2(PIVOT))
	manifest["scale"] = factor
	var error: Error = ResourceSaver.save(frames,"res://assets/characters/red_awakened/transform_frames.res",ResourceSaver.FLAG_COMPRESS)
	var file := FileAccess.open("res://assets/characters/red_awakened/transform_manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("RED CAP TRANSFORM IMPORT: 16 complete frames with held props")
	quit(0 if error == OK else 1)
