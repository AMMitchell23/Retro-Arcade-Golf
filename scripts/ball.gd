class_name GolfBall
extends RigidBody2D
## A player's golf ball. Frozen while the player aims, unfrozen while it rolls.

const RADIUS := 8.0

var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()

## The ball whose turn it is is drawn bright; the others are dimmed.
var active := false:
	set(value):
		active = value
		modulate.a = 1.0 if active else 0.35


func _ready() -> void:
	freeze = true


func launch(velocity: Vector2) -> void:
	freeze = false
	sleeping = false
	angular_velocity = 0.0
	linear_velocity = velocity


func stop() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true


func is_moving(threshold: float) -> bool:
	return linear_velocity.length() > threshold


func _draw() -> void:
	# Fake neon glow: a few soft circles behind a solid core.
	draw_circle(Vector2.ZERO, RADIUS + 8.0, Color(color, 0.08))
	draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(color, 0.2))
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_circle(Vector2(-2.5, -2.5), 2.5, Color(1, 1, 1, 0.8))
