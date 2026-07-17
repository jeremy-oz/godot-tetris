extends Node2D

# Versus mode: your board on the left, the opponent's on the right.
# Both machines load this scene with the same bag seed from the lobby
# handshake, so both players are dealt the identical piece sequence.
#
# All networking lives here, not in the boards. Whenever your board's
# display changes, its full visible state (three tile layers + label
# numbers) is sent to the other machine, which paints it onto its
# OpponentBoard. Clearing lines sends garbage rows the same way, and
# topping out tells the other machine it won. Both machines run this
# same script, so everything is symmetric.

#display syncs ride unreliable packets; a periodic refresh bounds how
#stale the mirror can get if the last packet of a burst was dropped
const RESEND_INTERVAL: float = 1.0

#garbage rows sent for clearing 0/1/2/3/4 lines at once
const GARBAGE_FOR_CLEAR := [0, 0, 1, 2, 4]

@onready var my_board: Node2D = $MyBoard
@onready var opponent_board: Node2D = $OpponentBoard
@onready var result_label: Label = $ResultLabel
@onready var end_menu: VBoxContainer = $EndMenu
@onready var rematch_button: Button = $EndMenu/RematchButton
@onready var menu_button: Button = $EndMenu/MenuButton

var resend_timer: float = 0.0
var match_over: bool = false

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
	my_board.lines_cleared.connect(_on_my_lines_cleared)
	my_board.topped_out.connect(_on_topped_out)
	rematch_button.pressed.connect(_on_rematch_pressed)
	menu_button.pressed.connect(_leave_match)
	my_board.new_game(Lobby.match_seed)

func _process(delta: float) -> void:
	resend_timer += delta
	if resend_timer >= RESEND_INTERVAL:
		resend_timer = 0.0
		_send_display()

#--- board mirroring ------------------------------------------------------

func _send_display() -> void:
	_receive_display.rpc(my_board.capture_display())

#runs on the OTHER machine: their board's state arrives here and is
#painted onto our right-hand mirror board
@rpc("any_peer", "call_remote", "unreliable_ordered")
func _receive_display(state: Array) -> void:
	opponent_board.apply_display(state)

#--- garbage attacks ------------------------------------------------------

func _on_my_lines_cleared(count: int) -> void:
	var garbage: int = GARBAGE_FOR_CLEAR[count]
	if garbage > 0:
		_receive_garbage.rpc(garbage)

#runs on the OTHER machine: our attack lands on their playing board
@rpc("any_peer", "call_remote", "reliable")
func _receive_garbage(count: int) -> void:
	my_board.queue_garbage(count)

#--- winning and losing ---------------------------------------------------

func _on_topped_out() -> void:
	_notify_win.rpc()
	_end_match(false)

#runs on the OTHER machine: we topped out, so they won
@rpc("any_peer", "call_remote", "reliable")
func _notify_win() -> void:
	if match_over:
		return
	my_board.game_running = false
	_end_match(true)

func _end_match(won: bool) -> void:
	match_over = true
	result_label.text = "YOU WIN!" if won else "YOU LOSE!"
	result_label.show()
	end_menu.show()

#--- rematch --------------------------------------------------------------

func _on_rematch_pressed() -> void:
	_request_rematch.rpc()

#either player may ask, but only the host picks the new seed — if both
#sides did, the players could end up with different bags
@rpc("any_peer", "call_local", "reliable")
func _request_rematch() -> void:
	if multiplayer.is_server():
		_do_rematch.rpc(randi())

@rpc("authority", "call_local", "reliable")
func _do_rematch(bag_seed: int) -> void:
	Lobby.match_seed = bag_seed
	match_over = false
	result_label.hide()
	end_menu.hide()
	opponent_board.reset_display()
	my_board.new_game(bag_seed)

func _leave_match() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
