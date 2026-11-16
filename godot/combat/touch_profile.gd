extends RefCounted

const MoveProfile = preload("res://combat/move_profile.gd")

## Stand-in touch action. A real arm part fills these fields later.
## range_meters is measured from the attacker's center. A target connects when its body enters that radius.
## scope_degrees is how far off the chosen facing a target can still be hit. The source names this Scope and gives no angle.
var range_meters: float = 2.0
var scope_degrees: float = 30.0
var pushback_strength: float = 1.0
var startup_frames: int = 10
var active_frames: int = 6
var wind_down_frames: int = 12


static func turn_arc_degrees(startup: int, degrees_per_frame: float) -> float:
	if startup <= 0 or degrees_per_frame <= 0.0:
		return 0.0
	return float(startup) * degrees_per_frame


static func clamp_aim_yaw(facing_degrees: float, desired_degrees: float, arc_degrees: float) -> float:
	if arc_degrees >= 180.0:
		return desired_degrees
	var delta: float = MoveProfile.shortest_yaw(facing_degrees, desired_degrees)
	delta = clampf(delta, -arc_degrees, arc_degrees)
	return wrapf(facing_degrees + delta, -180.0, 180.0)
