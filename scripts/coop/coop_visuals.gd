extends RefCounted
## Low-poly 3D geometry, not a picture of a 3D arena.
static func material(color: Color, emission: float = 0, alpha: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.88
	if emission > 0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = emission
	if alpha:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result

static func mesh(parent: Node3D, shape: Mesh, surface: Material, point: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	# Godot4.2 dummy storage reports null-mesh errors when freeing ArrayMesh
	# instances. Keep transform placeholders on headless servers; physics uses
	# independent CollisionShape3D nodes. Native renderers build the real meshes.
	if DisplayServer.get_name() != "headless" or Engine.get_version_info().minor > 2:
		result.mesh = shape
		result.material_override = surface
	result.position = point
	parent.add_child(result)
	return result

static func block(parent: Node3D, size: Vector3, point: Vector3, surface: Material, bevel: float = 0.1) -> MeshInstance3D:
	return mesh(parent,stone(size,bevel),surface,point)

static func cylinder(parent: Node3D, radius: float, height: float, point: Vector3, surface: Material, sides: int = 32) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = sides
	return mesh(parent,shape,surface,point)

static func stone(size: Vector3, bevel: float) -> ArrayMesh:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: Vector3 = size*0.5
	var cut: float = minf(bevel,minf(half.x,minf(half.y,half.z))*0.65)
	var rings: Array[PackedVector3Array] = []
	for row in range(4):
		var y: float = [-half.y,-half.y+cut,half.y-cut,half.y][row]
		var inset: float = cut if row in [0,3] else 0
		var x: float = half.x-inset
		var z: float = half.z-inset
		var c: float = minf(cut,minf(x,z)*0.5)
		rings.append(PackedVector3Array([Vector3(-x+c,y,-z),Vector3(x-c,y,-z),Vector3(x,y,-z+c),Vector3(x,y,z-c),Vector3(x-c,y,z),Vector3(-x+c,y,z),Vector3(-x,y,z-c),Vector3(-x,y,-z+c)]))
	for row in range(3):
		for i in range(8):
			var next: int = (i+1)%8
			triangle(builder,rings[row][i],rings[row+1][i],rings[row][next])
			triangle(builder,rings[row][next],rings[row+1][i],rings[row+1][next])
	for i in range(1,7):
		triangle(builder,rings[0][0],rings[0][i],rings[0][i+1])
		triangle(builder,rings[3][0],rings[3][i+1],rings[3][i])
	builder.generate_normals()
	return builder.commit()

static func triangle(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	builder.add_vertex(a)
	builder.add_vertex(b)
	builder.add_vertex(c)

static func ground_mark(parent: Node3D, radius: float, color: Color) -> MeshInstance3D:
	var result := cylinder(parent,radius,0.008,Vector3(0,0.035,0),material(color,0,true),48)
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result

static func ring(parent: Node3D, radius: float, width: float, color: Color, start: float = 0, angle: float = TAU) -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		var a: float = start+angle*i/64.0
		var b: float = start+angle*(i+1)/64.0
		var p := Vector3(cos(a),0,sin(a))
		var q := Vector3(cos(b),0,sin(b))
		triangle(builder,p*radius,q*radius,p*(radius-width))
		triangle(builder,p*(radius-width),q*radius,q*(radius-width))
	var surface := material(color,0,true)
	var result := mesh(parent,builder.commit(),surface,Vector3(0,0.04,0))
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return result
