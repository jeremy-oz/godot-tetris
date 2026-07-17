extends Node2D

# Solo mode: one offline board plus a restart button. Versus mode instead
# arranges two board instances and drives them over the network.
@onready var player_board: Node2D = $Board
@onready var start_button: Button = $StartButton
@onready var menu_button: Button = $MenuButton

func _ready() -> void:
	#a focused button would also react to Space (hard drop) and the arrow keys
	start_button.focus_mode = Control.FOCUS_NONE
	menu_button.focus_mode = Control.FOCUS_NONE
	start_button.pressed.connect(player_board.new_game)
	menu_button.pressed.connect(_back_to_menu)
	player_board.new_game()

func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
