extends "res://tools/import_side_guardians.gd"
## Separate small standing chain poses. Keep eye/core stable while scarf moves.
func build() -> void:
	var texture: Texture2D = load("res://assets/effects/ninja_grapple/ninja_grapple.png")
	var picture: Image = texture.get_image()
	var size: Vector2i = picture.get_size()
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("GRIP")
	frames.set_animation_loop("GRIP",true)
	frames.set_animation_speed("GRIP",10)
	var height: float = 0
	var reference_offset := Vector2.ZERO
	var middle: int = gutter(picture,true,size.y/2,Rect2i(Vector2i.ZERO,size),int(size.y*0.04))
	for row in range(2):
		var top: int = 0 if row == 0 else middle
		var bottom: int = middle if row == 0 else size.y
		var bounds := Rect2i(0,top,size.x,bottom-top)
		var cuts: Array[int] = [0]
		for column in range(1,4): cuts.append(gutter(picture,false,roundi(column*size.x/4.0),bounds,int(size.x*0.02)))
		cuts.append(size.x)
		for column in range(4):
			var cell := Rect2i(cuts[column],top,cuts[column+1]-cuts[column],bottom-top)
			var low := cell.end
			var high := cell.position
			var weighted := Vector2.ZERO
			var weights: float = 0
			for y in range(cell.position.y,cell.end.y):
				for x in range(cell.position.x,cell.end.x):
					var color: Color = picture.get_pixel(x,y)
					if color.a > 0.15:
						low = Vector2i(mini(low.x,x),mini(low.y,y))
						high = Vector2i(maxi(high.x,x+1),maxi(high.y,y+1))
					var q: Vector2 = Vector2(x-cell.position.x,y-cell.position.y)/Vector2(cell.size)
					if q.x > 0.35 and q.x < 0.94 and q.y > 0.20 and q.y < 0.65:
						var weight: float = pow(maxf(0,minf(color.r,minf(color.g,color.b))-0.5),2)*color.a
						weighted += Vector2(x,y)*weight
						weights += weight
			if high.y <= low.y or weights <= 0:
				push_error("Missing standing ninja or eye highlight, cell="+str(row*4+column))
				quit(1)
				return
			height = maxf(height,high.y-low.y)
			var core: Vector2 = weighted/weights
			if row == 0 and column == 0: reference_offset = Vector2(low.x+(high.x-low.x)*0.58,high.y)-core
			var anchor: Vector2 = core+reference_offset
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(cell)
			atlas.margin = Rect2(Vector2(512,960)-(anchor-Vector2(cell.position)),Vector2(1024,1024)-Vector2(cell.size))
			atlas.filter_clip = true
			atlas.set_meta("core",core-Vector2(cell.position))
			atlas.set_meta("ink_bounds",Rect2(Vector2(low-cell.position),Vector2(high-low)))
			frames.add_frame("GRIP",atlas)
	frames.set_meta("height",height)
	frames.set_meta("pivot",Vector2(512,960))
	assert(ResourceSaver.save(frames,"res://assets/effects/ninja_grapple_frames.res",ResourceSaver.FLAG_COMPRESS) == OK)
	print("IMPORTED 8 small standing ninja chain frames, height=",height)
	quit()
