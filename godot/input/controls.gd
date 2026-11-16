extends Node

## Bindings this project defines. The Godot input map is not used.

const CAMERA_FORWARD: int = 0
const CAMERA_BACK: int = 1
const CAMERA_LEFT: int = 2
const CAMERA_RIGHT: int = 3
const CAMERA_ORBIT: int = 4
const CAMERA_ZOOM_IN: int = 5
const CAMERA_ZOOM_OUT: int = 6
const POINTER: int = 7
const CONFIRM: int = 8

var _held: Dictionary = {}
var _pressed: Dictionary = {}


func held(control: int) -> bool:
	return bool(_held.get(control, false))


func consume_press(control: int) -> bool:
	if not bool(_pressed.get(control, false)):
		return false
	_pressed[control] = false
	return true


func _input(event: InputEvent) -> void:
	var control: int = _control_for(event)
	if control < 0:
		return
	var down: bool = event.is_pressed()
	if _oneshot(control):
		if down and not event.is_echo():
			_pressed[control] = true
		return
	if event.is_echo():
		return
	_held[control] = down


func _process(_delta: float) -> void:
	_pressed.clear()


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		return
	_held.clear()
	_pressed.clear()


func _oneshot(control: int) -> bool:
	return control == CAMERA_ZOOM_IN or control == CAMERA_ZOOM_OUT or control == POINTER or control == CONFIRM


func _control_for(event: InputEvent) -> int:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		var code: int = key_event.physical_keycode
		if code == KEY_NONE:
			code = key_event.keycode
		return _key_control(code)
	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event as InputEventMouseButton
		return _button_control(button_event.button_index)
	return -1


func _key_control(code: int) -> int:
	match code:
		KEY_W:
			return CAMERA_FORWARD
		KEY_S:
			return CAMERA_BACK
		KEY_A:
			return CAMERA_LEFT
		KEY_D:
			return CAMERA_RIGHT
		KEY_ENTER, KEY_KP_ENTER:
			return CONFIRM
		_:
			return -1


func _button_control(button_index: int) -> int:
	match button_index:
		MOUSE_BUTTON_RIGHT:
			return CAMERA_ORBIT
		MOUSE_BUTTON_WHEEL_UP:
			return CAMERA_ZOOM_IN
		MOUSE_BUTTON_WHEEL_DOWN:
			return CAMERA_ZOOM_OUT
		MOUSE_BUTTON_LEFT:
			return POINTER
		_:
			return -1
