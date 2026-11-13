extends Control

const BLINK_SECONDS: float = 1.0

@onready var _prompt: Label = $Center/Column/Prompt

var _blink_time: float = 0.0


func _process(delta: float) -> void:
	_blink_time += delta
	if _blink_time < BLINK_SECONDS:
		return
	_blink_time = 0.0
	var color: Color = _prompt.modulate
	if color.a > 0.0:
		color.a = 0.0
	else:
		color.a = 1.0
	_prompt.modulate = color


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event.button_index != MOUSE_BUTTON_LEFT or not button_event.pressed:
		return
	_start_fight()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ENTER and key_event.keycode != KEY_KP_ENTER:
		return
	_start_fight()


func _start_fight() -> void:
	get_tree().change_scene_to_file("res://scenes/fight.tscn")
