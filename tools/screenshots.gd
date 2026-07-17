extends SceneTree
# Reproducible screenshot generator for the tutorial. Needs a real window
# (rendering does not happen under --headless), so run WITHOUT --headless:
#   godot -s res://tools/screenshots.gd
# Writes PNGs to docs/img/. Game states are seeded, so re-running after
# code changes regenerates identical-layout, up-to-date images.

const OUT_DIR := "res://docs/img/"

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	# --- shot 1: the lobby ---
	var lobby: Node = (load("res://scenes/lobby.tscn") as PackedScene).instantiate()
	root.add_child(lobby)
	await _snap("lobby.png")
	lobby.queue_free()
	await process_frame

	# --- shot 2: solo game in progress (seeded, so always the same) ---
	var solo: Node = (load("res://scenes/solo.tscn") as PackedScene).instantiate()
	root.add_child(solo)
	var board: Node = solo.get_node("Board")
	board.new_game(42)
	board.hold_piece() # fill the HOLD panel
	for _i in 6:
		board.hard_drop() # build a small stack
	await _snap("solo-game.png")
	solo.queue_free()
	await process_frame
	quit(0)

# waits for the next rendered frame, then saves the window to a PNG
func _snap(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var err := img.save_png(OUT_DIR + file_name)
	print("SAVED " if err == OK else "FAILED ", file_name, " (", img.get_width(), "x", img.get_height(), ")")
