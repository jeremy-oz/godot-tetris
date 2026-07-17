extends SceneTree
# headless test harness — not part of the game scene.
# run with:  godot --headless -s res://test_headless.gd

var failures: Array[String] = []

func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: " + label)
	else:
		failures.append(label)
		print("FAIL: " + label)

# true when two boards show the same picture (same cells, same tiles).
# comparing tile_map_data bytes is NOT reliable: the serialization is not
# byte-stable across an assign/read round-trip, only the content is.
func boards_mirror(x: Node, y: Node) -> bool:
	for layer_name in ["Board", "Active", "Ghost"]:
		var lx: TileMapLayer = x.get_node(layer_name)
		var ly: TileMapLayer = y.get_node(layer_name)
		var cells: Array = lx.get_used_cells()
		if cells.size() != ly.get_used_cells().size():
			return false
		for cell in cells:
			if lx.get_cell_atlas_coords(cell) != ly.get_cell_atlas_coords(cell):
				return false
	return true

func force_piece(m: Node, shape: Array) -> void:
	m.clear_piece()
	m.ghost.clear()
	m.piece_type = shape
	m.piece_atlas = Vector2i(m.shapes_full.find(shape), 0)
	m.create_piece()

func _init() -> void:
	run_tests()

func run_tests() -> void:
	# _ready only fires once the tree starts iterating, so wait a frame first
	await process_frame
	var scene: Node = (load("res://scenes/solo.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	# all gameplay lives on the board instance, exactly as in solo mode
	var main: Node = scene.get_node("Board")

	# --- basic spawn state ---
	check(main.game_running, "game starts running")
	check(main.active_piece.size() == 4, "active piece has 4 cells")
	check(main.piece_fits(main.active_piece, main.cur_pos), "spawned piece fits")

	# --- ghost piece matches active piece shifted by drop distance ---
	var drop: int = main.drop_distance()
	check(drop > 0, "fresh piece has positive drop distance")
	var ghost_cells: Array = main.ghost.get_used_cells()
	var expected: Array = []
	for cell in main.active_piece:
		expected.append(main.cur_pos + Vector2i(0, drop) + cell)
	ghost_cells.sort()
	expected.sort()
	check(ghost_cells == expected, "ghost = active piece + drop distance")

	# --- SRS wall kick: T against the left wall ---
	main.new_game()
	force_piece(main, main.t)
	main.clear_piece()
	main.rotation_index = 1 # T pointing right
	main.active_piece = main.t[1]
	main.cur_pos = Vector2i(0, 5) # box flush against left wall, still valid
	main.draw_piece(main.active_piece, main.cur_pos, main.piece_atlas)
	main.update_ghost()
	main.try_rotate(-1) # back to spawn state: only fits with the (+1,0) kick
	check(main.rotation_index == 0, "wall kick: rotation succeeded")
	check(main.cur_pos == Vector2i(1, 5), "wall kick: piece kicked right by 1")

	# --- SRS wall kick: vertical I against the left wall ---
	main.new_game()
	force_piece(main, main.i)
	main.clear_piece()
	main.rotation_index = 1 # vertical, cells in column 2 of its box
	main.active_piece = main.i[1]
	main.cur_pos = Vector2i(-1, 5) # cells sit in board column 1
	main.draw_piece(main.active_piece, main.cur_pos, main.piece_atlas)
	main.update_ghost()
	main.try_rotate(1) # to 180: in-place and (-1,0) hit the wall, (+2,0) fits
	check(main.rotation_index == 2, "I kick: rotation succeeded")
	check(main.cur_pos == Vector2i(1, 5), "I kick: piece kicked right by 2")

	# --- rotation blocked when nothing fits ---
	main.new_game()
	force_piece(main, main.i)
	main.clear_piece()
	main.rotation_index = 0
	main.active_piece = main.i[0]
	main.cur_pos = Vector2i(1, 18) # near the floor
	# wall off every kick target by filling the two rows above the floor
	for x in range(1, 11):
		main.board.set_cell(Vector2i(x, 17), 0, Vector2i(0, 0))
		main.board.set_cell(Vector2i(x, 18), 0, Vector2i(0, 0))
	main.board.erase_cell(Vector2i(1, 18)) # hole so gravity test stays valid
	var before_rot: int = main.rotation_index
	main.try_rotate(1)
	check(main.rotation_index == before_rot, "rotation cancelled when no kick fits")

	# --- hard drop locks the piece and scores 2 per cell ---
	main.new_game()
	var score_before: int = main.score
	var dist: int = main.drop_distance()
	var board_before: int = main.board.get_used_cells().size()
	main.hard_drop()
	check(main.board.get_used_cells().size() == board_before + 4, "hard drop: 4 cells landed")
	check(main.score == score_before + 2 * dist, "hard drop: +2 points per cell")
	check(main.piece_fits(main.active_piece, main.cur_pos), "hard drop: next piece spawned")

	# --- hold: first hold stores piece, second hold is refused ---
	main.new_game()
	var first: Array = main.piece_type
	var queued: Array = main.next_piece_type
	main.hold_piece()
	check(main.hold_type == first, "hold: piece stored")
	check(main.piece_type == queued, "hold: next piece became active")
	check(not main.can_hold, "hold: disabled until lock")
	var current: Array = main.piece_type
	main.hold_piece()
	check(main.piece_type == current, "hold: second hold refused")

	# --- hold swap: after a lock, holding swaps with the stored piece ---
	main.hard_drop() # locks, re-enables hold
	var active_now: Array = main.piece_type
	var held: Array = main.hold_type
	main.hold_piece()
	check(main.piece_type == held and main.hold_type == active_now, "hold: swap works")

	# --- line clear ---
	main.new_game()
	for x in range(1, 11):
		main.board.set_cell(Vector2i(x, 20), 0, Vector2i(0, 0))
	main.board.set_cell(Vector2i(5, 19), 0, Vector2i(0, 0)) # one block above
	var cleared: int = main.check_rows()
	check(cleared == 1, "line clear: one full row detected")
	check(main.is_free(Vector2i(1, 19)), "line clear: row above shifted down")
	check(not main.is_free(Vector2i(5, 20)), "line clear: block above landed on floor row")

	# --- scoring/level bookkeeping via lock_piece ---
	main.new_game()
	main.lines = 9
	for x in range(1, 11):
		main.board.set_cell(Vector2i(x, 20), 0, Vector2i(0, 0))
	for cell in main.active_piece: # avoid double-land collisions: park piece high
		pass
	var pts_before: int = main.score
	main.clear_piece()
	main.cur_pos = Vector2i(4, 2)
	main.draw_piece(main.active_piece, main.cur_pos, main.piece_atlas)
	main.lock_piece()
	check(main.lines == 10, "scoring: line total updated")
	check(main.level == 2, "scoring: level up at 10 lines")
	check(main.score == pts_before + 100 * 1, "scoring: single = 100 x level(1)")
	check(main.fall_interval() < 1.0, "gravity: level 2 falls faster than level 1")

	# --- game over: blocked spawn ends the game ---
	main.new_game()
	for y in range(2, 20): # tower up the middle, right under the spawn box
		main.board.set_cell(Vector2i(5, y), 0, Vector2i(0, 0))
	main.hard_drop() # locks at/near spawn; next spawn must collide
	check(not main.game_running, "game over: blocked spawn stops the game")

	# --- full top row clears without freezing (regression: shift_rows row 1) ---
	main.new_game()
	for x in range(1, 11):
		main.board.set_cell(Vector2i(x, 1), 0, Vector2i(0, 0))
	check(main.check_rows() == 1, "top row: clears exactly once")
	check(main.is_free(Vector2i(5, 1)), "top row: actually emptied")

	# --- seeded bag: same seed deals the identical piece sequence ---
	var board_scene: PackedScene = load("res://scenes/board.tscn")
	var board_a: Node = board_scene.instantiate()
	var board_b: Node = board_scene.instantiate()
	root.add_child(board_a)
	root.add_child(board_b)
	# a board that was never started must look idle, not dead
	check(not board_a.get_node("GameOverLabel").visible, "fresh board: no game-over label")
	board_a.new_game(1234)
	board_b.new_game(1234)
	var same: bool = board_a.piece_type == board_b.piece_type \
			and board_a.next_piece_type == board_b.next_piece_type
	for _i in 20:
		same = same and board_a.pick_piece() == board_b.pick_piece()
	check(same, "seeded bag: same seed deals identical pieces")

	# --- seeded bag: different seeds diverge ---
	board_a.new_game(1)
	board_b.new_game(2)
	var diverged := false
	for _i in 20:
		if board_a.pick_piece() != board_b.pick_piece():
			diverged = true
			break
	check(diverged, "seeded bag: different seeds deal different pieces")

	# --- unseeded games are not all identical (solo stays random) ---
	board_a.new_game()
	board_b.new_game()
	diverged = false
	for _i in 30:
		if board_a.pick_piece() != board_b.pick_piece():
			diverged = true
			break
	check(diverged, "unseeded bag: solo games stay random")

	# --- mirror: capture/apply reproduces the source board exactly ---
	board_a.new_game(99)
	board_a.hard_drop()
	var state: Array = board_a.capture_display()
	var mirror_board: Node = board_scene.instantiate()
	root.add_child(mirror_board)
	mirror_board.apply_display(state)
	check(boards_mirror(board_a, mirror_board), "mirror: all three layers copied exactly")
	check(mirror_board.score_label.text == board_a.score_label.text, "mirror: score label copied")
	check(not mirror_board.game_running, "mirror: applying state does not start the mirror")

	# --- display_changed: emitted on the frame after visible activity ---
	var pings: Array = [0]
	board_a.display_changed.connect(func() -> void: pings[0] += 1)
	board_a.hard_drop() # marks the display dirty
	await process_frame
	check(pings[0] >= 1, "mirror: display_changed fires after activity")

	# --- lobby scene loads with the right menus showing ---
	var lobby: Node = (load("res://scenes/lobby.tscn") as PackedScene).instantiate()
	root.add_child(lobby)
	check(lobby.get_node("MainMenu").visible, "lobby: main menu visible")
	check(not lobby.get_node("JoinMenu").visible, "lobby: join menu hidden")
	check(not lobby.get_node("WaitMenu").visible, "lobby: wait menu hidden")

	# --- versus scene: my board runs, opponent board waits for step 3 ---
	var versus: Node = (load("res://scenes/versus.tscn") as PackedScene).instantiate()
	root.add_child(versus)
	check(versus.get_node("MyBoard").game_running, "versus: my board started")
	check(not versus.get_node("OpponentBoard").game_running, "versus: opponent board waits")

	# --- versus relay: a received state lands on the mirror board ---
	versus._receive_display(board_a.capture_display())
	check(boards_mirror(board_a, versus.get_node("OpponentBoard")),
			"versus: received state painted onto the mirror")

	# --- garbage: queued rows rise from the bottom when the piece locks ---
	var gboard: Node = board_scene.instantiate()
	root.add_child(gboard)
	gboard.new_game(5)
	gboard.queue_garbage(1)
	gboard.queue_garbage(2) # attacks accumulate
	gboard.hard_drop()
	var glayer: TileMapLayer = gboard.get_node("Board")
	var garbage_rows_ok := true
	var holes: Array = []
	for y in range(18, 21):
		var filled := 0
		for col in range(1, 11):
			if glayer.get_cell_atlas_coords(Vector2i(col, y)) == Vector2i(7, 0):
				filled += 1
			elif glayer.get_cell_source_id(Vector2i(col, y)) == -1:
				holes.append(col)
		garbage_rows_ok = garbage_rows_ok and filled == 9
	check(garbage_rows_ok, "garbage: three rows of 9 grey tiles at the bottom")
	check(holes.size() == 3 and holes[0] == holes[1] and holes[1] == holes[2],
			"garbage: one shared hole column to dig through")
	check(gboard.pending_garbage == 0, "garbage: queue emptied after insertion")

	# --- lines_cleared signal reports the clear count ---
	var clears: Array = [0]
	gboard.lines_cleared.connect(func(n: int) -> void: clears[0] = n)
	for x in range(1, 11):
		glayer.set_cell(Vector2i(x, 20), 0, Vector2i(0, 0))
	gboard.clear_piece()
	gboard.cur_pos = Vector2i(4, 2)
	gboard.draw_piece(gboard.active_piece, gboard.cur_pos, gboard.piece_atlas)
	gboard.lock_piece()
	check(clears[0] == 1, "lines_cleared: reports a single clear")

	# --- versus end flow: lose, late-win guard, rematch, win ---
	versus._on_topped_out() # the RPC inside is a no-op with no peer
	check(versus.result_label.visible and versus.result_label.text == "YOU LOSE!",
			"versus: topping out shows YOU LOSE")
	versus._notify_win() # a win notice arriving after the match ended
	check(versus.result_label.text == "YOU LOSE!", "versus: late win notice ignored")
	versus._do_rematch(77)
	check(not versus.result_label.visible and versus.my_board.game_running,
			"versus: rematch restarts the board")
	check(versus.get_node("OpponentBoard/Board").get_used_cells().size() == 64,
			"versus: rematch blanks the mirror")
	board_a.new_game(77)
	check(board_a.piece_type == versus.my_board.piece_type,
			"versus: rematch seed deals the same pieces")
	versus._notify_win()
	check(versus.result_label.text == "YOU WIN!" and not versus.my_board.game_running,
			"versus: opponent loss shows YOU WIN")

	print("----")
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d FAILURES" % failures.size())
		quit(1)
