extends Node2D
## One golf hole. The ground is built from `ground_points` (left to right),
## so a new level is just a copy of level_1.tscn with different numbers.
## Runs turn-based play: one player shoots at a time, the others wait.

const BallScene := preload("res://scenes/ball.tscn")

@export var hole_name := "HOLE 1"
@export var par := 3
@export var level_width := 2000.0
## Where every ball starts.
@export var tee_position := Vector2(200, 511)
## Center of the cup's bottom. Put a dip in ground_points around it.
@export var cup_position := Vector2(1720, 572)
## The ground's top edge, from x = 0 to x = level_width.
@export var ground_points := PackedVector2Array()
@export var ground_color := Color("#39ff14")
@export var fill_color := Color(0.02, 0.07, 0.03, 1)

const FLOOR_Y := 900.0      # bottom of the solid ground
const WALL := 40.0          # wall thickness at both ends
const WALL_TOP := -800.0
const AIM_SPEED := 70.0     # degrees per second
const POWER_SPEED := 60.0   # percent per second
const MAX_SHOT_SPEED := 1500.0
const STOP_SPEED := 8.0     # below this the ball counts as stopped
const STOP_TIME := 0.6      # ...for this many seconds
const MAX_ROLL_TIME := 12.0 # safety net for a ball that never settles

enum State { AIMING, SWINGING, ROLLING, WAITING, FINISHED }

var state := State.WAITING
var balls: Array[GolfBall] = []
var holed: Array[bool] = []
var current := 0
var aim_angle := 45.0   # 0 = right, 90 = straight up, 180 = left
var power := 50.0       # percent
var still_timer := 0.0
var roll_timer := 0.0
var last_rest := Vector2.ZERO
var _solid_polygon := PackedVector2Array()

@onready var camera: Camera2D = $Camera2D
@onready var hud: GameHUD = $HUD
@onready var golfer: Golfer = $Golfer
@onready var aim_line: Line2D = $AimLine
@onready var cup: Area2D = $Cup


func _ready() -> void:
	_build_terrain()
	cup.position = cup_position
	cup.body_entered.connect(_on_cup_body_entered)

	# Lets you run this scene directly (F6) without going through the menu.
	if Game.players.is_empty():
		Game.setup_players(1)
	var index := Game.LEVELS.find(scene_file_path)
	if index != -1:
		Game.level_index = index

	for i in Game.players.size():
		var player: Dictionary = Game.players[i]
		player["strokes"] = 0
		var ball: GolfBall = BallScene.instantiate()
		ball.color = player["color"]
		ball.position = tee_position
		add_child(ball)
		balls.append(ball)
		holed.append(false)

	camera.limit_left = int(-WALL)
	camera.limit_right = int(level_width + WALL)
	camera.limit_top = int(WALL_TOP)
	camera.limit_bottom = int(FLOOR_Y - 140.0)
	camera.global_position = tee_position
	camera.reset_smoothing()

	hud.setup(hole_name, par)
	_start_turn(0)


# --- Turn flow -----------------------------------------------------------

func _start_turn(index: int) -> void:
	current = index
	state = State.AIMING
	for i in balls.size():
		balls[i].active = (i == current)
	var player: Dictionary = Game.players[current]
	golfer.reset()
	golfer.color = player["color"]
	aim_line.default_color = player["color"]
	if Game.players.size() > 1:
		hud.flash("%s, YOUR SHOT" % player["name"], player["color"])
	_refresh_hud()


func _shoot() -> void:
	# Swing the club first; the ball leaves when the club reaches it.
	state = State.SWINGING
	aim_line.visible = false
	golfer.swing(power)
	await golfer.impact
	if state != State.SWINGING:
		return
	var ball := balls[current]
	last_rest = ball.global_position
	Game.players[current]["strokes"] += 1
	state = State.ROLLING
	still_timer = 0.0
	roll_timer = 0.0
	# TODO (FR-18/19): spin the roulette wheel here and modify the shot.
	ball.launch(_aim_direction() * MAX_SHOT_SPEED * power / 100.0)
	_refresh_hud()


func _end_shot() -> void:
	balls[current].stop()
	_next_turn()


func _next_turn() -> void:
	if not holed.has(false):
		_finish()
		return
	var count := balls.size()
	for step in range(1, count + 1):
		var i := (current + step) % count
		if not holed[i]:
			_start_turn(i)
			return


func _finish() -> void:
	state = State.FINISHED
	aim_line.visible = false
	golfer.visible = false
	Game.record_hole(par)
	hud.show_results(Game.players, par, Game.is_last_level())


func _on_cup_body_entered(body: Node2D) -> void:
	var i := balls.find(body)
	if i == -1 or holed[i]:
		return
	holed[i] = true
	state = State.WAITING
	var ball := balls[i]
	ball.call_deferred("stop")
	ball.visible = false
	var player: Dictionary = Game.players[i]
	hud.flash("%s SANK IT!  %s" % [player["name"], _score_name(player["strokes"])], player["color"])
	_refresh_hud()
	await get_tree().create_timer(1.5).timeout
	_next_turn()


func _ball_lost() -> void:
	var ball := balls[current]
	ball.stop()
	ball.global_position = last_rest
	Game.players[current]["strokes"] += 1
	hud.flash("OUT OF BOUNDS  +1", Color("#ff3b3b"))
	_next_turn()


func _score_name(strokes: int) -> String:
	if strokes == 1:
		return "HOLE IN ONE!"
	match strokes - par:
		-2: return "EAGLE"
		-1: return "BIRDIE"
		0: return "PAR"
		1: return "BOGEY"
		_: return "%+d" % (strokes - par)


# --- Input and per-frame updates -------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Game.go_to_main_menu()
		return
	if state != State.AIMING:
		return
	if event.is_action_pressed("ui_accept"):
		_shoot()
	elif event is InputEventMouseMotion:
		var v := get_global_mouse_position() - balls[current].global_position
		var degrees := rad_to_deg(atan2(-v.y, v.x))
		if degrees < 0.0:
			degrees = 0.0 if degrees > -90.0 else 180.0
		aim_angle = degrees
	elif event is InputEventMouseButton and event.is_pressed():
		var button := event as InputEventMouseButton
		match button.button_index:
			MOUSE_BUTTON_LEFT: _shoot()
			MOUSE_BUTTON_WHEEL_UP: power = clampf(power + 5.0, 5.0, 100.0)
			MOUSE_BUTTON_WHEEL_DOWN: power = clampf(power - 5.0, 5.0, 100.0)


func _process(delta: float) -> void:
	if balls.is_empty():
		return
	var ball := balls[current]
	camera.global_position = ball.global_position

	var aiming := state == State.AIMING
	aim_line.visible = aiming
	# Keep the golfer on screen through the swing's follow-through.
	golfer.visible = aiming or state == State.SWINGING or golfer.is_swinging()
	if not aiming:
		return

	var turn := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		turn += 1.0
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		turn -= 1.0
	aim_angle = clampf(aim_angle + turn * AIM_SPEED * delta, 0.0, 180.0)

	var charge := 0.0
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		charge += 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		charge -= 1.0
	power = clampf(power + charge * POWER_SPEED * delta, 5.0, 100.0)

	var start := ball.global_position
	aim_line.points = PackedVector2Array([start, start + _aim_direction() * (30.0 + power * 1.7)])
	# Stand the golfer behind the ball, facing the shot.
	golfer.facing = 1.0 if aim_angle <= 90.0 else -1.0
	golfer.global_position = start - Vector2(Golfer.BALL_OFFSET.x * golfer.facing, Golfer.BALL_OFFSET.y)
	hud.update_aim(aim_angle, power)


func _physics_process(delta: float) -> void:
	if state != State.ROLLING:
		return
	var ball := balls[current]
	roll_timer += delta
	if ball.global_position.y > FLOOR_Y + 100.0:
		_ball_lost()
		return
	if ball.is_moving(STOP_SPEED):
		still_timer = 0.0
	else:
		still_timer += delta
	if still_timer >= STOP_TIME or roll_timer >= MAX_ROLL_TIME:
		_end_shot()


func _aim_direction() -> Vector2:
	var r := deg_to_rad(aim_angle)
	return Vector2(cos(r), -sin(r))


func _refresh_hud() -> void:
	hud.update_turn(Game.players[current], Game.players.size() > 1)
	hud.update_scores(Game.players, holed)
	hud.update_aim(aim_angle, power)


# --- Building the course -----------------------------------------------------

func _build_terrain() -> void:
	_solid_polygon = ground_points.duplicate()
	_solid_polygon.append(Vector2(level_width, FLOOR_Y))
	_solid_polygon.append(Vector2(0.0, FLOOR_Y))

	var body := StaticBody2D.new()
	body.name = "Ground"
	var material := PhysicsMaterial.new()
	material.bounce = 0.35
	material.friction = 0.8
	body.physics_material_override = material

	var ground_shape := CollisionPolygon2D.new()
	ground_shape.polygon = _solid_polygon
	body.add_child(ground_shape)

	for x in [-WALL, level_width]:
		var wall := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(WALL, FLOOR_Y - WALL_TOP)
		wall.shape = rect
		wall.position = Vector2(x + WALL / 2.0, (FLOOR_Y + WALL_TOP) / 2.0)
		body.add_child(wall)
	add_child(body)

	# Neon outline: a wide faint line under a thin bright one.
	var outline := ground_points.duplicate()
	outline.insert(0, Vector2(0.0, WALL_TOP))
	outline.append(Vector2(level_width, WALL_TOP))
	for spec in [[12.0, 0.15], [3.0, 1.0]]:
		var line := Line2D.new()
		line.points = outline
		line.width = spec[0]
		line.default_color = Color(ground_color, spec[1])
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(line)
	queue_redraw()


func _draw() -> void:
	if _solid_polygon.is_empty():
		return
	draw_colored_polygon(_solid_polygon, fill_color)

	# ASCII "dirt" texture inside the ground.
	var font := ThemeDB.fallback_font
	var chars := [".", ":", "'", ",", "."]
	var dim := Color(ground_color, 0.22)
	for x in range(10, int(level_width), 26):
		for y in range(int(WALL_TOP), int(FLOOR_Y), 26):
			var p := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(p + Vector2(0, -16), _solid_polygon):
				draw_string(font, p, chars[(x * 7 + y * 13) % chars.size()],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 16, dim)

	# Flag over the cup.
	var pole_base := cup_position + Vector2(0, -40)
	var pole_top := pole_base + Vector2(0, -90)
	draw_line(pole_base, pole_top, Color("#d9f2ff"), 2.0)
	var flag := PackedVector2Array([pole_top, pole_top + Vector2(30, 11), pole_top + Vector2(0, 22)])
	draw_colored_polygon(flag, Color("#ff2bd6"))
	draw_string(font, pole_top + Vector2(-16, -10), hole_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ff2bd6"))
