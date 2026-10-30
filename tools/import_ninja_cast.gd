extends "res://tools/import_side_guardians.gd"
const SHEETS_CAST := {"SEAL_CHILL":"seal_chill","SEAL_CLASSIC":"seal_classic","SHOVE":"capped_shove"}
func build() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var heights: Dictionary = {}
	for clip: String in SHEETS_CAST:
		var texture: Texture2D = load("res://assets/characters/ninja_cast/"+SHEETS_CAST[clip]+".png")
		var picture: Image = texture.get_image()
		var size: Vector2i = picture.get_size()
		frames.add_animation(clip)
		frames.set_animation_loop(clip,false)
		var middle: int = gutter(picture,true,size.y/2,Rect2i(Vector2i.ZERO,size),int(size.y*0.025))
		var height: float = 0
		for row in range(2):
			var top: int = 0 if row == 0 else middle
			var bottom: int = middle if row == 0 else size.y
			var bounds := Rect2i(0,top,size.x,bottom-top)
			var cuts: Array[int] = [0]
			for column in range(1,4): cuts.append(gutter(picture,false,roundi(column*size.x/4.0),bounds,int(size.x*0.015)))
			cuts.append(size.x)
			for column in range(4):
				var cell := Rect2i(cuts[column],top,cuts[column+1]-cuts[column],bottom-top)
				var low := cell.end
				var high := cell.position
				for y in range(cell.position.y,cell.end.y):
					for x in range(cell.position.x,cell.end.x):
						if picture.get_pixel(x,y).a > 0.50:
							low = Vector2i(mini(low.x,x),mini(low.y,y))
							high = Vector2i(maxi(high.x,x+1),maxi(high.y,y+1))
				if high.y <= low.y:
					push_error("Empty cast frame "+clip)
					quit(1)
					return
				height = maxf(height,high.y-low.y)
				var foot_sum: float = 0
				var feet: float = 0
				for y in range(high.y-maxi(4,roundi((high.y-low.y)*0.025)),high.y):
					for x in range(low.x,high.x):
						if picture.get_pixel(x,y).a > 0.6:
							foot_sum += x
							feet += 1
				var anchor := Vector2(foot_sum/maxf(1,feet),high.y)
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(cell)
				atlas.filter_clip = true
				atlas.margin = Rect2(Vector2(512,960)-(anchor-Vector2(cell.position)),Vector2(1024,1024)-Vector2(cell.size))
				frames.add_frame(clip,atlas)
		heights[clip] = height
		print("IMPORTED ",clip," 8 complete casting drawings height=",height)
	frames.set_meta("heights",heights)
	assert(ResourceSaver.save(frames,"res://assets/characters/ninja_cast/cast_frames.res",ResourceSaver.FLAG_COMPRESS) == OK)
	quit()
