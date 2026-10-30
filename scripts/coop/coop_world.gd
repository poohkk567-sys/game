extends RefCounted
const V = preload("res://scripts/coop/coop_visuals.gd")

static func build(stage: Node3D) -> void:
	var world := Node3D.new()
	world.name = "Courtyard3D"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	stage.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("111a37")
	sky_material.sky_horizon_color = Color("b66f56")
	sky_material.ground_bottom_color = Color("141827")
	sky_material.ground_horizon_color = Color("735a61")
	sky.sky_material = sky_material
	environment.environment.sky = sky
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a4b4df")
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-36,0)
	sun.light_color = Color("ffe0b1")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 40
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-36,145,0)
	fill.light_color = Color("728bd6")
	fill.light_energy = 0.40
	world.add_child(fill)
	var dark: StandardMaterial3D = V.material(Color("252c3e"))
	var edge: StandardMaterial3D = V.material(Color("4b5066"))
	var trim: StandardMaterial3D = V.material(Color("a18d70"))
	var luminous: StandardMaterial3D = V.material(Color("a371e7"),0.9)
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor3D"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	world.add_child(floor_body)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(26,0.8,19)
	collision.shape = box
	collision.position.y = -0.4
	floor_body.add_child(collision)
	V.block(world,Vector3(26,0.8,19),Vector3(0,-0.42,0),dark,0.18)
	V.block(world,Vector3(26.4,0.25,19.4),Vector3(0,-0.82,0),edge,0.10)
	build_tiles(world)
	var arena_ring := V.ring(world,9.9,0.06,Color(0.74,0.57,0.88,0.55))
	arena_ring.scale.z = 0.64
	var inner_ring := V.ring(world,3.0,0.045,Color(0.71,0.61,0.40,0.55))
	inner_ring.scale.z = 0.85
	for side: int in [-1,1]:
		for i in range(4):
			var x: float = side*12.1
			var z: float = -6+i*4
			V.block(world,Vector3(0.85,0.5,0.85),Vector3(x,0.25,z),edge,0.12)
			V.block(world,Vector3(0.50,2.25,0.50),Vector3(x,1.55,z),dark,0.10)
			V.block(world,Vector3(0.78,0.22,0.78),Vector3(x,2.75,z),trim,0.06)
			var lantern := SphereMesh.new()
			lantern.radius = 0.20
			lantern.height = 0.4
			lantern.radial_segments = 12
			lantern.rings = 6
			V.mesh(world,lantern,luminous,Vector3(x,3.0,z))
		V.block(world,Vector3(0.28,0.20,16),Vector3(side*12.1,1.5,0),trim,0.06)
		for level in range(3):
			V.block(world,Vector3(4.5+level*0.5,0.22,1.8),Vector3(side*8,-0.1-level*0.22,9.6+level*0.6),edge,0.06)
	# Gate and broken monument behind the playable ground, leaving the view clear.
	for side: int in [-1,1]:
		V.block(world,Vector3(1.1,6.4,1.2),Vector3(side*4.0,2.8,-9),dark,0.16)
		V.block(world,Vector3(1.45,0.35,1.5),Vector3(side*4,5.7,-9),trim,0.08)
	V.block(world,Vector3(10.5,0.75,1.5),Vector3(0,6.3,-9),edge,0.16)
	V.block(world,Vector3(8.4,0.24,0.80),Vector3(0,5.55,-9),trim,0.06)
	V.block(world,Vector3(2.4,1.0,0.35),Vector3(0,5.0,-8.6),dark,0.09)
	var sign := Label3D.new()
	sign.text = "E C L I P S E"
	sign.font_size = 60
	sign.pixel_size = 0.006
	sign.position = Vector3(0,5,-8.38)
	sign.modulate = Color("e5d3ac")
	sign.outline_size = 4
	world.add_child(sign)
	var hills: StandardMaterial3D = V.material(Color("263c4a"))
	var leaves: StandardMaterial3D = V.material(Color("30494c"))
	for i in range(14):
		var cone := CylinderMesh.new()
		cone.top_radius = 0
		cone.bottom_radius = 2.1+fmod(i*1.7,2.2)
		cone.height = 5+fmod(i*1.9,4.5)
		cone.radial_segments = 7
		var tree := V.mesh(world,cone,leaves if i%2 else hills,Vector3(-22+i*3.4,cone.height*0.5-0.8,-17-fmod(i*2.3,7)))
		tree.rotation.y = i*1.7
		tree.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side: int in [-1,1]:
		var crystal := V.block(world,Vector3(0.50,1.7,0.50),Vector3(side*10.0,1.0,-5.6),luminous,0.15)
		crystal.rotation.z = side*0.25
		var light := OmniLight3D.new()
		light.position = Vector3(side*9,2,-5)
		light.light_color = Color("aa80ff")
		light.light_energy = 2.0
		light.omni_range = 5.0
		world.add_child(light)

static func build_tiles(world: Node3D) -> void:
	# Decorative instances are unnecessary on a headless server (and Godot4.2
	# dummy storage cannot compute their per-instance mesh surface bounds).
	if DisplayServer.get_name() == "headless": return
	var tiles := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = V.stone(Vector3(1.94,0.08,1.94),0.035)
	multimesh.instance_count = 13*9
	tiles.multimesh = multimesh
	var tile_material: StandardMaterial3D = V.material(Color.WHITE)
	tile_material.vertex_color_use_as_albedo = true
	tiles.material_override = tile_material
	world.add_child(tiles)
	for row in range(9):
		for col in range(13):
			var index: int = row*13+col
			multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(-12+col*2,-0.04,-8+row*2)))
			var value: float = sin(index*17.31)*0.025
			multimesh.set_instance_color(index,Color(0.26+value,0.29+value,0.37+value))
