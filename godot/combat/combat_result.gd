class_name CombatResult
extends RefCounted

enum Kind { CANCEL, REPLACE }

var kind: Kind
var participant_id: int
## Frames of wind-down before waiting. Used by REPLACE.
var frames: int


static func cancel(target_id: int) -> CombatResult:
	var result: CombatResult = (load("res://combat/combat_result.gd") as GDScript).new()
	result.kind = Kind.CANCEL
	result.participant_id = target_id
	return result


static func replace(target_id: int, wind_down_frames: int) -> CombatResult:
	var result: CombatResult = (load("res://combat/combat_result.gd") as GDScript).new()
	result.kind = Kind.REPLACE
	result.participant_id = target_id
	result.frames = wind_down_frames
	return result
