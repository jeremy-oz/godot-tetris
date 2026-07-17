extends SceneTree
# headless end-to-end network test, client side — see test_net_host.gd.

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	var lobby: Node = (load("res://scenes/lobby.tscn") as PackedScene).instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	lobby._on_join_pressed()
	lobby.ip_edit.text = "127.0.0.1"
	lobby._on_connect_pressed()
	# wait (max ~20s) for the seed handshake to move us into the versus scene
	var in_versus := false
	for _i in 1200:
		await process_frame
		if is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/versus.tscn":
			in_versus = true
			break
	if not in_versus:
		print("CLIENT_FAIL: match never started")
		quit(1)
		return
	var versus: Node = current_scene
	var mirror: TileMapLayer = versus.get_node("OpponentBoard/Board")
	# play two pieces so the other machine has something to mirror
	await process_frame
	versus.get_node("MyBoard").hard_drop()
	versus.get_node("MyBoard").hard_drop()
	# the other side's two pieces must show up on our mirror
	# (64 wall tiles + 8 piece cells)
	var got_mirror := false
	for _i in 900:
		await process_frame
		if not is_instance_valid(mirror):
			break # opponent already quit and we fell back to the lobby
		if mirror.get_used_cells().size() >= 72:
			got_mirror = true
			break
	if not got_mirror:
		print("CLIENT_FAIL: mirror never showed the opponent's pieces")
		quit(1)
		return
	# fire a garbage attack, then wait for the other side's attack on us
	versus._receive_garbage.rpc(2)
	var my_board: Node = versus.get_node("MyBoard")
	for _i in 900:
		await process_frame
		if not is_instance_valid(my_board):
			break
		if my_board.pending_garbage >= 2 or _bottom_garbage(my_board):
			print("CLIENT_OK SEED ", Lobby.match_seed, " GARBAGE_RECEIVED")
			quit(0)
			return
	print("CLIENT_FAIL: garbage never arrived")
	quit(1)

# true when the bottom playfield row holds grey garbage tiles (the queued
# attack may already have been consumed by a lock, so check both forms)
func _bottom_garbage(b: Node) -> bool:
	var layer: TileMapLayer = b.get_node("Board")
	for col in range(1, 11):
		if layer.get_cell_atlas_coords(Vector2i(col, 20)) == Vector2i(7, 0):
			return true
	return false
