extends Node2D

# Versus mode: your board on the left, the opponent's on the right.
# Both machines load this scene with the same bag seed from the lobby
# handshake, so both players are dealt the identical piece sequence.
#
# All networking lives here, not in the boards. Whenever your board's
# display changes, its full visible state (three tile layers + label
# numbers) is sent to the other machine, which paints it onto its
# OpponentBoard. Both machines run this same script, so the mirroring
# is symmetric.

#display syncs ride unreliable packets; a periodic refresh bounds how
#stale the mirror can get if the last packet of a burst was dropped
const RESEND_INTERVAL: float = 1.0

@onready var my_board: Node2D = $MyBoard
@onready var opponent_board: Node2D = $OpponentBoard

var resend_timer: float = 0.0

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
	my_board.display_changed.connect(_send_display)
	my_board.new_game(Lobby.match_seed)

func _process(delta: float) -> void:
	resend_timer += delta
	if resend_timer >= RESEND_INTERVAL:
		resend_timer = 0.0
		_send_display()

func _send_display() -> void:
	_receive_display.rpc(my_board.capture_display())

#runs on the OTHER machine: their board's state arrives here and is
#painted onto our right-hand mirror board
@rpc("any_peer", "call_remote", "unreliable_ordered")
func _receive_display(state: Array) -> void:
	opponent_board.apply_display(state)

func _leave_match() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
