class_name Golfer
extends Node2D
## The golfer standing behind the ball: a neon stick figure holding a club.
## The node's origin is the spot on the ground between the golfer's feet.
## Set `facing` to 1 to face right or -1 to face left. Call `swing()` to play
## the swing; `impact` fires when the club reaches the ball.

signal impact
signal swing_finished

## Where the ball sits, relative to the golfer's feet (facing right).
const BALL_OFFSET := Vector2(30, -8)
const SHOULDER := Vector2(0, -46)
const HIP := Vector2(0, -24)
const HEAD := Vector2(1, -57)
const HEAD_RADIUS := 7.0
const ARM_LENGTH := 18.0
const CLUB_COLOR := Color("#d9f2ff")
const GRIP_COLOR := Color("#ff2bd6")

## Body color; the level sets it to the current player's color.
var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()

## 1 = facing right, -1 = facing left.
var facing := 1.0:
	set(value):
		facing = value
		scale.x = facing

## How far the club is rotated from its resting spot at the ball, in degrees.
## Positive = back swing (club goes up behind the golfer).
var swing_angle := 0.0:
	set(value):
		swing_angle = value
		queue_redraw()

var _tween: Tween
# The club rests with its head just behind the ball.
var _rest_dir := (BALL_OFFSET + Vector2(-12, 6) - SHOULDER).normalized()
var _club_length := (BALL_OFFSET + Vector2(-12, 6) - SHOULDER).length()


func is_swinging() -> bool:
	return _tween != null and _tween.is_running()


## Puts the club back at the ball, cancelling any swing in progress.
func reset() -> void:
	if _tween:
		_tween.kill()
	swing_angle = 0.0


## Back swing, down swing (emits `impact` at the ball), then follow-through.
## `power` is 0-100 and sets how far back the club goes.
func swing(power: float) -> void:
	reset()
	var back := 60.0 + power * 1.1
	_tween = create_tween()
	_tween.tween_property(self, "swing_angle", back, 0.22 + power * 0.002) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.08)
	_tween.tween_property(self, "swing_angle", 0.0, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(impact.emit)
	_tween.tween_property(self, "swing_angle", -110.0, 0.18) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.35)
	_tween.tween_callback(swing_finished.emit)


func _draw() -> void:
	var dir := _rest_dir.rotated(deg_to_rad(swing_angle))
	var hands := SHOULDER + dir * ARM_LENGTH
	var club_end := SHOULDER + dir * _club_length
	# The club head lies flat on the ground at rest and turns with the club.
	var head_dir := Vector2.RIGHT.rotated(deg_to_rad(swing_angle))

	# Club first, so the arms are drawn over the grip.
	_glow_line(hands, club_end, CLUB_COLOR, 2.0)
	_glow_line(club_end - head_dir * 2.0, club_end + head_dir * 9.0, CLUB_COLOR, 5.0)
	draw_line(hands, hands + dir * 6.0, GRIP_COLOR, 3.0)

	# Body.
	_glow_line(SHOULDER, HIP, color, 3.0)
	_glow_line(HIP, Vector2(-8, 0), color, 3.0)
	_glow_line(HIP, Vector2(9, 0), color, 3.0)
	_glow_line(SHOULDER, hands, color, 3.0)
	_glow_line(SHOULDER + Vector2(0, 3), hands, color, 2.0)

	# Head with a golf cap: crown plus a brim sticking out the front.
	draw_circle(HEAD, HEAD_RADIUS + 4.0, Color(color, 0.12))
	draw_arc(HEAD, HEAD_RADIUS, 0.0, TAU, 24, color, 2.0)
	draw_arc(HEAD, HEAD_RADIUS + 1.0, PI, TAU, 12, color, 3.0)
	draw_line(HEAD + Vector2(HEAD_RADIUS - 1.0, -2.0), HEAD + Vector2(HEAD_RADIUS + 7.0, -1.0), color, 3.0)


## A bright line with a faint wide one underneath, to fake a neon glow.
func _glow_line(from: Vector2, to: Vector2, c: Color, width: float) -> void:
	draw_line(from, to, Color(c, 0.18), width + 5.0)
	draw_line(from, to, c, width)
