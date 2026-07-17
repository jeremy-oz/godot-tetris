extends Node2D

# Versus mode: your board on the left, the opponent's on the right.
# Both machines load this scene with the same bag seed from the lobby
# handshake, so both players are dealt the identical piece sequence.
# For now only your own board plays — the opponent's board stays empty
# until the next step teaches it to mirror their machine.

@onready var my_board: Node2D = $MyBoard
@onready var opponent_board: Node2D = $OpponentBoard

func _ready() -> void:
	#two boards need twice the width: widen the logical canvas, then ask the
	#OS window to match. If the window cannot grow (the editor's embedded
	#game view), the stretch mode scales and centers the canvas instead.
	var window := get_window()
	window.content_scale_size = Vector2i(1300, 704)
	window.size = Vector2i(1300, 704)
	window.move_to_center()
	multiplayer.server_disconnected.connect(_leave_match)
	multiplayer.peer_disconnected.connect(func(_id: int) -> void: _leave_match())
	my_board.new_game(Lobby.match_seed)

func _leave_match() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
