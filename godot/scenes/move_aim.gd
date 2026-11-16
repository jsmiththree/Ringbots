extends Node3D

const MoveProfile = preload("res://combat/move_profile.gd")

signal destination_chosen(point: Vector3)

const SEGMENTS: int = 128
const MARKER_RADIUS: float = 0.35
const LINE_WIDTH: float = 0.04
const DASH_LENGTH: float = 0.16
const GAP_LENGTH: float = 0.14
const TARGET_COLOR: Color = Color(1.0, 0.82, 0.3, 1.0)
const REACH_COLOR: Color = Color(1.0, 0.82, 0.3, 0.35)
const BLOCKED_COLOR: Color = Color(1.0, 0.45, 0.08, 1.0)

var _active: bool = false
var _origin: Vector3 = Vector3.ZERO
var _facing_degrees: float = 0.0
var _profile: MoveProfile
var _blocked_centers: PackedVector3Array = PackedVector3Array()
var _blocked_radii: PackedFloat32Array = PackedFloat32Array()
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


func set_move(origin: Vector3, facing_degrees: float, profile: MoveProfile, blocked_centers: PackedVector3Array, blocked_radii: PackedFloat32Array) -> void:
	_origin = origin
	_facing_degrees = facing_degrees
	_profile = profile
	_blocked_centers = blocked_centers
	_blocked_radii = blocked_radii


func _process(_delta: float) -> void:
	_track_cursor()
	_redraw()


func _unhandled_input(_event: InputEvent) -> void:
	if not _active or not _has_point:
		return
	if not Controls.consume_press(Controls.POINTER):
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
	if _profile == null:
		return
	var offset: Vector3 = hit - flat_origin
	var span: float = offset.length()
	if span > 0.0:
		var aim_yaw: float = rad_to_deg(atan2(offset.x, offset.z))
		var turn: float = MoveProfile.shortest_yaw(_facing_degrees, aim_yaw)
		var limit: float = _profile.reach_at(turn)
		if span > limit:
			offset = offset * (limit / span)
	var chosen: Vector3 = flat_origin + offset
	for index: int in _blocked_centers.size():
		var clearance: float = _blocked_radii[index] + MARKER_RADIUS
		chosen = stop_before(flat_origin, chosen, _blocked_centers[index], clearance)
	chosen.y = 0.04
	_chosen = chosen
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
	ring_at.y = 0.05
	_draw_reach(range_mesh, ring_at, LINE_WIDTH, REACH_COLOR)
	_draw_blocked(range_mesh)
	if not _has_point:
		return
	var from: Vector3 = ring_at
	from.y = 0.04
	var toward: Vector3 = _chosen - from
	toward.y = 0.0
	var span: float = toward.length()
	if span > MARKER_RADIUS:
		var end: Vector3 = _chosen - toward * (MARKER_RADIUS / span)
		end.y = _chosen.y
		var path: PackedVector3Array = PackedVector3Array()
		path.append(from)
		path.append(end)
		_draw_dashed(marker_mesh, path, false, LINE_WIDTH, TARGET_COLOR)
	_draw_ring(marker_mesh, _chosen, MARKER_RADIUS, 0.06, TARGET_COLOR)


static func stop_before(start: Vector3, end: Vector3, center: Vector3, radius: float) -> Vector3:
	var flat_start: Vector3 = start
	flat_start.y = 0.0
	var flat_end: Vector3 = end
	flat_end.y = 0.0
	var flat_center: Vector3 = center
	flat_center.y = 0.0
	var offset: Vector3 = flat_end - flat_start
	var span: float = offset.length()
	if span < 0.0001 or radius <= 0.0:
		return end
	var direction: Vector3 = offset / span
	var from_start: Vector3 = flat_center - flat_start
	var along: float = from_start.dot(direction)
	var closest_sq: float = from_start.length_squared() - along * along
	var radius_sq: float = radius * radius
	if closest_sq >= radius_sq:
		return end
	var half_chord: float = sqrt(maxf(radius_sq - closest_sq, 0.0))
	var entry: float = along - half_chord
	if entry <= 0.0 or entry >= span:
		return end
	var stopped: Vector3 = flat_start + direction * entry
	stopped.y = end.y
	return stopped


func _draw_blocked(mesh: ImmediateMesh) -> void:
	for index: int in _blocked_centers.size():
		var radius: float = _blocked_radii[index]
		if radius <= 0.0:
			continue
		var center: Vector3 = _blocked_centers[index]
		center.y = 0.06
		var points: PackedVector3Array = PackedVector3Array()
		points.resize(SEGMENTS)
		for step: int in SEGMENTS:
			var angle: float = TAU * float(step) / float(SEGMENTS)
			points[step] = center + Vector3(sin(angle), 0.0, cos(angle)) * radius
		_draw_dashed(mesh, points, true, LINE_WIDTH, BLOCKED_COLOR)


func _draw_reach(mesh: ImmediateMesh, at: Vector3, width: float, color: Color) -> void:
	if _profile == null:
		return
	var points: PackedVector3Array = PackedVector3Array()
	points.resize(SEGMENTS)
	for step: int in SEGMENTS:
		var relative: float = 360.0 * float(step) / float(SEGMENTS)
		var turn: float = MoveProfile.shortest_yaw(0.0, relative)
		var reach: float = _profile.reach_at(turn)
		var world_yaw: float = deg_to_rad(_facing_degrees + relative)
		var spoke: Vector3 = Vector3(sin(world_yaw), 0.0, cos(world_yaw))
		points[step] = at + spoke * reach
	_draw_dashed(mesh, points, true, width, color)


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


func _draw_dashed(mesh: ImmediateMesh, points: PackedVector3Array, closed: bool, width: float, color: Color) -> void:
	var count: int = points.size()
	if count < 2:
		return
	var edges: int = count if closed else count - 1
	var lengths: PackedFloat32Array = PackedFloat32Array()
	lengths.resize(edges)
	var total: float = 0.0
	for edge: int in edges:
		var next_index: int = (edge + 1) % count
		var edge_length: float = points[edge].distance_to(points[next_index])
		lengths[edge] = edge_length
		total += edge_length
	if total < 0.001:
		return
	var dash: float = DASH_LENGTH
	var gap: float = GAP_LENGTH
	if closed:
		var period: float = dash + gap
		var repeats: int = maxi(1, roundi(total / period))
		var fitted: float = total / float(repeats)
		dash = fitted * (DASH_LENGTH / period)
		gap = fitted - dash
	var half_width: float = width * 0.5
	var remaining: float = dash
	var drawing: bool = true
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_set_color(color)
	for edge: int in edges:
		var next_index: int = (edge + 1) % count
		var start: Vector3 = points[edge]
		var finish: Vector3 = points[next_index]
		var edge_length: float = lengths[edge]
		if edge_length < 0.0001:
			continue
		var walked: float = 0.0
		while walked < edge_length - 0.00005:
			var step_length: float = minf(edge_length - walked, remaining)
			if drawing and step_length > 0.0001:
				var start_mark: Vector3 = start.lerp(finish, walked / edge_length)
				var end_mark: Vector3 = start.lerp(finish, (walked + step_length) / edge_length)
				_add_quad(mesh, start_mark, end_mark, half_width)
			walked += step_length
			remaining -= step_length
			if remaining <= 0.00005:
				drawing = not drawing
				remaining = dash if drawing else gap
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
