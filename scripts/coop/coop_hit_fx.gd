extends Node3D
const V = preload("res://scripts/coop/coop_visuals.gd")
var damage: int = 0
var tint: Color = Color("d7abff")
var heavy: bool = false
var perfect: bool = false
var age: float = 0
var label: Label3D
var sparks: MultiMeshInstance3D
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("coop_hit_fx")
	sparks = MultiMeshInstance3D.new()
	sparks.multimesh = MultiMesh.new()
	sparks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var shape := BoxMesh.new()
	shape.size = Vector3(0.06,0.06,0.25 if heavy else 0.16)
	sparks.multimesh.mesh = shape
	sparks.multimesh.instance_count = 8
	var surface: StandardMaterial3D = V.material(tint,1)
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sparks.material_override = surface
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	label = Label3D.new()
	label.text = "PERFECT" if perfect else ("GUARD" if damage == 0 else str(damage))
	label.font_size = 58 if heavy else 46
	label.outline_size = 12
	label.pixel_size = 0.006
	label.modulate = tint.lightened(0.25)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = 0.45
	add_child(label)

func _physics_process(delta: float) -> void:
	age += delta
	label.position.y = 0.45+age*1.7
	label.modulate.a = clampf((0.7-age)*4,0,1)
	for i in range(8):
		var point: Vector3 = Vector3(cos(i*TAU/8),sin(i*3.3)*0.7,sin(i*TAU/8))*age*(4 if heavy else 2.5)
		var basis: Basis = Basis.from_euler(Vector3(i*0.7,i*TAU/8,i*0.3)).scaled(Vector3.ONE*maxf(0.001,1-age/0.3))
		sparks.multimesh.set_instance_transform(i,Transform3D(basis,point))
	if age > 0.7: queue_free()
