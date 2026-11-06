extends Control
## Main Menu (Fig. 2) and Play Menu (Fig. 3).

const TITLE := """
 +==================================================+
 |                                                  |
 |   R E T R O    A R C A D E    G O L F            |
 |                                                  |
 |      o                                  |>       |
 |     /|\\_                                |        |
 |     / \\   .                 ____     __|__      |
 |  ___________________________/    \\___/  \\_____   |
 +==================================================+
"""

@onready var main_box: VBoxContainer = $Center/Main
@onready var play_box: VBoxContainer = $Center/PlayMenu
@onready var player_count: SpinBox = $Center/PlayMenu/PlayerRow/PlayerCount


func _ready() -> void:
	$Center/Main/Title.text = TITLE
	$Center/Main/PlayButton.pressed.connect(_show_play_menu.bind(true))
	$Center/Main/QuitButton.pressed.connect(get_tree().quit)
	$Center/PlayMenu/SingleButton.pressed.connect(Game.start_local.bind(1))
	$Center/PlayMenu/MultiButton.pressed.connect(_on_multi_pressed)
	$Center/PlayMenu/BackButton.pressed.connect(_show_play_menu.bind(false))
	player_count.max_value = Game.MAX_PLAYERS
	_show_play_menu(false)


func _show_play_menu(show_play: bool) -> void:
	main_box.visible = not show_play
	play_box.visible = show_play
	if show_play:
		$Center/PlayMenu/SingleButton.grab_focus()
	else:
		$Center/Main/PlayButton.grab_focus()


func _on_multi_pressed() -> void:
	Game.start_local(int(player_count.value))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and play_box.visible:
		_show_play_menu(false)
