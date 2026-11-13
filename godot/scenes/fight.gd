extends Node3D

const Clock = preload("res://combat/combat_clock.gd")
const Order = preload("res://combat/combat_order.gd")
const GRID: Texture2D = preload("res://assets/textures/debug_grid.png")
const PLAY_PAUSE: Texture2D = preload("res://assets/sprites/play_pause.png")
const Aim = preload("res://scenes/move_aim.gd")
const STATE_FRAME: int = 32

## Stand-in frame counts. The design document has no formulas for these yet.
const ATTACK_LENGTHS: Vector3i = Vector3i(18, 8, 20)
const BRACE_LENGTHS: Vector3i = Vector3i(10, 16, 12)
const PARRY_LENGTHS: Vector3i = Vector3i(6, 8, 18)
const TURN_DEGREES_PER_FRAME: float = 30.0
const MOVE_MAX_FRAMES: int = 14
const TRAVEL_RATE: float = 1.0
const UNITS_PER_TRAVEL_PER_FRAME: float = 0.25
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


func _ready() -> void:
	_pause_icon = _sheet_frame(STATE_FRAME)
	_play_icon = _sheet_frame(0)
	_aim.destination_chosen.connect(_confirm_move)
	_add_room()
	_clock = Clock.new()
	_fighters.append(_add_fighter("P1", Vector3(0, 0.5, 0), Color(0.25, 0.75, 1.0)))
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
		_refresh_view()
		return
	_try_action(_fighters[0], action)
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
	var step_length: float = TRAVEL_RATE * UNITS_PER_TRAVEL_PER_FRAME
	var travel_frames: int = clampi(ceili(distance / step_length), 1, MOVE_MAX_FRAMES)
	var aim_yaw: float = rad_to_deg(atan2(offset.x, offset.z))
	var turn: float = _shortest_yaw(fighter.yaw_degrees, aim_yaw)
	var turn_frames: int = 0
	if absf(turn) > 0.01:
		turn_frames = ceili(absf(turn) / TURN_DEGREES_PER_FRAME)
	var label: String = "legs move"
	var order: Order = Order.new(turn_frames, travel_frames, 0, label)
	if not _clock.submit_order(fighter.id, order):
		return
	fighter.action = "move"
	fighter.action_label = label
	fighter.active_length = travel_frames
	fighter.part = ""
	fighter.aiming = false
	fighter.move_yaw = aim_yaw
	fighter.move_destination = Vector3(flat_end.x, fighter.base_position.y, flat_end.z)
	fighter.move_step = step_length
	_refresh_view()


func _move_reach() -> float:
	return TRAVEL_RATE * UNITS_PER_TRAVEL_PER_FRAME * float(MOVE_MAX_FRAMES)


func _shortest_yaw(from_yaw: float, to_yaw: float) -> float:
	var delta: float = fmod(to_yaw - from_yaw, 360.0)
	if delta > 180.0:
		delta -= 360.0
	elif delta < -180.0:
		delta += 360.0
	return delta


func _try_action(fighter: Fighter, action: String) -> void:
	if fighter.part == "":
		return
	if fighter.part == "head" and action != "attack":
		return
	if fighter.part == "legs" and action != "move":
		return
	var resolved: String = action
	var lengths: Vector3i = _lengths(resolved)
	var label: String = "%s %s" % [fighter.part, resolved]
	var order: Order = Order.new(lengths.x, lengths.y, lengths.z, label)
	if not _clock.submit_order(fighter.id, order):
		return
	fighter.action = resolved
	fighter.action_label = label
	fighter.active_length = lengths.y
	fighter.part = ""


func _lengths(action: String) -> Vector3i:
	match action:
		"attack":
			return ATTACK_LENGTHS
		"brace":
			return BRACE_LENGTHS
		"parry":
			return PARRY_LENGTHS
		_:
			return Vector3i(8, 8, 8)


func _step_moves() -> void:
	for fighter: Fighter in _fighters:
		if fighter.action != "move":
			continue
		var phase: int = _clock.phase_of(fighter.id)
		if phase == Clock.Phase.STU:
			_step_turn(fighter)
		elif phase == Clock.Phase.ADR:
			_step_travel(fighter)


func _step_turn(fighter: Fighter) -> void:
	if _clock.time_left(fighter.id) <= 0:
		return
	var remaining: float = _shortest_yaw(fighter.yaw_degrees, fighter.move_yaw)
	if absf(remaining) <= TURN_DEGREES_PER_FRAME:
		fighter.yaw_degrees = fighter.move_yaw
		return
	if remaining > 0.0:
		fighter.yaw_degrees += TURN_DEGREES_PER_FRAME
	else:
		fighter.yaw_degrees -= TURN_DEGREES_PER_FRAME
	fighter.yaw_degrees = wrapf(fighter.yaw_degrees, -180.0, 180.0)


func _step_travel(fighter: Fighter) -> void:
	var next: Vector3 = fighter.base_position
	var offset: Vector3 = fighter.move_destination - next
	offset.y = 0.0
	var distance: float = offset.length()
	if distance <= fighter.move_step:
		next.x = fighter.move_destination.x
		next.z = fighter.move_destination.z
		fighter.base_position = next
		fighter.yaw_degrees = fighter.move_yaw
		return
	next += offset / distance * fighter.move_step
	fighter.base_position = next
	fighter.yaw_degrees = fighter.move_yaw


func _refresh_view() -> void:
	for fighter: Fighter in _fighters:
		var shown: Vector3 = fighter.base_position
		var phase: int = _clock.phase_of(fighter.id)
		if phase == Clock.Phase.ADR and fighter.action == "attack" and fighter.active_length > 0:
			var remaining: float = float(_clock.time_left(fighter.id))
			var along: float = 1.0 - remaining / float(fighter.active_length)
			var yaw: float = deg_to_rad(fighter.yaw_degrees)
			shown += Vector3(sin(yaw), 0.0, cos(yaw)) * sin(along * PI) * 0.6
		fighter.mesh.position = shown
		fighter.mesh.rotation_degrees = Vector3(0.0, fighter.yaw_degrees, 0.0)
		fighter.label.text = "%s  %s" % [fighter.who, _fighter_line(fighter, phase)]
	var lead: Fighter = _fighters[0]
	var lead_phase: int = _clock.phase_of(lead.id)
	var aiming: bool = lead.aiming and lead_phase == Clock.Phase.WAITING
	_aim.set_active(aiming)
	if aiming:
		var origin: Vector3 = lead.base_position
		origin.y = 0.0
		_aim.set_range(origin, _move_reach())
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
	if phase == Clock.Phase.WAITING and fighter.aiming:
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
	if step == "action":
		_choice.text = _part_title(fighter.part)
		if fighter.part == "head":
			_add_button("Attack", _choose_action.bind("attack"))
		elif fighter.part == "legs":
			_add_button("Move", _choose_action.bind("move"))
		else:
			_add_button("Attack", _choose_action.bind("attack"))
			_add_button("Brace", _choose_action.bind("brace"))
			_add_button("Parry", _choose_action.bind("parry"))
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
	_add_surface("Floor", PlaneMesh.new(), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector2(FLOOR_SIZE, FLOOR_SIZE), Color(0.62, 0.64, 0.68), true)


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


func _add_fighter(who: String, at: Vector3, color: Color) -> Fighter:
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
	fighter.id = _clock.add_participant(true)
	fighter.mesh = body
	fighter.label = label
	fighter.base_position = at
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
	var action: String = ""
	var action_label: String = ""
	var active_length: int = 0
	var move_yaw: float = 0.0
	var move_destination: Vector3 = Vector3.ZERO
	var move_step: float = 0.0
