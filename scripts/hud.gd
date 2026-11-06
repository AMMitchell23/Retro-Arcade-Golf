class_name GameHUD
extends CanvasLayer
## In-game HUD (Fig. 6): hole info, stroke count, aim readout, scores, results.

const BAR_LENGTH := 20

var _hole_name := ""
var _par := 0
var _message_tween: Tween

@onready var info: Label = $Info
@onready var scores: Label = $Scores
@onready var aim: Label = $Aim
@onready var message: Label = $Message
@onready var results: PanelContainer = $Results
@onready var table: Label = $Results/Box/Table


func _ready() -> void:
	results.visible = false
	message.visible = false
	$Results/Box/AgainButton.pressed.connect(func() -> void: get_tree().reload_current_scene())
	$Results/Box/MenuButton.pressed.connect(Game.go_to_main_menu)


func setup(hole_name: String, par: int) -> void:
	_hole_name = hole_name
	_par = par


func update_turn(player: Dictionary, show_name: bool) -> void:
	var lines := "%s   PAR %d\n" % [_hole_name, _par]
	if show_name:
		lines += "PLAYER  %s\n" % player["name"]
	lines += "STROKES %d" % player["strokes"]
	info.text = lines
	info.add_theme_color_override("font_color", player["color"])


func update_aim(angle: float, power: float) -> void:
	var filled := roundi(power / 100.0 * BAR_LENGTH)
	aim.text = "ANGLE %3d°   POWER [%s%s] %3d%%" % [
		roundi(angle), "#".repeat(filled), "-".repeat(BAR_LENGTH - filled), roundi(power)]


func update_scores(players: Array[Dictionary], holed: Array[bool]) -> void:
	if players.size() < 2:
		scores.text = ""
		return
	var lines := PackedStringArray()
	for i in players.size():
		var tag := "  IN" if holed[i] else ""
		lines.append("%s  %2d%s" % [players[i]["name"], players[i]["strokes"], tag])
	scores.text = "\n".join(lines)


func flash(text: String, color: Color) -> void:
	message.text = text
	message.add_theme_color_override("font_color", color)
	message.visible = true
	message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(1.2)
	_message_tween.tween_property(message, "modulate:a", 0.0, 0.5)


func show_results(players: Array[Dictionary], par: int) -> void:
	var ranked := players.duplicate()
	ranked.sort_custom(func(a, b): return a["strokes"] < b["strokes"])
	var lines := PackedStringArray()
	for i in ranked.size():
		var p: Dictionary = ranked[i]
		lines.append("%d. %-4s %s %2d strokes (%+d)" % [
			i + 1, p["name"], ".".repeat(8), p["strokes"], p["strokes"] - par])
	table.text = "\n".join(lines)
	aim.visible = false
	results.visible = true
	$Results/Box/AgainButton.grab_focus()
