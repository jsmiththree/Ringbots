class_name CombatClock
extends RefCounted

const Order = preload("res://combat/combat_order.gd")
const Result = preload("res://combat/combat_result.gd")

## One timeline of participants. Each is waiting, or committed to one action.

enum Phase { WAITING, STU, ADR, WND }

signal paused(waiting_ids: Array)
signal order_accepted(participant_id: int)
signal phase_changed(participant_id: int, phase: int)
signal result_applied(result: Result)
signal returned_to_waiting(participant_id: int)

var _participants: Array = []
var _next_id: int = 1
var _paused: bool = false


func add_participant(blocking: bool) -> int:
	var participant: Participant = Participant.new()
	participant.id = _next_id
	_next_id += 1
	participant.blocking = blocking
	participant.phase = Phase.WAITING
	_participants.append(participant)
	phase_changed.emit(participant.id, Phase.WAITING)
	_update_pause()
	return participant.id


func submit_order(participant_id: int, order: Order) -> bool:
	var participant: Participant = _participant(participant_id)
	if participant == null or order == null:
		return false
	if participant.phase != Phase.WAITING:
		return false
	if order.startup < 0 or order.active < 0 or order.wind_down < 0:
		return false
	participant.token += 1
	participant.order = order
	participant.phase = Phase.STU
	participant.time_left = order.startup
	order_accepted.emit(participant_id)
	phase_changed.emit(participant_id, Phase.STU)
	_update_pause()
	return true


func tick(frames: int = 1) -> void:
	var remaining: int = frames
	while remaining > 0:
		if _paused:
			return
		_advance_frame()
		remaining -= 1


func is_paused() -> bool:
	return _paused


func phase_of(participant_id: int) -> int:
	var participant: Participant = _participant(participant_id)
	if participant == null:
		return -1
	return participant.phase


func time_left(participant_id: int) -> int:
	var participant: Participant = _participant(participant_id)
	if participant == null:
		return 0
	return participant.time_left


func waiting_ids() -> Array:
	var ids: Array = []
	for participant: Participant in _participants:
		if participant.blocking and participant.phase == Phase.WAITING:
			ids.append(participant.id)
	return ids


func _advance_frame() -> void:
	# Every commitment spends this frame before any active window resolves, so two
	# actions that end together see each other still in the frame.
	var spending: Array = []
	for participant: Participant in _participants:
		if participant.phase != Phase.WAITING:
			spending.append(participant)
	for participant: Participant in spending:
		if participant.phase == Phase.WAITING:
			continue
		if participant.time_left > 0:
			participant.time_left -= 1
	for participant: Participant in spending:
		if participant.phase == Phase.WAITING:
			continue
		if participant.time_left == 0:
			_complete_phase(participant)
	_update_pause()


func _complete_phase(participant: Participant) -> void:
	var token: int = participant.token
	match participant.phase:
		Phase.STU:
			_begin_active(participant, token)
		Phase.ADR:
			_end_active(participant, token)
		Phase.WND:
			_to_waiting(participant, token)


func _begin_active(participant: Participant, token: int) -> void:
	if participant.token != token or participant.phase != Phase.STU:
		return
	var order: Order = participant.order
	var active: int = 0 if order == null else order.active
	participant.phase = Phase.ADR
	participant.time_left = maxi(active, 0)
	phase_changed.emit(participant.id, Phase.ADR)
	if order != null:
		_invoke(order.on_active_opened, participant.id)
	if participant.token != token or participant.phase != Phase.ADR:
		return
	if participant.time_left <= 0:
		_end_active(participant, token)


func _end_active(participant: Participant, token: int) -> void:
	if participant.token != token or participant.phase != Phase.ADR:
		return
	var order: Order = participant.order
	if order != null:
		_invoke(order.on_active_closed, participant.id)
	if participant.token != token or participant.phase != Phase.ADR:
		return
	_begin_wind_down(participant, token)


func _begin_wind_down(participant: Participant, token: int) -> void:
	if participant.token != token or participant.phase != Phase.ADR:
		return
	var wind: int = 0
	if participant.order != null:
		wind = participant.order.wind_down
	if wind <= 0:
		_to_waiting(participant, token)
		return
	participant.phase = Phase.WND
	participant.time_left = wind
	phase_changed.emit(participant.id, Phase.WND)


func _to_waiting(participant: Participant, token: int) -> void:
	if participant.token != token:
		return
	if participant.phase == Phase.WAITING and participant.order == null:
		return
	participant.token += 1
	participant.phase = Phase.WAITING
	participant.time_left = 0
	participant.order = null
	phase_changed.emit(participant.id, Phase.WAITING)
	returned_to_waiting.emit(participant.id)


func _invoke(hook: Callable, participant_id: int) -> void:
	if not hook.is_valid():
		return
	_apply_returned(hook.call(self, participant_id))


func _apply_returned(returned: Variant) -> void:
	if returned == null:
		return
	if returned is Result:
		_apply(returned)
		return
	if returned is Array:
		for item: Variant in returned:
			if item is Result:
				_apply(item)
			else:
				push_error("CombatClock hook returned an item that is not a CombatResult")
		return
	push_error("CombatClock hook returned %s" % typeof(returned))


func _apply(result: Result) -> void:
	var participant: Participant = _participant(result.participant_id)
	if participant == null:
		result_applied.emit(result)
		return
	match result.kind:
		Result.Kind.CANCEL:
			if participant.phase != Phase.WAITING:
				_to_waiting(participant, participant.token)
		Result.Kind.REPLACE:
			if result.frames <= 0:
				_to_waiting(participant, participant.token)
			else:
				participant.token += 1
				participant.order = null
				participant.phase = Phase.WND
				participant.time_left = result.frames
				phase_changed.emit(participant.id, Phase.WND)
	result_applied.emit(result)


func _update_pause() -> void:
	var ids: Array = waiting_ids()
	var now_paused: bool = not ids.is_empty()
	if now_paused and not _paused:
		_paused = true
		paused.emit(ids)
	elif not now_paused:
		_paused = false


func _participant(participant_id: int) -> Participant:
	for participant: Participant in _participants:
		if participant.id == participant_id:
			return participant
	return null


class Participant extends RefCounted:
	var id: int = 0
	var blocking: bool = true
	var phase: Phase = Phase.WAITING
	var time_left: int = 0
	var token: int = 0
	var order: Order
