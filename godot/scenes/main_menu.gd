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


func _gui_input(_event: InputEvent) -> void:
	if Controls.consume_press(Controls.POINTER):
		_start_fight()


func _unhandled_input(_event: InputEvent) -> void:
	if Controls.consume_press(Controls.CONFIRM):
		_start_fight()


func _start_fight() -> void:
	get_tree().change_scene_to_file("res://scenes/fight.tscn")
