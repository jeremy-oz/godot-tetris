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
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
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

	print("----")
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d FAILURES" % failures.size())
		quit(1)
