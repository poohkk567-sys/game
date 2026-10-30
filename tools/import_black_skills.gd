extends "res://tools/import_side_guardians.gd"
## Extract atlases in Godot without modifying either original generated image.
func build() -> void:
	var effects := SpriteFrames.new()
	effects.remove_animation("default")
	var texture: Texture2D = load("res://assets/effects/black_skills/crimson_skills.png")
	var picture: Image = texture.get_image()
	var rows: Array[int] = cuts(picture,true,5,Rect2i(Vector2i.ZERO,picture.get_size()))
	var clips: Array[String] = ["FANG","DRIVE","RISE","CRUSH","BURST"]
	for row in range(5):
		var bounds := Rect2i(0,rows[row],picture.get_width(),rows[row+1]-rows[row])
		var columns: Array[int] = cuts(picture,false,4,bounds)
		effects.add_animation(clips[row])
		effects.set_animation_loop(clips[row],false)
		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(columns[col],bounds.position.y,columns[col+1]-columns[col],bounds.size.y)
			atlas.filter_clip = true
			# A thin transparent margin prevents touching the destination boundary.
			atlas.margin = Rect2(4,4,8,8)
			effects.add_frame(clips[row],atlas)
		print("IMPORTED CRIMSON ",clips[row]," / 4 frames")
	assert(ResourceSaver.save(effects,"res://assets/effects/black_skills/crimson_frames.res",ResourceSaver.FLAG_COMPRESS) == OK)
	var body := SpriteFrames.new()
	body.remove_animation("default")
	texture = load("res://assets/characters/black_coat/skills/rise_crush.png")
	picture = texture.get_image()
	rows = cuts(picture,true,4,Rect2i(Vector2i.ZERO,picture.get_size()),0.045)
	var heights: Dictionary = {}
	for row in range(4):
		var clip: String = "RISE" if row < 2 else "CRUSH"
		if row%2 == 0:
			body.add_animation(clip)
			body.set_animation_loop(clip,false)
		var bounds := Rect2i(0,rows[row],picture.get_width(),rows[row+1]-rows[row])
		var columns: Array[int] = cuts(picture,false,4,bounds)
		for col in range(4):
			var cell := Rect2i(columns[col],bounds.position.y,columns[col+1]-columns[col],bounds.size.y)
			# Small remnants from the neighbouring row must not enter this body.
			# Keep the largest connected silhouette, with a few pixels of edge room.
			var bitmap := BitMap.new()
			bitmap.create_from_image_alpha(picture.get_region(cell),0.5)
			var core := Rect2()
			var largest: float = 0
			for polygon: PackedVector2Array in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,cell.size),0.2):
				var area: float = 0
				var box := Rect2(polygon[0],Vector2.ZERO)
				for i in range(polygon.size()):
					area += polygon[i].cross(polygon[(i+1)%polygon.size()])
					box = box.expand(polygon[i])
				if absf(area) > largest:
					largest = absf(area)
					core = box
			assert(largest > 1000,"No complete body in cast cell")
			cell = Rect2i((core.grow(3).intersection(Rect2(Vector2.ZERO,cell.size))).position+Vector2(cell.position),(core.grow(3).intersection(Rect2(Vector2.ZERO,cell.size))).size)
			var low: Vector2i = cell.end
			var high: Vector2i = cell.position
			for y in range(cell.position.y,cell.end.y):
				for x in range(cell.position.x,cell.end.x):
					if picture.get_pixel(x,y).a > 0.5:
						low = Vector2i(mini(low.x,x),mini(low.y,y))
						high = Vector2i(maxi(high.x,x+1),maxi(high.y,y+1))
			assert(high.y > low.y,"Empty black cast frame")
			if row%2 == 0 and col == 0: heights[clip] = high.y-low.y
			var total: float = 0
			var feet: int = 0
			for y in range(high.y-6,high.y):
				for x in range(low.x,high.x):
					if picture.get_pixel(x,y).a > 0.6:
						total += x
						feet += 1
			var anchor := Vector2(total/maxi(1,feet),high.y)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(cell)
			atlas.margin = Rect2(Vector2(512,960)-(anchor-Vector2(cell.position)),Vector2(1024,1024)-Vector2(cell.size))
			atlas.filter_clip = true
			body.add_frame(clip,atlas)
	body.set_meta("heights",heights)
	assert(ResourceSaver.save(body,"res://assets/characters/black_coat/skills/black_cast_frames.res",ResourceSaver.FLAG_COMPRESS) == OK)
	print("IMPORTED BLACK / 16 complete body drawings / ",heights)
	quit()

func cuts(picture: Image, horizontal: bool, count: int, bounds: Rect2i, radius: float = 0.012) -> Array[int]:
	var length: int = picture.get_height() if horizontal else picture.get_width()
	var result: Array[int] = [0]
	for i in range(1,count): result.append(gutter(picture,horizontal,roundi(float(i)*length/count),bounds,int(length*radius)))
	result.append(length)
	return result
