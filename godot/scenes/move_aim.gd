extends Node3D

signal destination_chosen(point: Vector3)

const SEGMENTS: int = 64

var _active: bool = false
var _origin: Vector3 = Vector3.ZERO
var _reach: float = 1.0
var _chosen: Vector3 = Vector3.ZERO
var _has_point: bool = false

@onready var _range_ring: MeshInstance3D = %Range
@onready var _marker: MeshInstance3D = %Marker


func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	_range_ring.mesh = ImmediateMesh.new()
	_marker.mesh = ImmediateMesh.new()
	_range_ring.material_override = material
	_marker.material_override = material
	_range_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_active(enabled: bool) -> void:
	_active = enabled
	if not _active:
		_has_point = false


func set_range(origin: Vector3, reach: float) -> void:
	_origin = origin
	_reach = reach


func _process(_delta: float) -> void:
	_track_cursor()
	_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not _has_point:
		return
	if not (event is InputEventMouseButton):
		return
	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event.button_index != MOUSE_BUTTON_LEFT or not button_event.pressed:
		return
	var flat_origin: Vector3 = _origin
	flat_origin.y = 0.0
	var flat_chosen: Vector3 = _chosen
	flat_chosen.y = 0.0
	if flat_origin.distance_to(flat_chosen) < 0.05:
		return
	destination_chosen.emit(_chosen)
	get_viewport().set_input_as_handled()


func _track_cursor() -> void:
	_has_point = false
	if not _active:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse)
	if absf(ray_direction.y) < 0.0001:
		return
	var distance: float = -ray_origin.y / ray_direction.y
	if distance < 0.0:
		return
	var hit: Vector3 = ray_origin + ray_direction * distance
	hit.y = 0.0
	var flat_origin: Vector3 = _origin
	flat_origin.y = 0.0
	var offset: Vector3 = hit - flat_origin
	var span: float = offset.length()
	if span > _reach and span > 0.0:
		offset = offset * (_reach / span)
	_chosen = flat_origin + offset
	_chosen.y = 0.04
	_has_point = true


func _redraw() -> void:
	var range_mesh: ImmediateMesh = _range_ring.mesh as ImmediateMesh
	var marker_mesh: ImmediateMesh = _marker.mesh as ImmediateMesh
	range_mesh.clear_surfaces()
	marker_mesh.clear_surfaces()
	_range_ring.visible = _active
	_marker.visible = _active and _has_point
	if not _active:
		return
	var ring_at: Vector3 = _origin
	ring_at.y = 0.02
	_draw_ring(range_mesh, ring_at, _reach, 0.07, Color(0.55, 0.9, 1.0, 0.9))
	if not _has_point:
		return
	var from: Vector3 = ring_at
	from.y = 0.04
	_draw_segment(marker_mesh, from, _chosen, 0.06, Color(1.0, 1.0, 1.0, 0.95))
	_draw_ring(marker_mesh, _chosen, 0.35, 0.06, Color(1.0, 0.82, 0.3, 1.0))


func _draw_ring(mesh: ImmediateMesh, at: Vector3, reach: float, width: float, color: Color) -> void:
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	mesh.surface_set_color(color)
	var outer: float = reach
	var inner: float = maxf(reach - width, 0.0)
	for step: int in SEGMENTS + 1:
		var angle: float = TAU * float(step) / float(SEGMENTS)
		var spoke: Vector3 = Vector3(sin(angle), 0.0, cos(angle))
		mesh.surface_add_vertex(at + spoke * outer)
		mesh.surface_add_vertex(at + spoke * inner)
	mesh.surface_end()


func _draw_segment(mesh: ImmediateMesh, from: Vector3, to: Vector3, width: float, color: Color) -> void:
	var delta: Vector3 = to - from
	delta.y = 0.0
	if delta.length() < 0.001:
		return
	var side: Vector3 = Vector3(-delta.z, 0.0, delta.x).normalized() * (width * 0.5)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(from - side)
	mesh.surface_add_vertex(from + side)
	mesh.surface_add_vertex(to - side)
	mesh.surface_add_vertex(to + side)
	mesh.surface_end()
