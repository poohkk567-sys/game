extends SceneTree
## Import coherent full-body drawings, including poses crossing nominal grid lines.
const OUTPUT: String = "res://assets/characters/spritesheets/phuzashi_frames.res"
const CANVAS := Vector2i(512,384)
const PIVOT := Vector2i(256,360)
const SHEETS: Array = [
	["res://assets/characters/drafts/idle_walk_draft.png",["IDLE","WALK"]],
	["res://assets/characters/spritesheets/mobility.png",["RUN","JUMP"]],
	["res://assets/characters/spritesheets/defense.png",["CROUCH","GUARD"]],
	["res://assets/characters/spritesheets/strikes.png",["PUNCH","KICK"]],
	["res://assets/characters/spritesheets/reactions.png",["HIT","FALL"]],
	["res://assets/characters/spritesheets/powers.png",["SPECIAL","ULTIMATE"]]
]
const SPEEDS: Dictionary = {"IDLE":6.0,"WALK":11.0,"RUN":16.0,"JUMP":10.0,"CROUCH":20.0,"GUARD":20.0,"PUNCH":19.0,"KICK":14.0,"HIT":17.0,"FALL":6.0,"SPECIAL":9.0,"ULTIMATE":4.5}

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var manifest: Dictionary = {"canvas":[CANVAS.x,CANVAS.y],"pivot":[PIVOT.x,PIVOT.y],"alpha_threshold":0.5,"frames":[]}
	for sheet: Array in SHEETS:
		var atlas: Texture2D = load(sheet[0])
		if atlas == null:
			fail("Cannot load "+sheet[0])
			return
		var image: Image = atlas.get_image()
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(image,0.5)
		var rows: Array = [[],[]]
		for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,image.get_size()),0.1):
			var area: float = 0.0
			var lo := Vector2(INF,INF)
			var hi := Vector2(-INF,-INF)
			for i in range(polygon.size()):
				area += polygon[i].cross(polygon[(i+1)%polygon.size()])
				lo.x = minf(lo.x,polygon[i].x)
				lo.y = minf(lo.y,polygon[i].y)
				hi.x = maxf(hi.x,polygon[i].x)
				hi.y = maxf(hi.y,polygon[i].y)
			if absf(area)*0.5 < 1500.0:
				continue
			var region := Rect2i(Vector2i(floori(lo.x),floori(lo.y)),Vector2i(ceili(hi.x)-floori(lo.x),ceili(hi.y)-floori(lo.y)))
			var row: int = 0 if region.get_center().y < image.get_height()/2 else 1
			rows[row].append({"region":region,"polygon":polygon})
		for row in range(2):
			rows[row].sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.region.get_center().x < b.region.get_center().x)
			if rows[row].size() != 8:
				fail("Expected 8 complete silhouettes in row %d of %s, found %d" % [row,sheet[0],rows[row].size()])
				return
			var animation: String = sheet[1][row]
			frames.add_animation(animation)
			frames.set_animation_speed(animation,float(SPEEDS[animation]))
			frames.set_animation_loop(animation,animation in ["IDLE","WALK","RUN"])
			for index in range(8):
				var region: Rect2i = rows[row][index].region
				if region.size.x > CANVAS.x or region.size.y > CANVAS.y:
					fail("Pose exceeds the common frame canvas: "+animation)
					return
				var centers: Array[float] = []
				for y in range(region.position.y+roundi(region.size.y*0.61),region.position.y+roundi(region.size.y*0.68)):
					var lo: int = region.end.x
					var hi: int = -1
					for x in range(region.position.x,region.end.x):
						if image.get_pixel(x,y).a >= 0.5:
							lo = mini(lo,x)
							hi = maxi(hi,x)
					if hi >= lo:
						centers.append((lo+hi+1)*0.5)
				centers.sort()
				var waist: int = roundi(centers[centers.size()/2])
				var texture := AtlasTexture.new()
				var isolated: bool = false
				for nearby_row: Array in rows:
					for other: Dictionary in nearby_row:
						if other.region != region and region.intersects(other.region):
							isolated = true
				texture.atlas = isolate(image,region,rows[row][index].polygon) if isolated else atlas
				texture.region = Rect2(Vector2.ZERO,Vector2(region.size)) if isolated else Rect2(region)
				if isolated:
					print("Isolated touching source drawings: ",animation," frame ",index)
				texture.margin = Rect2(Vector2(PIVOT.x-(waist-region.position.x),PIVOT.y-region.size.y),Vector2(CANVAS-region.size))
				texture.filter_clip = true
				frames.add_frame(animation,texture)
				manifest.frames.append({"animation":animation,"frame":index,"source":sheet[0],"isolated":isolated,"region":[region.position.x,region.position.y,region.size.x,region.size.y],"waist_x":waist,"floor_y":region.end.y})
			print("Imported ",animation,": 8 whole-body frames")
	var error: Error = ResourceSaver.save(frames,OUTPUT,ResourceSaver.FLAG_COMPRESS)
	var file := FileAccess.open("res://assets/characters/spritesheets/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("SPRITESHEET IMPORT: ",frames.get_animation_names().size()," animations / ",manifest.frames.size()," frames")
	quit(0 if error == OK else 1)

func fail(message: String) -> void:
	push_error(message)
	quit(1)

func isolate(image: Image,region: Rect2i,outline: PackedVector2Array) -> Texture2D:
	# Lossless alpha isolation, not repainting: copy only the connected source
	# silhouette. Overlapping bounding boxes must not include a neighbor's hand.
	var output := Image.create(region.size.x,region.size.y,false,Image.FORMAT_RGBA8)
	var queue := PackedInt32Array()
	var visited := PackedByteArray()
	visited.resize(region.size.x*region.size.y)
	for y in range(region.size.y):
		for x in range(region.size.x):
			var point: Vector2 = Vector2(region.position+Vector2i(x,y))+Vector2(0.5,0.5)
			if image.get_pixelv(region.position+Vector2i(x,y)).a >= 0.5 and Geometry2D.is_point_in_polygon(point,outline):
				queue.append(y*region.size.x+x)
				visited[y*region.size.x+x] = 1
				break
		if not queue.is_empty():
			break
	var cursor: int = 0
	while cursor < queue.size():
		var index: int = queue[cursor]
		cursor += 1
		var x: int = index%region.size.x
		var y: int = index/region.size.x
		output.set_pixel(x,y,image.get_pixelv(region.position+Vector2i(x,y)))
		for dy in range(-1,2):
			for dx in range(-1,2):
				var nx: int = x+dx
				var ny: int = y+dy
				if nx < 0 or ny < 0 or nx >= region.size.x or ny >= region.size.y:
					continue
				var next: int = ny*region.size.x+nx
				if visited[next] == 0 and image.get_pixelv(region.position+Vector2i(nx,ny)).a >= 0.5:
					visited[next] = 1
					queue.append(next)
	return ImageTexture.create_from_image(output)
