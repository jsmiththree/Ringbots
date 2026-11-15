extends RefCounted

## Stand-in leg profile. A real part fills these fields later.
var travel_rate: float = 1.0
var full_meters: float = 4.0
var max_frames: int = 28
var turn_degrees_per_frame: float = 15.0
## Fraction of the front-to-back drop removed at the rear. One half is the most the arc can take.
var low_end_cut: float = 0.3


func meters_per_frame() -> float:
	if max_frames <= 0:
		return 0.0
	return travel_rate * full_meters / float(max_frames)


func turn_frames(angle_degrees: float) -> int:
	if turn_degrees_per_frame <= 0.0:
		return 0
	var magnitude: float = absf(angle_degrees)
	if magnitude <= 0.01:
		return 0
	return ceili(magnitude / turn_degrees_per_frame)


func reach_at(angle_degrees: float) -> float:
	if max_frames <= 0 or turn_degrees_per_frame <= 0.0:
		return 0.0
	var sliding: float = float(max_frames) - _turn_cost(absf(angle_degrees))
	return meters_per_frame() * maxf(sliding, 0.0)


## Linear turn cost near the facing direction, easing to a flat rear.
## The rear cost keeps (1 - low_end_cut) of the full about-face.
func _turn_cost(magnitude: float) -> float:
	var linear: float = magnitude / turn_degrees_per_frame
	var cut: float = clampf(low_end_cut, 0.0, 0.5)
	if cut <= 0.0 or magnitude <= 0.0:
		return linear
	var full_turn: float = 180.0 / turn_degrees_per_frame
	var t: float = clampf(magnitude / 180.0, 0.0, 1.0)
	var kept: float = 1.0 - cut
	var slope_basis: float = t - 2.0 * t * t + t * t * t
	var end_basis: float = 3.0 * t * t - 2.0 * t * t * t
	return full_turn * (slope_basis + kept * end_basis)


static func shortest_yaw(from_yaw: float, to_yaw: float) -> float:
	var delta: float = fmod(to_yaw - from_yaw, 360.0)
	if delta > 180.0:
		delta -= 360.0
	elif delta < -180.0:
		delta += 360.0
	return delta
