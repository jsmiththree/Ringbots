class_name CombatOrder
extends RefCounted

## Lengths are frames. The payload is for the caller. CombatClock does not read it.
var startup: int
var active: int
var wind_down: int
var payload: Variant
var on_active_opened: Callable
var on_active_closed: Callable


func _init(
	startup_frames: int,
	active_frames: int,
	wind_down_frames: int,
	action_payload: Variant = null,
	active_opened: Callable = Callable(),
	active_closed: Callable = Callable()
) -> void:
	startup = startup_frames
	active = active_frames
	wind_down = wind_down_frames
	payload = action_payload
	on_active_opened = active_opened
	on_active_closed = active_closed
