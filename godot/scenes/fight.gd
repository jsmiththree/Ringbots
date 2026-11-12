extends Node3D

const Clock = preload("res://combat/combat_clock.gd")
const Order = preload("res://combat/combat_order.gd")
const GRID: Texture2D = preload("res://assets/textures/debug_grid.png")

## Stand-in frame counts. The design document has no formulas for these yet.
const ATTACK_LENGTHS: Vector3i = Vector3i(18, 8, 20)
const BRACE_LENGTHS: Vector3i = Vector3i(10, 16, 12)
const PARRY_LENGTHS: Vector3i = Vector3i(6, 8, 18)
const MOVE_LENGTHS: Vector3i = Vector3i(8, 12, 10)
const MOVE_DISTANCE: float = 2.0
const FLOOR_SIZE: float = 16.0

var _clock: Clock
var _fighters: Array = []

@onready var _status: Label = $UI/Status
@onready var _help: Label = $UI/Help


func _ready() -> void:
	var camera: Camera3D = $Camera3D
	camera.position = Vector3(0, 8, 11)
	camera.look_at(Vector3(0, 0.5, 0))
	_add_room()
	_clock = Clock.new()
	_fighters.append(_add_fighter("P1", Vector3(-3, 0.5, 0), 1.0, Color(0.25, 0.75, 1.0)))
	_fighters.append(_add_fighter("P2", Vector3(3, 0.5, 0), -1.0, Color(1.0, 0.42, 0.18)))
	_refresh_view()


func _physics_process(_delta: float) -> void:
	if not _clock.is_paused():
		_step_moves()
		_clock.tick(1)
	_refresh_view()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	_handle_key(0, key_event.keycode, KEY_Q, KEY_W, KEY_E, KEY_R)
	_handle_key(1, key_event.keycode, KEY_U, KEY_I, KEY_O, KEY_P)


func _handle_key(index: int, pressed: Key, first: Key, second: Key, third: Key, fourth: Key) -> void:
	var fighter: Fighter = _fighters[index]
	if _clock.phase_of(fighter.id) != Clock.Phase.WAITING:
		return
	if fighter.part == "":
		if pressed == first:
			fighter.part = "head"
		elif pressed == second:
			fighter.part = "left arm"
		elif pressed == third:
			fighter.part = "right arm"
		elif pressed == fourth:
			fighter.part = "legs"
		return
	if pressed == fourth:
		fighter.part = ""
		return
	if pressed == first:
		_try_action(fighter, "attack")
	elif pressed == second:
		_try_action(fighter, "brace")
	elif pressed == third:
		_try_action(fighter, "parry")


func _try_action(fighter: Fighter, action: String) -> void:
	if fighter.part == "":
		return
	if fighter.part == "head" and action != "attack":
		return
	if fighter.part == "legs" and action != "attack":
		return
	var resolved: String = action
	if fighter.part == "legs":
		resolved = "move"
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
		"move":
			return MOVE_LENGTHS
		_:
			return Vector3i(8, 8, 8)


func _step_moves() -> void:
	for fighter: Fighter in _fighters:
		if fighter.action != "move":
			continue
		if _clock.phase_of(fighter.id) != Clock.Phase.ADR:
			continue
		if fighter.active_length <= 0:
			continue
		var step: float = MOVE_DISTANCE / float(fighter.active_length)
		fighter.base_position.x += fighter.facing * step
		fighter.base_position.x = clampf(fighter.base_position.x, -7.0, 7.0)


func _refresh_view() -> void:
	for fighter: Fighter in _fighters:
		var shown: Vector3 = fighter.base_position
		var phase: int = _clock.phase_of(fighter.id)
		if phase == Clock.Phase.ADR and fighter.action == "attack" and fighter.active_length > 0:
			var remaining: float = float(_clock.time_left(fighter.id))
			var along: float = 1.0 - remaining / float(fighter.active_length)
			shown.x += fighter.facing * sin(along * PI) * 0.6
		fighter.mesh.position = shown
		fighter.label.text = "%s  %s" % [fighter.who, _fighter_line(fighter, phase)]
	var state: String = "running"
	if _clock.is_paused():
		state = "paused"
	_status.text = state
	var lines: PackedStringArray = PackedStringArray()
	var p1: String = _help_line(_fighters[0], "Q", "W", "E", "R")
	var p2: String = _help_line(_fighters[1], "U", "I", "O", "P")
	if p1 != "":
		lines.append(p1)
	if p2 != "":
		lines.append(p2)
	_help.text = "\n".join(lines)


func _help_line(fighter: Fighter, first: String, second: String, third: String, fourth: String) -> String:
	if _clock.phase_of(fighter.id) != Clock.Phase.WAITING:
		return ""
	if fighter.part == "":
		return "%s  %s head  %s left arm  %s right arm  %s legs" % [fighter.who, first, second, third, fourth]
	if fighter.part == "head":
		return "%s  head  %s attack  %s back" % [fighter.who, first, fourth]
	if fighter.part == "legs":
		return "%s  legs  %s move  %s back" % [fighter.who, first, fourth]
	return "%s  %s  %s attack  %s brace  %s parry  %s back" % [fighter.who, fighter.part, first, second, third, fourth]


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
	env.background_color = Color(0.08, 0.08, 0.09)
	world.environment = env
	add_child(world)
	_add_surface("Floor", PlaneMesh.new(), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector2(FLOOR_SIZE, FLOOR_SIZE), Color(0.82, 0.84, 0.88), true)
	_add_surface("WallNorth", QuadMesh.new(), Vector3(0, 2, -8), Vector3(0, 0, 0), Vector2(FLOOR_SIZE, 4), Color(0.45, 0.5, 0.58), true)
	_add_surface("WallEast", QuadMesh.new(), Vector3(8, 2, 0), Vector3(0, 90, 0), Vector2(FLOOR_SIZE, 4), Color(0.38, 0.42, 0.5), true)
	_add_surface("WallWest", QuadMesh.new(), Vector3(-8, 2, 0), Vector3(0, -90, 0), Vector2(FLOOR_SIZE, 4), Color(0.38, 0.42, 0.5), true)


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


func _add_fighter(who: String, at: Vector3, facing: float, color: Color) -> Fighter:
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
	label.font_size = 16
	label.outline_size = 4
	label.modulate = Color.WHITE
	body.add_child(label)
	add_child(body)
	var fighter: Fighter = Fighter.new()
	fighter.who = who
	fighter.id = _clock.add_participant(true)
	fighter.mesh = body
	fighter.label = label
	fighter.facing = facing
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
	var facing: float = 1.0
	var base_position: Vector3 = Vector3.ZERO
	var part: String = ""
	var action: String = ""
	var action_label: String = ""
	var active_length: int = 0
