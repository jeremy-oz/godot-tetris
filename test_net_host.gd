extends SceneTree
# headless end-to-end network test, host side. Run both processes:
#   godot --headless -s res://test_net_host.gd    (start this first)
#   godot --headless -s res://test_net_client.gd  (then this one)
# Each side prints "<SIDE>_OK SEED <n>" after landing in the versus scene;
# compare the two seeds to confirm the handshake delivered the same bag.

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	var lobby: Node = (load("res://scenes/lobby.tscn") as PackedScene).instantiate()
	root.add_child(lobby)
	current_scene = lobby
	await process_frame
	lobby._on_host_pressed()
	# wait (max ~20s) for the guest to join and the handshake to move us on
	for _i in 1200:
		await process_frame
		if is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/versus.tscn":
			print("HOST_OK SEED ", Lobby.match_seed)
			quit(0)
			return
	print("HOST_FAIL: match never started")
	quit(1)
