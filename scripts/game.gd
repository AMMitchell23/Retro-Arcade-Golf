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
]

## Each player is {"name": String, "color": Color, "strokes": int}.
var players: Array[Dictionary] = []
var level_index := 0


func setup_players(count: int) -> void:
	players.clear()
	for i in clampi(count, 1, MAX_PLAYERS):
		players.append({
			"name": "P%d" % (i + 1),
			"color": PLAYER_COLORS[i],
			"strokes": 0,
		})


## Called from the Play Menu. count = 1 is Local Singleplayer,
## 2 to 4 is Local Multiplayer (hot-seat, players take turns).
func start_local(count: int) -> void:
	setup_players(count)
	level_index = 0
	get_tree().change_scene_to_file(LEVELS[level_index])


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)
