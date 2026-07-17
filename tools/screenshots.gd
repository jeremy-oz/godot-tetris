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
	var board_scene: PackedScene = load("res://scenes/board.tscn")

	# --- the lobby and its join menu ---
	var lobby: Node = (load("res://scenes/lobby.tscn") as PackedScene).instantiate()
	root.add_child(lobby)
	await _snap("lobby.png")
	lobby._on_join_pressed()
	await _snap("join-menu.png")
	lobby.queue_free()
	await process_frame

	# --- solo game in progress (seeded, so always the same picture) ---
	var solo: Node = (load("res://scenes/solo.tscn") as PackedScene).instantiate()
	root.add_child(solo)
	var board: Node = solo.get_node("Board")
	board.new_game(42)
	board.hold_piece() # fill the HOLD panel
	for _i in 6:
		board.hard_drop() # build a small stack
	await _snap("solo-game.png")

	# --- garbage rows risen on the same board ---
	board.queue_garbage(3)
	board.hard_drop()
	await _snap("garbage.png")
	solo.queue_free()
	await process_frame

	# --- wall kick, before and after ---
	var solo2: Node = (load("res://scenes/solo.tscn") as PackedScene).instantiate()
	root.add_child(solo2)
	var board2: Node = solo2.get_node("Board")
	board2.new_game(1)
	# stage a T piece pointing right, flush against the left wall: rotating
	# it back to spawn state only fits thanks to the (+1, 0) wall kick
	board2.clear_piece()
	board2.piece_type = board2.t
	board2.piece_atlas = Vector2i(board2.shapes_full.find(board2.t), 0)
	board2.rotation_index = 1
	board2.active_piece = board2.t[1]
	board2.cur_pos = Vector2i(0, 10)
	board2.draw_piece(board2.active_piece, board2.cur_pos, board2.piece_atlas)
	board2.update_ghost()
	await _snap("wallkick-before.png")
	board2.try_rotate(-1)
	await _snap("wallkick-after.png")
	solo2.queue_free()
	await process_frame

	# --- versus mode with a staged opponent, then the win screen ---
	var versus: Node = (load("res://scenes/versus.tscn") as PackedScene).instantiate()
	root.add_child(versus) # widens the window to 1300x704
	await process_frame
	var mine: Node = versus.get_node("MyBoard")
	for _i in 4:
		mine.hard_drop()
	# fake the remote player: a staging board parked below the visible
	# canvas plays a different game, and its captured display is applied
	# to the mirror exactly as the network would
	var staged: Node = board_scene.instantiate()
	root.add_child(staged)
	staged.position = Vector2(0, 3000)
	staged.new_game(7)
	staged.hold_piece()
	for _i in 5:
		staged.hard_drop()
	staged.queue_garbage(2)
	staged.hard_drop()
	versus._receive_display(staged.capture_display())
	await _snap("versus.png")
	versus._notify_win()
	await _snap("versus-win.png")
	quit(0)

# waits for the next rendered frame, then saves the window to a PNG
func _snap(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var err := img.save_png(OUT_DIR + file_name)
	print("SAVED " if err == OK else "FAILED ", file_name, " (", img.get_width(), "x", img.get_height(), ")")
