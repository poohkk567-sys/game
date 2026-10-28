extends SceneTree
## Rebuild the trial's SpriteFrames without resampling or repainting the PNG.
const SOURCE: String = "res://assets/characters/drafts/idle_walk_draft.png"
const OUTPUT: String = "res://assets/characters/drafts/idle_walk_frames.tres"
const CANVAS := Vector2i(320,362)
const PIVOT := Vector2i(160,340)

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var atlas: Texture2D = load(SOURCE)
	var image: Image = atlas.get_image() if atlas != null else null
	if image == null or atlas == null:
		push_error("Cannot load draft atlas")
		quit(1)
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var manifest: Dictionary = {"source":SOURCE,"size":[image.get_width(),image.get_height()],"canvas":[CANVAS.x,CANVAS.y],"pivot":[PIVOT.x,PIVOT.y],"alpha_threshold":0.5,"frames":[]}
	for row in range(2):
		var animation: String = "IDLE" if row == 0 else "WALK"
		frames.add_animation(animation)
		frames.set_animation_speed(animation, 6.0 if row == 0 else 11.0)
		frames.set_animation_loop(animation,true)
		for column in range(8):
			var left: int = roundi(column*image.get_width()/8.0)
			var right: int = roundi((column+1)*image.get_width()/8.0)
			var top: int = row*image.get_height()/2
			var bottom: int = (row+1)*image.get_height()/2
			var minimum := Vector2i(right,bottom)
			var maximum := Vector2i(-1,-1)
			for y in range(top,bottom):
				for x in range(left,right):
					if image.get_pixel(x,y).a >= 0.5:
						minimum = Vector2i(mini(minimum.x,x),mini(minimum.y,y))
						maximum = Vector2i(maxi(maximum.x,x),maxi(maximum.y,y))
			if maximum.x < 0:
				push_error("Empty atlas cell")
				quit(1)
				return
			var region := Rect2i(minimum,maximum-minimum+Vector2i.ONE)
			# Anchor at the waist, not the bounding-box center: a forward fist or
			# extended foot must not shift the entire character horizontally.
			var centers: Array[float] = []
			for y in range(region.position.y+roundi(region.size.y*0.61),region.position.y+roundi(region.size.y*0.68)):
				var lo: int = right
				var hi: int = -1
				for x in range(left,right):
					if image.get_pixel(x,y).a >= 0.5:
						lo = mini(lo,x)
						hi = maxi(hi,x)
				if hi >= lo:
					centers.append((lo+hi+1)*0.5)
			centers.sort()
			var waist: int = roundi(centers[centers.size()/2])
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = region
			texture.margin = Rect2(Vector2(PIVOT.x-(waist-region.position.x),PIVOT.y-region.size.y),Vector2(CANVAS-region.size))
			texture.filter_clip = true
			frames.add_frame(animation,texture)
			manifest.frames.append({"animation":animation,"frame":column,"region":[region.position.x,region.position.y,region.size.x,region.size.y],"waist_x":waist,"floor_y":region.end.y})
	var error: Error = ResourceSaver.save(frames,OUTPUT)
	var file := FileAccess.open("res://assets/characters/drafts/idle_walk_manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("Imported ",frames.get_frame_count("IDLE")," IDLE and ",frames.get_frame_count("WALK")," WALK frames; shared feet pivot ",PIVOT)
	quit(0 if error == OK else 1)
