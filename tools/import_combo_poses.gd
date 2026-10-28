extends SceneTree
## Import whole connected drawings, retaining the four generated PNGs unchanged.
const CANVAS := Vector2i(1024,1024)
const PIVOT := Vector2i(512,960)
const SHEETS: Dictionary = {
	"PUNCH_2": "res://assets/characters/combos/punch_2_hook.png",
	"PUNCH_3": "res://assets/characters/combos/punch_3_uppercut.png",
	"KICK_2": "res://assets/characters/combos/kick_2_spin.png",
	"KICK_3": "res://assets/characters/combos/kick_3_axe.png"
}

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var scales: Dictionary = {}
	var manifest: Dictionary = {"canvas":[CANVAS.x,CANVAS.y], "pivot":[PIVOT.x,PIVOT.y], "frames":[]}
	for clip: String in SHEETS:
		var source: Texture2D = load(SHEETS[clip])
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
			var row: int = 0 if region.get_center().y < image.get_height()/2 else 1
			drawings.append({"region":region,"order":row * image.get_width()+region.get_center().x})
		drawings.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.order < b.order)
		if drawings.size() != 8:
			push_error("Expected eight connected whole figures for %s, found %d" % [clip,drawings.size()])
			quit(1)
			return
		var guard_height: float = (drawings[0].region.size.y + drawings[7].region.size.y) * 0.5
		scales[clip] = 286.0 / guard_height
		frames.add_animation(clip)
		frames.set_animation_loop(clip,false)
		for index in range(8):
			var region: Rect2i = drawings[index].region
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
			manifest.frames.append({"clip":clip,"frame":index,"source":SHEETS[clip],"region":[region.position.x,region.position.y,region.size.x,region.size.y],"foot_x":anchor,"floor_y":region.end.y})
		print("Imported ",clip,": 8 complete figures, scale ",scales[clip])
	frames.set_meta("scales",scales)
	frames.set_meta("pivot",Vector2(PIVOT))
	manifest["scales"] = scales
	var error: Error = ResourceSaver.save(frames,"res://assets/characters/combos/combo_frames.res",ResourceSaver.FLAG_COMPRESS)
	var file := FileAccess.open("res://assets/characters/combos/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	print("COMBO POSE IMPORT: 4 animations / 32 complete figures")
	quit(0 if error == OK else 1)
