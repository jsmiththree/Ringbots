extends Node3D

const SUBJECT_GROUP: String = "camera_subject"

@export var distance: float = 12.9
@export var min_distance: float = 3.0
@export var max_distance: float = 28.0
@export var yaw_degrees: float = 0.0
@export var pitch_degrees: float = 35.5
@export var min_pitch_degrees: float = 8.0
@export var max_pitch_degrees: float = 88.0
@export var orbit_sensitivity: float = 0.25
@export var zoom_step: float = 1.25

@onready var _arm: SpringArm3D = %Arm

var _orbiting: bool = false


func _ready() -> void:
	distance = clampf(distance, min_distance, max_distance)
	pitch_degrees = clampf(pitch_degrees, min_pitch_degrees, max_pitch_degrees)
	_aim_arm()


func _process(_delta: float) -> void:
	var subject: Node3D = _subject()
	if subject == null:
		return
	global_position = subject.global_position
	_aim_arm()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_pointer_button(event as InputEventMouseButton)
		return
	if not _orbiting or not (event is InputEventMouseMotion):
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	yaw_degrees -= motion.relative.x * orbit_sensitivity
	pitch_degrees += motion.relative.y * orbit_sensitivity
	pitch_degrees = clampf(pitch_degrees, min_pitch_degrees, max_pitch_degrees)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		return
	_orbiting = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _pointer_button(button_event: InputEventMouseButton) -> void:
	if button_event.button_index == MOUSE_BUTTON_RIGHT:
		_orbiting = button_event.pressed
		if _orbiting:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if not button_event.pressed:
		return
	if button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		distance = clampf(distance - zoom_step, min_distance, max_distance)
	elif button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		distance = clampf(distance + zoom_step, min_distance, max_distance)


func _aim_arm() -> void:
	var yaw: float = deg_to_rad(yaw_degrees)
	var pitch: float = deg_to_rad(pitch_degrees)
	var outward: Vector3 = Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	)
	var z_axis: Vector3 = outward.normalized()
	var x_axis: Vector3 = Vector3.UP.cross(z_axis).normalized()
	var y_axis: Vector3 = z_axis.cross(x_axis)
	_arm.spring_length = distance
	_arm.global_basis = Basis(x_axis, y_axis, z_axis)


func _subject() -> Node3D:
	var found: Array = get_tree().get_nodes_in_group(SUBJECT_GROUP)
	if found.is_empty():
		return null
	return found[0] as Node3D
