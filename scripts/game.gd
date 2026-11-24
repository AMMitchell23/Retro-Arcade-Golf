extends Node
## Global game state (autoloaded as "Game").
## Holds the players for the current match and handles scene changes.

const PLAYER_COLORS: Array[Color] = [
	Color("#39ff14"), # neon green
	Color("#ff2bd6"), # neon magenta
	Color("#00e5ff"), # neon cyan
	Color("#ffe600"), # neon yellow
]
const MAX_PLAYERS := 4

const MAIN_MENU := "res://scenes/main_menu.tscn"
const LEVELS: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]

## Each player is {"name": String, "color": Color, "strokes": int, "scores": Array}.
## "strokes" is the current hole; "scores" holds the strokes for each finished
## hole by level index (null for a hole that was skipped, e.g. when running a
## level directly with F6).
var players: Array[Dictionary] = []
## Index into LEVELS of the hole being played.
var level_index := 0
## Par of each finished hole, by level index.
var hole_pars: Array = []


func setup_players(count: int) -> void:
	players.clear()
	for i in clampi(count, 1, MAX_PLAYERS):
		players.append({
			"name": "P%d" % (i + 1),
			"color": PLAYER_COLORS[i],
			"strokes": 0,
			"scores": [],
		})


## Called from the Play Menu. count = 1 is Local Singleplayer,
## 2 to 4 is Local Multiplayer (hot-seat, players take turns).
func start_local(count: int) -> void:
	setup_players(count)
	restart_match()


## Starts the match over from the first hole with the same players.
func restart_match() -> void:
	for player in players:
		player["strokes"] = 0
		player["scores"] = []
	hole_pars.clear()
	level_index = 0
	get_tree().change_scene_to_file(LEVELS[level_index])


## Saves every player's strokes for the hole just finished.
func record_hole(par: int) -> void:
	if hole_pars.size() <= level_index:
		hole_pars.resize(level_index + 1)
	hole_pars[level_index] = par
	for player in players:
		var scores: Array = player["scores"]
		if scores.size() <= level_index:
			scores.resize(level_index + 1)
		scores[level_index] = player["strokes"]


func is_last_level() -> bool:
	return level_index >= LEVELS.size() - 1


func next_level() -> void:
	if is_last_level():
		return
	level_index += 1
	get_tree().change_scene_to_file(LEVELS[level_index])


## Strokes over all finished holes.
func total_strokes(player: Dictionary) -> int:
	var total := 0
	for s in player["scores"]:
		if s != null:
			total += int(s)
	return total


## Par over all finished holes.
func total_par() -> int:
	var total := 0
	for p in hole_pars:
		if p != null:
			total += int(p)
	return total


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)
