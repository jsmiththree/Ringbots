extends Node3D

const PAN_SPEED: float = 12.0
const FRAME_SHARPNESS: float = 6.0

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
var _focus: Vector3 = Vector3.ZERO
var _ease_target: Vector3 = Vector3.ZERO
var _easing: bool = false


func _ready() -> void:
	distance = clampf(distance, min_distance, max_distance)
	pitch_degrees = clampf(pitch_degrees, min_pitch_degrees, max_pitch_degrees)
	_focus = global_position
	_aim_arm()


func frame_at(point: Vector3) -> void:
	_ease_target = point
	_easing = true


func _process(delta: float) -> void:
	var pan: Vector2 = Vector2.ZERO
	if Controls.held(Controls.CAMERA_RIGHT):
		pan.x += 1.0
	if Controls.held(Controls.CAMERA_LEFT):
		pan.x -= 1.0
	if Controls.held(Controls.CAMERA_FORWARD):
		pan.y += 1.0
	if Controls.held(Controls.CAMERA_BACK):
		pan.y -= 1.0
	if pan.length_squared() > 0.0:
		_easing = false
		if pan.length_squared() > 1.0:
			pan = pan.normalized()
		var yaw: float = deg_to_rad(yaw_degrees)
		var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
		var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
		_focus += (right * pan.x + forward * pan.y) * PAN_SPEED * delta
	if _easing:
		var blend: float = 1.0 - exp(-FRAME_SHARPNESS * delta)
		_focus = _focus.lerp(_ease_target, blend)
		if _focus.distance_to(_ease_target) < 0.02:
			_focus = _ease_target
			_easing = false
	global_position = _focus
	_aim_arm()


func _unhandled_input(event: InputEvent) -> void:
	var orbiting: bool = Controls.held(Controls.CAMERA_ORBIT)
	if orbiting != _orbiting:
		_orbiting = orbiting
		if _orbiting:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Controls.consume_press(Controls.CAMERA_ZOOM_IN):
		distance = clampf(distance - zoom_step, min_distance, max_distance)
	elif Controls.consume_press(Controls.CAMERA_ZOOM_OUT):
		distance = clampf(distance + zoom_step, min_distance, max_distance)
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
