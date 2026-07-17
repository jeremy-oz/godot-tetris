extends Node2D

# Solo mode: one offline board plus a restart button. Versus mode will
# instead arrange two board instances and drive them over the network.
@onready var player_board: Node2D = $Board
@onready var start_button: Button = $StartButton

func _ready() -> void:
	#a focused button would also react to Space (hard drop) and the arrow keys
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.pressed.connect(player_board.new_game)
	player_board.new_game()
