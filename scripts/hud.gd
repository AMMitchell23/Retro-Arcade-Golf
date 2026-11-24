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
@onready var results_title: Label = $Results/Box/ResultsTitle
@onready var next_button: Button = $Results/Box/NextButton
@onready var again_button: Button = $Results/Box/AgainButton


func _ready() -> void:
	results.visible = false
	message.visible = false
	next_button.pressed.connect(Game.next_level)
	again_button.pressed.connect(Game.restart_match)
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


## Results panel at the end of a hole. Between holes it ranks this hole and
## shows running totals; after the last hole it shows the full scorecard.
func show_results(players: Array[Dictionary], par: int, final: bool) -> void:
	var ranked := players.duplicate()
	if final:
		ranked.sort_custom(func(a, b): return Game.total_strokes(a) < Game.total_strokes(b))
		results_title.text = "== FINAL SCORECARD =="
		table.text = _scorecard(ranked)
	else:
		ranked.sort_custom(func(a, b): return a["strokes"] < b["strokes"])
		results_title.text = "== %s RESULTS ==" % _hole_name
		table.text = _hole_table(ranked, par)
	next_button.visible = not final
	again_button.visible = final
	aim.visible = false
	results.visible = true
	(again_button if final else next_button).grab_focus()


func _hole_table(ranked: Array, par: int) -> String:
	var lines := PackedStringArray()
	for i in ranked.size():
		var p: Dictionary = ranked[i]
		lines.append("%d. %-4s %s %2d strokes (%+d)   TOTAL %2d" % [
			i + 1, p["name"], ".".repeat(6), p["strokes"], p["strokes"] - par,
			Game.total_strokes(p)])
	return "\n".join(lines)


## Players by hole: one column per hole, then the total and the score to par.
func _scorecard(ranked: Array) -> String:
	var holes := Game.hole_pars.size()
	var header := "        "
	var par_row := "   PAR  "
	for h in holes:
		header += " %3s" % ("H%d" % (h + 1))
		par_row += " %3s" % _cell(Game.hole_pars[h])
	header += "  TOT"
	par_row += "  %3d" % Game.total_par()
	var lines := PackedStringArray([header, par_row])
	for i in ranked.size():
		var p: Dictionary = ranked[i]
		var row := "%d. %-4s " % [i + 1, p["name"]]
		var scores: Array = p["scores"]
		for h in holes:
			row += " %3s" % _cell(scores[h] if h < scores.size() else null)
		var total := Game.total_strokes(p)
		row += "  %3d (%+d)" % [total, total - Game.total_par()]
		lines.append(row)
	return "\n".join(lines)


func _cell(value: Variant) -> String:
	return "-" if value == null else str(value)
