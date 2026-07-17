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
	for _i in 1200:
		await process_frame
		if is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/versus.tscn":
			print("CLIENT_OK SEED ", Lobby.match_seed)
			quit(0)
			return
	print("CLIENT_FAIL: match never started")
	quit(1)
