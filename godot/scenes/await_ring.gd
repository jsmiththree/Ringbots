extends Node3D

const LINE_WIDTH: float = 0.04
const RING_COLOR: Color = Color(0.35, 0.92, 0.4, 1.0)

var _center: Vector3 = Vector3.ZERO
var _radius: float = 0.0

@onready var _ring: MeshInstance3D = %Ring


func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	_ring.mesh = ImmediateMesh.new()
	_ring.material_override = material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_ring(center: Vector3, radius: float) -> void:
	_center = center
	_radius = radius
	_redraw()


func _redraw() -> void:
	var mesh: ImmediateMesh = _ring.mesh as ImmediateMesh
	mesh.clear_surfaces()
	_ring.visible = _radius > 0.0
	if _radius <= 0.0:
		return
	var at: Vector3 = _center
	at.y = 0.04
	var steps: int = 48
	var outer: float = _radius + LINE_WIDTH * 0.5
	var inner: float = maxf(_radius - LINE_WIDTH * 0.5, 0.0)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	mesh.surface_set_color(RING_COLOR)
	for step: int in steps + 1:
		var angle: float = TAU * float(step) / float(steps)
		var spoke: Vector3 = Vector3(sin(angle), 0.0, cos(angle))
		mesh.surface_add_vertex(at + spoke * outer)
		mesh.surface_add_vertex(at + spoke * inner)
	mesh.surface_end()
