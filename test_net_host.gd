extends SceneTree
# headless end-to-end network test, host side. Run both processes:
#   godot --headless -s res://test_net_host.gd    (start this first)
#   godot --headless -s res://test_net_client.gd  (then this one)
# Each side hosts/joins, plays two pieces, and passes once the OTHER
# side's pieces appear on its own mirror board. "<SIDE>_OK SEED <n>"
# lines let the wrapper compare that both agreed on the same bag seed.

func _init() -> void:
	_run("HOST")

func _run(side: String) -> void:
	await process_frame
	var lobby: Node = (load("res://scenes/lobby.tscn") as PackedScene).instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	lobby._on_host_pressed()
	# wait (max ~20s) for the seed handshake to move us into the versus scene
	var in_versus := false
	for _i in 1200:
		await process_frame
		if is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/versus.tscn":
			in_versus = true
			break
	if not in_versus:
		print(side + "_FAIL: match never started")
		quit(1)
		return
	var versus: Node = current_scene
	var mirror: TileMapLayer = versus.get_node("OpponentBoard/Board")
	# play two pieces so the other machine has something to mirror
	await process_frame
	versus.get_node("MyBoard").hard_drop()
	versus.get_node("MyBoard").hard_drop()
	# pass when the other side's two pieces show up on our mirror
	# (64 wall tiles + 8 piece cells)
	for _i in 900:
		await process_frame
		if not is_instance_valid(mirror):
			break # opponent already quit and we fell back to the lobby
		if mirror.get_used_cells().size() >= 72:
			print(side + "_OK SEED ", Lobby.match_seed, " MIRROR_CELLS ", mirror.get_used_cells().size())
			quit(0)
			return
	print(side + "_FAIL: mirror never showed the opponent's pieces")
	quit(1)
