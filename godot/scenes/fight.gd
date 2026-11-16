extends Node3D

const Clock = preload("res://combat/combat_clock.gd")
const Order = preload("res://combat/combat_order.gd")
const MoveProfile = preload("res://combat/move_profile.gd")
const MoveInput = preload("res://combat/move_input.gd")
const ActionKind = preload("res://combat/action_kind.gd")
const TouchProfile = preload("res://combat/touch_profile.gd")
const TouchInput = preload("res://combat/touch_input.gd")
const ReactionInput = preload("res://combat/reaction_input.gd")
const PushbackProfile = preload("res://combat/pushback_profile.gd")
const GRID: Texture2D = preload("res://assets/textures/debug_grid.png")
const PLAY_PAUSE: Texture2D = preload("res://assets/sprites/play_pause.png")
const Aim = preload("res://scenes/move_aim.gd")
const AttackAim = preload("res://scenes/attack_aim.gd")
const STATE_FRAME: int = 32
const SAME_CENTERING_DEGREES: float = 0.01
const FLOOR_SIZE: float = 16.0

var _clock: Clock
var _fighters: Array = []
var _menu_step: String = ""
var _pause_icon: AtlasTexture
var _play_icon: AtlasTexture

@onready var _state: TextureRect = %Icon
@onready var _choice: Label = %Choice
@onready var _options: HBoxContainer = %Options
@onready var _aim: Aim = %MoveAim
@onready var _attack_aim: AttackAim = %AttackAim


func _ready() -> void:
	_pause_icon = _sheet_frame(STATE_FRAME)
	_play_icon = _sheet_frame(0)
	_aim.destination_chosen.connect(_confirm_move)
	_attack_aim.direction_chosen.connect(_confirm_touch)
	_add_room()
	_clock = Clock.new()
	_fighters.append(_add_fighter("P1", Vector3(0, 0.5, 0), Color(0.25, 0.75, 1.0), true))
	var sandbag: Fighter = _add_fighter("Sandbag", Vector3(0, 0.5, 3), Color.WHITE, false)
	sandbag.yaw_degrees = 180.0
	_fighters.append(sandbag)
	_refresh_view()


func _physics_process(_delta: float) -> void:
	if not _clock.is_paused():
		_step_moves()
		_clock.tick(1)
	_refresh_view()


func _choose_part(part: String) -> void:
	var fighter: Fighter = _fighters[0]
	if _clock.phase_of(fighter.id) != Clock.Phase.WAITING:
		return
	fighter.part = part
	_refresh_view()


func _clear_part() -> void:
	var fighter: Fighter = _fighters[0]
	fighter.part = ""
	_refresh_view()


func _choose_action(action: String) -> void:
	if action == "move":
		_begin_aim()
	elif action == "touch":
		_begin_touch(_fighters[0])
	_refresh_view()


func _begin_aim() -> void:
	var fighter: Fighter = _fighters[0]
	if fighter.part != "legs":
		return
	if _clock.phase_of(fighter.id) != Clock.Phase.WAITING:
		return
	fighter.aiming = true


func _cancel_aim() -> void:
	_fighters[0].aiming = false
	_fighters[0].aiming_touch = false
	_refresh_view()


func _confirm_move(point: Vector3) -> void:
	var fighter: Fighter = _fighters[0]
	if not fighter.aiming:
		return
	if _clock.phase_of(fighter.id) != Clock.Phase.WAITING:
		return
	var flat_start: Vector3 = fighter.base_position
	flat_start.y = 0.0
	var flat_end: Vector3 = point
	flat_end.y = 0.0
	var offset: Vector3 = flat_end - flat_start
	var distance: float = offset.length()
	if distance < 0.05:
		return
	var profile: MoveProfile = fighter.move_profile
	var step_length: float = profile.meters_per_frame()
	if step_length <= 0.0:
		return
	var aim_yaw: float = rad_to_deg(atan2(offset.x, offset.z))
	var turn: float = MoveProfile.shortest_yaw(fighter.yaw_degrees, aim_yaw)
	var limit: float = profile.reach_at(turn)
	if limit < 0.05:
		return
	if distance > limit:
		offset = offset * (limit / distance)
		distance = limit
		flat_end = flat_start + offset
	flat_end = _clear_of_fighters(fighter, flat_start, flat_end)
	offset = flat_end - flat_start
	distance = offset.length()
	if distance < 0.05:
		return
	var input: MoveInput = MoveInput.new()
	input.kind = ActionKind.Kind.MOVE
	input.part = fighter.part
	input.destination = Vector3(flat_end.x, 0.0, flat_end.z)
	_submit_move(fighter, input)
	_refresh_view()


func _submit_move(fighter: Fighter, input: MoveInput) -> void:
	var profile: MoveProfile = fighter.move_profile
	if profile == null:
		return
	var step_length: float = profile.meters_per_frame()
	if step_length <= 0.0:
		return
	var flat_start: Vector3 = fighter.base_position
	flat_start.y = 0.0
	var flat_end: Vector3 = input.destination
	flat_end.y = 0.0
	var offset: Vector3 = flat_end - flat_start
	var distance: float = offset.length()
	if distance < 0.05:
		return
	var aim_yaw: float = rad_to_deg(atan2(offset.x, offset.z))
	var turn: float = MoveProfile.shortest_yaw(fighter.yaw_degrees, aim_yaw)
	var turning: int = profile.turn_frames(turn)
	var travel_frames: int = ceili(distance / step_length)
	if travel_frames <= 0:
		return
	var label: String = "%s move" % input.part
	var order: Order = Order.new(turning, travel_frames, 0, input)
	if not _clock.submit_order(fighter.id, order):
		return
	fighter.action_label = label
	fighter.part = ""
	fighter.aiming = false
	fighter.aiming_touch = false


func _begin_touch(fighter: Fighter) -> void:
	if fighter.part != "left arm" and fighter.part != "right arm":
		return
	if _clock.phase_of(fighter.id) != Clock.Phase.WAITING:
		return
	var touch: TouchProfile = fighter.right_touch if fighter.part == "right arm" else fighter.left_touch
	if touch == null:
		return
	fighter.swing = touch
	fighter.aiming_touch = true


func _confirm_touch(aim_yaw: float) -> void:
	var fighter: Fighter = _fighters[0]
	if not fighter.aiming_touch or fighter.swing == null or fighter.move_profile == null:
		return
	if _clock.phase_of(fighter.id) != Clock.Phase.WAITING:
		return
	var touch: TouchProfile = fighter.swing
	var arc: float = TouchProfile.turn_arc_degrees(touch.startup_frames, fighter.move_profile.turn_degrees_per_frame)
	var yaw: float = TouchProfile.clamp_aim_yaw(fighter.yaw_degrees, aim_yaw, arc)
	var input: TouchInput = TouchInput.new()
	input.kind = ActionKind.Kind.TOUCH
	input.part = fighter.part
	input.aim_yaw = yaw
	_submit_touch(fighter, input)


func _submit_touch(fighter: Fighter, input: TouchInput) -> void:
	var touch: TouchProfile = _touch_profile(fighter, input.part)
	if touch == null or fighter.move_profile == null:
		return
	var label: String = "%s touch" % input.part
	var order: Order = Order.new(touch.startup_frames, touch.active_frames, touch.wind_down_frames, input, Callable(self, "_touch_opened"))
	if not _clock.submit_order(fighter.id, order):
		return
	fighter.aiming_touch = false
	fighter.action_label = label
	fighter.part = ""


func _touch_opened(combat_clock: Clock, participant_id: int) -> Variant:
	var attacker: Fighter = _fighter_by_id(participant_id)
	var input: TouchInput = _touch_input_from(combat_clock.payload_of(participant_id))
	if attacker == null or input == null:
		return null
	var touch: TouchProfile = _touch_profile(attacker, input.part)
	if touch == null:
		return null
	var target: Fighter = _select_touch_target(attacker, touch, input.aim_yaw)
	if target != null:
		_start_pushback(combat_clock, attacker, target, touch.pushback_strength)
	return null


func _touch_input_from(value: Variant) -> TouchInput:
	if value == null or not (value is RefCounted):
		return null
	if (value as RefCounted).get_script() != TouchInput:
		return null
	return value as TouchInput


func _touch_profile(fighter: Fighter, part_name: String) -> TouchProfile:
	if part_name == "left arm":
		return fighter.left_touch
	if part_name == "right arm":
		return fighter.right_touch
	return null


func _select_touch_target(attacker: Fighter, touch: TouchProfile, aim_yaw: float) -> Fighter:
	var chosen: Fighter = null
	var chosen_off: float = 0.0
	var chosen_distance: float = 0.0
	for other: Fighter in _fighters:
		if other == attacker:
			continue
		if not _in_touch_scope(attacker, other, touch, aim_yaw):
			continue
		var off_center: float = _off_center(attacker, other, aim_yaw)
		var gap: float = _flat_offset(attacker, other).length()
		var nearer_center: bool = chosen == null or off_center < chosen_off - SAME_CENTERING_DEGREES
		var same_center: bool = chosen != null and absf(off_center - chosen_off) <= SAME_CENTERING_DEGREES
		if nearer_center or (same_center and gap < chosen_distance):
			chosen = other
			chosen_off = off_center
			chosen_distance = gap
	return chosen


func _in_touch_scope(attacker: Fighter, target: Fighter, touch: TouchProfile, facing_degrees: float) -> bool:
	var offset: Vector3 = _flat_offset(attacker, target)
	if offset.length() > touch.range_meters + target.body_radius:
		return false
	if offset.length() < 0.001:
		return true
	return _off_center(attacker, target, facing_degrees) <= touch.scope_degrees


func _off_center(attacker: Fighter, target: Fighter, aim_yaw: float) -> float:
	var offset: Vector3 = _flat_offset(attacker, target)
	if offset.length() < 0.001:
		return 0.0
	var toward: float = rad_to_deg(atan2(offset.x, offset.z))
	return absf(MoveProfile.shortest_yaw(aim_yaw, toward))


func _flat_offset(attacker: Fighter, target: Fighter) -> Vector3:
	var offset: Vector3 = target.base_position - attacker.base_position
	offset.y = 0.0
	return offset


func _start_pushback(combat_clock: Clock, attacker: Fighter, target: Fighter, strength: float) -> void:
	var profile: PushbackProfile = target.pushback_profile
	if profile == null or strength <= 0.0 or profile.meters_per_strength <= 0.0 or profile.meters_per_frame <= 0.0:
		return
	var push_meters: float = strength * profile.meters_per_strength
	var away: Vector3 = target.base_position - attacker.base_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		var yaw: float = deg_to_rad(attacker.yaw_degrees)
		away = Vector3(sin(yaw), 0.0, cos(yaw))
	else:
		away = away.normalized()
	var frames: int = ceili(push_meters / profile.meters_per_frame)
	if frames <= 0:
		return
	var input: ReactionInput = ReactionInput.new()
	input.kind = ActionKind.Kind.REACTION
	input.destination = target.base_position + away * push_meters
	var order: Order = Order.new(0, frames, profile.wind_down_frames, input)
	if not combat_clock.submit_order(target.id, order):
		return
	target.action_label = "pushback"
	target.part = ""
	target.aiming = false
	target.aiming_touch = false


func _fighter_by_id(participant_id: int) -> Fighter:
	for fighter: Fighter in _fighters:
		if fighter.id == participant_id:
			return fighter
	return null


func _move_input_from(value: Variant) -> MoveInput:
	if value == null or not (value is RefCounted):
		return null
	if (value as RefCounted).get_script() != MoveInput:
		return null
	return value as MoveInput


func _reaction_input_from(value: Variant) -> ReactionInput:
	if value == null or not (value is RefCounted):
		return null
	if (value as RefCounted).get_script() != ReactionInput:
		return null
	return value as ReactionInput


func _step_moves() -> void:
	for fighter: Fighter in _fighters:
		var phase: int = _clock.phase_of(fighter.id)
		var payload: Variant = _clock.payload_of(fighter.id)
		var move_input: MoveInput = _move_input_from(payload)
		if move_input != null and fighter.move_profile != null:
			if phase == Clock.Phase.STU:
				_step_turn(fighter, _heading_toward(fighter, move_input.destination), fighter.move_profile.turn_degrees_per_frame)
			elif phase == Clock.Phase.ADR:
				_step_slide(fighter, move_input.destination, fighter.move_profile.meters_per_frame(), true)
			continue
		var touch_input: TouchInput = _touch_input_from(payload)
		if touch_input != null and fighter.move_profile != null and phase == Clock.Phase.STU:
			_step_turn(fighter, touch_input.aim_yaw, fighter.move_profile.turn_degrees_per_frame)
			continue
		var reaction: ReactionInput = _reaction_input_from(payload)
		if reaction != null and fighter.pushback_profile != null and phase == Clock.Phase.ADR:
			_step_slide(fighter, reaction.destination, fighter.pushback_profile.meters_per_frame, false)


func _heading_toward(fighter: Fighter, destination: Vector3) -> float:
	var offset: Vector3 = destination - fighter.base_position
	offset.y = 0.0
	if offset.length() < 0.001:
		return fighter.yaw_degrees
	return rad_to_deg(atan2(offset.x, offset.z))


func _step_turn(fighter: Fighter, aim_yaw: float, degrees_per_frame: float) -> void:
	if _clock.time_left(fighter.id) <= 0:
		return
	var remaining_yaw: float = MoveProfile.shortest_yaw(fighter.yaw_degrees, aim_yaw)
	if absf(remaining_yaw) <= degrees_per_frame:
		fighter.yaw_degrees = aim_yaw
		return
	if remaining_yaw > 0.0:
		fighter.yaw_degrees += degrees_per_frame
	else:
		fighter.yaw_degrees -= degrees_per_frame
	fighter.yaw_degrees = wrapf(fighter.yaw_degrees, -180.0, 180.0)


func _step_slide(fighter: Fighter, destination: Vector3, meters_per_frame: float, face_travel: bool) -> void:
	var next: Vector3 = fighter.base_position
	var end_point: Vector3 = Vector3(destination.x, next.y, destination.z)
	var offset: Vector3 = end_point - next
	offset.y = 0.0
	var distance: float = offset.length()
	if distance < 0.001 or meters_per_frame <= 0.0:
		return
	var heading: float = rad_to_deg(atan2(offset.x, offset.z))
	if distance <= meters_per_frame:
		next.x = end_point.x
		next.z = end_point.z
	else:
		next += offset / distance * meters_per_frame
	fighter.base_position = next
	if face_travel:
		fighter.yaw_degrees = heading


func _refresh_view() -> void:
	for fighter: Fighter in _fighters:
		var shown: Vector3 = fighter.base_position
		var phase: int = _clock.phase_of(fighter.id)
		var active_frames: int = _clock.active_of(fighter.id)
		if phase == Clock.Phase.ADR and _touch_input_from(_clock.payload_of(fighter.id)) != null and active_frames > 0:
			var remaining: float = float(_clock.time_left(fighter.id))
			var along: float = 1.0 - remaining / float(active_frames)
			var yaw: float = deg_to_rad(fighter.yaw_degrees)
			shown += Vector3(sin(yaw), 0.0, cos(yaw)) * sin(along * PI) * 0.6
		fighter.mesh.position = shown
		fighter.mesh.rotation_degrees = Vector3(0.0, fighter.yaw_degrees, 0.0)
		fighter.label.text = "%s  %s" % [fighter.who, _fighter_line(fighter, phase)]
	var lead: Fighter = _fighters[0]
	var lead_phase: int = _clock.phase_of(lead.id)
	var aiming: bool = lead.aiming and lead_phase == Clock.Phase.WAITING
	var aiming_touch: bool = lead.aiming_touch and lead_phase == Clock.Phase.WAITING and lead.swing != null and lead.move_profile != null
	_aim.set_active(aiming)
	_attack_aim.set_active(aiming_touch)
	var targeted: Fighter = null
	if aiming_touch:
		var attack_origin: Vector3 = lead.base_position
		attack_origin.y = 0.0
		var arc: float = TouchProfile.turn_arc_degrees(lead.swing.startup_frames, lead.move_profile.turn_degrees_per_frame)
		_attack_aim.set_attack(attack_origin, lead.yaw_degrees, lead.swing.range_meters, arc, lead.swing.scope_degrees)
		targeted = _select_touch_target(lead, lead.swing, _attack_aim.aim_yaw())
	if targeted == null:
		_attack_aim.set_target(Vector3.ZERO, 0.0)
	else:
		var ring_center: Vector3 = targeted.base_position
		ring_center.y = 0.0
		var ring_radius: float = targeted.body_radius * sqrt(2.0) + 0.06
		_attack_aim.set_target(ring_center, ring_radius)
	if aiming:
		var origin: Vector3 = lead.base_position
		origin.y = 0.0
		var blocked_centers: PackedVector3Array = PackedVector3Array()
		var blocked_radii: PackedFloat32Array = PackedFloat32Array()
		for other: Fighter in _fighters:
			if other == lead:
				continue
			var blocked_center: Vector3 = other.base_position
			blocked_center.y = 0.0
			blocked_centers.append(blocked_center)
			blocked_radii.append(lead.body_radius + other.body_radius)
		_aim.set_move(origin, lead.yaw_degrees, lead.move_profile, blocked_centers, blocked_radii)
	if _clock.is_paused():
		_state.texture = _pause_icon
	else:
		_state.texture = _play_icon
	_refresh_menu()


func _sheet_frame(at_x: int) -> AtlasTexture:
	var icon: AtlasTexture = AtlasTexture.new()
	icon.atlas = PLAY_PAUSE
	icon.region = Rect2(at_x, 0, STATE_FRAME, STATE_FRAME)
	return icon


func _refresh_menu() -> void:
	var fighter: Fighter = _fighters[0]
	var phase: int = _clock.phase_of(fighter.id)
	var step: String = "busy"
	if phase == Clock.Phase.WAITING and fighter.aiming_touch:
		step = "touch"
	elif phase == Clock.Phase.WAITING and fighter.aiming:
		step = "aim"
	elif phase == Clock.Phase.WAITING and fighter.part == "":
		step = "part"
	elif phase == Clock.Phase.WAITING:
		step = "action"
	if step == _menu_step:
		return
	_menu_step = step
	_clear_buttons()
	if step == "part":
		_choice.text = ""
		_add_button("Head", _choose_part.bind("head"))
		_add_button("Left arm", _choose_part.bind("left arm"))
		_add_button("Right arm", _choose_part.bind("right arm"))
		_add_button("Legs", _choose_part.bind("legs"))
		return
	if step == "aim":
		_choice.text = "Move"
		_add_button("Back", _cancel_aim)
		return
	if step == "touch":
		_choice.text = "Attack"
		_add_button("Back", _cancel_aim)
		return
	if step == "action":
		_choice.text = _part_title(fighter.part)
		if fighter.part == "legs":
			_add_button("Move", _choose_action.bind("move"))
		elif fighter.part == "left arm" or fighter.part == "right arm":
			_add_button("Attack", _choose_action.bind("touch"))
		_add_button("Back", _clear_part)
		return
	_choice.text = fighter.action_label


func _part_title(part: String) -> String:
	match part:
		"head":
			return "Head"
		"left arm":
			return "Left arm"
		"right arm":
			return "Right arm"
		"legs":
			return "Legs"
		_:
			return part


func _add_button(title: String, on_pressed: Callable) -> void:
	var button: Button = Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(120, 36)
	button.pressed.connect(on_pressed)
	_options.add_child(button)


func _clear_buttons() -> void:
	for child: Node in _options.get_children():
		_options.remove_child(child)
		child.queue_free()


func _fighter_line(fighter: Fighter, phase: int) -> String:
	var phase_name: String = _phase_name(phase)
	if phase == Clock.Phase.WAITING and fighter.part != "":
		return "waiting  choosing %s" % fighter.part
	if phase == Clock.Phase.WAITING:
		return "waiting"
	return "%s  %s  %d" % [fighter.action_label, phase_name, _clock.time_left(fighter.id)]


func _phase_name(phase: int) -> String:
	match phase:
		Clock.Phase.WAITING:
			return "waiting"
		Clock.Phase.STU:
			return "start-up"
		Clock.Phase.ADR:
			return "active"
		Clock.Phase.WND:
			return "wind-down"
		_:
			return "unknown"


func _add_room() -> void:
	var world: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.018)
	world.environment = env
	add_child(world)
	_add_surface("Floor", PlaneMesh.new(), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector2(FLOOR_SIZE, FLOOR_SIZE), Color(0.4, 0.4, 0.4), true)


func _add_surface(node_name: String, mesh: PrimitiveMesh, at: Vector3, surface_euler: Vector3, size: Vector2, color: Color, tiled: bool) -> void:
	if mesh is PlaneMesh:
		(mesh as PlaneMesh).size = size
	elif mesh is QuadMesh:
		(mesh as QuadMesh).size = size
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = node_name
	body.mesh = mesh
	body.position = at
	body.rotation_degrees = surface_euler
	var tiles: Vector2 = Vector2.ONE
	if tiled:
		tiles = size
	body.material_override = _grid_material(color, tiles, tiled)
	add_child(body)


func _clear_of_fighters(mover: Fighter, start: Vector3, end: Vector3) -> Vector3:
	var kept: Vector3 = end
	for other: Fighter in _fighters:
		if other == mover:
			continue
		var center: Vector3 = other.base_position
		center.y = 0.0
		var clearance: float = mover.body_radius + other.body_radius + Aim.MARKER_RADIUS
		kept = Aim.stop_before(start, kept, center, clearance)
	return kept


func _add_fighter(who: String, at: Vector3, color: Color, holds_time: bool) -> Fighter:
	var body: Node3D = Node3D.new()
	body.name = who
	body.position = at
	var material: StandardMaterial3D = _grid_material(color, Vector2.ONE, false)
	_add_cube_face(body, "Front", Vector3(0, 0, 0.5), Vector3(0, 0, 0), material)
	_add_cube_face(body, "Back", Vector3(0, 0, -0.5), Vector3(0, 180, 0), material)
	_add_cube_face(body, "Right", Vector3(0.5, 0, 0), Vector3(0, 90, 0), material)
	_add_cube_face(body, "Left", Vector3(-0.5, 0, 0), Vector3(0, -90, 0), material)
	_add_cube_face(body, "Top", Vector3(0, 0.5, 0), Vector3(-90, 0, 0), material)
	_add_cube_face(body, "Bottom", Vector3(0, -0.5, 0), Vector3(90, 0, 0), material)
	var label: Label3D = Label3D.new()
	label.position = Vector3(0, 0.85, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.002
	label.font_size = 8
	label.outline_size = 2
	label.modulate = Color.WHITE
	body.add_child(label)
	body.add_to_group("camera_subject")
	add_child(body)
	var fighter: Fighter = Fighter.new()
	fighter.who = who
	fighter.id = _clock.add_participant(holds_time)
	fighter.mesh = body
	fighter.label = label
	fighter.base_position = at
	fighter.move_profile = MoveProfile.new()
	fighter.left_touch = TouchProfile.new()
	fighter.right_touch = TouchProfile.new()
	fighter.pushback_profile = PushbackProfile.new()
	return fighter


func _add_cube_face(body: Node3D, face_name: String, at: Vector3, surface_euler: Vector3, material: Material) -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	var face: MeshInstance3D = MeshInstance3D.new()
	face.name = face_name
	face.mesh = quad
	face.position = at
	face.rotation_degrees = surface_euler
	face.material_override = material
	body.add_child(face)


func _grid_material(color: Color, tiles: Vector2, tiled: bool) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = GRID
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.uv1_scale = Vector3(tiles.x, tiles.y, 1)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.set_flag(BaseMaterial3D.FLAG_USE_TEXTURE_REPEAT, tiled)
	return material


class Fighter extends RefCounted:
	var who: String = ""
	var id: int = 0
	var mesh: Node3D
	var label: Label3D
	var yaw_degrees: float = 0.0
	var base_position: Vector3 = Vector3.ZERO
	var part: String = ""
	var aiming: bool = false
	var aiming_touch: bool = false
	var action_label: String = ""
	var move_profile: MoveProfile
	var left_touch: TouchProfile
	var right_touch: TouchProfile
	var swing: TouchProfile
	var pushback_profile: PushbackProfile
	var body_radius: float = 0.5
