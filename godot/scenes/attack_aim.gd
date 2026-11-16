extends Node3D

const TouchProfile = preload("res://combat/touch_profile.gd")

signal direction_chosen(aim_yaw: float)

const ARC_STEP_DEGREES: float = 6.0
const LINE_WIDTH: float = 0.04
const INNER_RADIUS: float = 0.55
const DASH_LENGTH: float = 0.12
const GAP_LENGTH: float = 0.1
const ARROW_LENGTH: float = 0.28
const ARROW_HALF_WIDTH: float = 0.16
const INTENT_RING_GAP: float = 0.14
const RANGE_COLOR: Color = Color(0.95, 0.22, 0.18, 0.25)
const ATTACK_FILL: Color = Color(0.95, 0.22, 0.18, 0.25)
const ATTACK_COLOR: Color = Color(0.95, 0.22, 0.18, 1.0)

var _active: bool = false
var _origin: Vector3 = Vector3.ZERO
var _facing_degrees: float = 0.0
var _range_meters: float = 2.0
var _turn_arc_degrees: float = 0.0
var _scope_degrees: float = 0.0
var _aim_yaw: float = 0.0
var _target_center: Vector3 = Vector3.ZERO
var _target_radius: float = 0.0
var _full_intent: bool = false

@onready var _cone: MeshInstance3D = %Cone


func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	_cone.mesh = ImmediateMesh.new()
	_cone.material_override = material
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_active(enabled: bool) -> void:
	_active = enabled


func aim_yaw() -> float:
	_track_cursor()
	return _aim_yaw


func set_target(center: Vector3, radius: float, full_intent: bool) -> void:
	_target_center = center
	_target_radius = radius
	_full_intent = full_intent


func set_attack(origin: Vector3, facing_degrees: float, range_meters: float, turn_arc_degrees: float, scope_degrees: float) -> void:
	_origin = origin
	_facing_degrees = facing_degrees
	_range_meters = range_meters
	_turn_arc_degrees = turn_arc_degrees
	_scope_degrees = scope_degrees


func _process(_delta: float) -> void:
	_track_cursor()
	_redraw()


func _unhandled_input(_event: InputEvent) -> void:
	if not _active:
		return
	if not Controls.consume_press(Controls.POINTER):
		return
	direction_chosen.emit(_aim_yaw)
	get_viewport().set_input_as_handled()


func _track_cursor() -> void:
	_aim_yaw = _facing_degrees
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
	if offset.length() < 0.05:
		return
	var desired: float = rad_to_deg(atan2(offset.x, offset.z))
	_aim_yaw = TouchProfile.clamp_aim_yaw(_facing_degrees, desired, _turn_arc_degrees)


func _redraw() -> void:
	var mesh: ImmediateMesh = _cone.mesh as ImmediateMesh
	mesh.clear_surfaces()
	_cone.visible = _active
	if not _active:
		return
	var at: Vector3 = _origin
	at.y = 0.05
	_draw_cone(mesh, at, _facing_degrees, _turn_arc_degrees, true, RANGE_COLOR)
	at.y = 0.07
	_draw_filled_cone(mesh, at, _aim_yaw, _scope_degrees, ATTACK_FILL)
	at.y = 0.08
	_draw_center(mesh, at, _aim_yaw, ATTACK_COLOR)
	_draw_ring(mesh, _target_center, _target_radius, ATTACK_COLOR)
	if _full_intent:
		_draw_ring(mesh, _target_center, _target_radius + INTENT_RING_GAP, ATTACK_COLOR)


func _draw_filled_cone(mesh: ImmediateMesh, at: Vector3, center_yaw: float, half_degrees: float, color: Color) -> void:
	if _range_meters <= INNER_RADIUS:
		return
	var half: float = maxf(half_degrees, 0.0)
	if half <= 0.0:
		return
	var left_yaw: float = center_yaw - half
	var right_yaw: float = center_yaw + half
	var steps: int = maxi(1, ceili(absf(right_yaw - left_yaw) / ARC_STEP_DEGREES))
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(color)
	for step: int in steps:
		var yaw_a: float = lerpf(left_yaw, right_yaw, float(step) / float(steps))
		var yaw_b: float = lerpf(left_yaw, right_yaw, float(step + 1) / float(steps))
		var inner_a: Vector3 = at + _direction(yaw_a) * INNER_RADIUS
		var outer_a: Vector3 = at + _direction(yaw_a) * _range_meters
		var inner_b: Vector3 = at + _direction(yaw_b) * INNER_RADIUS
		var outer_b: Vector3 = at + _direction(yaw_b) * _range_meters
		mesh.surface_add_vertex(inner_a)
		mesh.surface_add_vertex(outer_a)
		mesh.surface_add_vertex(outer_b)
		mesh.surface_add_vertex(inner_a)
		mesh.surface_add_vertex(outer_b)
		mesh.surface_add_vertex(inner_b)
	mesh.surface_end()


func _draw_cone(mesh: ImmediateMesh, at: Vector3, center_yaw: float, half_degrees: float, dotted: bool, color: Color) -> void:
	if _range_meters <= INNER_RADIUS:
		return
	var half: float = maxf(half_degrees, 0.0)
	var left_yaw: float = center_yaw - half
	var right_yaw: float = center_yaw + half
	_draw_ray(mesh, at, left_yaw, dotted, color)
	_draw_ray(mesh, at, right_yaw, dotted, color)
	_draw_arc(mesh, at, left_yaw, right_yaw, dotted, color)


func _draw_ring(mesh: ImmediateMesh, center: Vector3, radius: float, color: Color) -> void:
	if radius <= 0.0:
		return
	var at: Vector3 = center
	at.y = 0.06
	var steps: int = 48
	var points: PackedVector3Array = PackedVector3Array()
	points.resize(steps + 1)
	for step: int in steps + 1:
		var angle: float = TAU * float(step) / float(steps)
		points[step] = at + Vector3(sin(angle), 0.0, cos(angle)) * radius
	_draw_solid(mesh, points, color)


func _draw_center(mesh: ImmediateMesh, at: Vector3, yaw_degrees: float, color: Color) -> void:
	var direction: Vector3 = _direction(yaw_degrees)
	var side: Vector3 = Vector3(-direction.z, 0.0, direction.x)
	var points: PackedVector3Array = PackedVector3Array()
	points.append(at + direction * INNER_RADIUS)
	points.append(at + direction * _range_meters)
	_draw_solid(mesh, points, color)
	var neck: Vector3 = at + direction * _range_meters
	var tip: Vector3 = at + direction * (_range_meters + ARROW_LENGTH)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(tip)
	mesh.surface_add_vertex(neck + side * ARROW_HALF_WIDTH)
	mesh.surface_add_vertex(neck - side * ARROW_HALF_WIDTH)
	mesh.surface_end()


func _draw_ray(mesh: ImmediateMesh, at: Vector3, yaw_degrees: float, dotted: bool, color: Color) -> void:
	var points: PackedVector3Array = PackedVector3Array()
	points.append(at + _direction(yaw_degrees) * INNER_RADIUS)
	points.append(at + _direction(yaw_degrees) * _range_meters)
	if dotted:
		_draw_dashed(mesh, points, color)
	else:
		_draw_solid(mesh, points, color)


func _draw_arc(mesh: ImmediateMesh, at: Vector3, from_yaw: float, to_yaw: float, dotted: bool, color: Color) -> void:
	var span: float = absf(to_yaw - from_yaw)
	var steps: int = maxi(1, ceili(span / ARC_STEP_DEGREES))
	var points: PackedVector3Array = PackedVector3Array()
	points.resize(steps + 1)
	for step: int in steps + 1:
		var yaw: float = from_yaw
		if steps > 0:
			yaw = lerpf(from_yaw, to_yaw, float(step) / float(steps))
		points[step] = at + _direction(yaw) * _range_meters
	if dotted:
		_draw_dashed(mesh, points, color)
	else:
		_draw_solid(mesh, points, color)


func _direction(yaw_degrees: float) -> Vector3:
	var yaw: float = deg_to_rad(yaw_degrees)
	return Vector3(sin(yaw), 0.0, cos(yaw))


func _draw_solid(mesh: ImmediateMesh, points: PackedVector3Array, color: Color) -> void:
	if points.size() < 2:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(color)
	for index: int in points.size() - 1:
		_add_quad(mesh, points[index], points[index + 1], LINE_WIDTH * 0.5)
	mesh.surface_end()


func _draw_dashed(mesh: ImmediateMesh, points: PackedVector3Array, color: Color) -> void:
	var count: int = points.size()
	if count < 2:
		return
	var total: float = 0.0
	var lengths: PackedFloat32Array = PackedFloat32Array()
	lengths.resize(count - 1)
	for index: int in count - 1:
		var edge_length: float = points[index].distance_to(points[index + 1])
		lengths[index] = edge_length
		total += edge_length
	if total < 0.001:
		return
	var remaining: float = DASH_LENGTH
	var drawing: bool = true
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(color)
	for index: int in count - 1:
		var start: Vector3 = points[index]
		var finish: Vector3 = points[index + 1]
		var edge_length: float = lengths[index]
		if edge_length < 0.0001:
			continue
		var walked: float = 0.0
		while walked < edge_length - 0.00005:
			var step_length: float = minf(edge_length - walked, remaining)
			if drawing and step_length > 0.0001:
				var start_mark: Vector3 = start.lerp(finish, walked / edge_length)
				var end_mark: Vector3 = start.lerp(finish, (walked + step_length) / edge_length)
				_add_quad(mesh, start_mark, end_mark, LINE_WIDTH * 0.5)
			walked += step_length
			remaining -= step_length
			if remaining <= 0.00005:
				drawing = not drawing
				remaining = DASH_LENGTH if drawing else GAP_LENGTH
	mesh.surface_end()


func _add_quad(mesh: ImmediateMesh, start: Vector3, finish: Vector3, half_width: float) -> void:
	var delta: Vector3 = finish - start
	delta.y = 0.0
	if delta.length() < 0.001:
		return
	var side: Vector3 = Vector3(-delta.z, 0.0, delta.x).normalized() * half_width
	var left_start: Vector3 = start - side
	var right_start: Vector3 = start + side
	var left_finish: Vector3 = finish - side
	var right_finish: Vector3 = finish + side
	mesh.surface_add_vertex(left_start)
	mesh.surface_add_vertex(right_start)
	mesh.surface_add_vertex(right_finish)
	mesh.surface_add_vertex(left_start)
	mesh.surface_add_vertex(right_finish)
	mesh.surface_add_vertex(left_finish)
