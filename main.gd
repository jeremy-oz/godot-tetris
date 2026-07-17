extends Node2D

# Since Godot 4.3 the TileMap node (one node holding many layers) is
# deprecated. Each layer is now its own TileMapLayer node, so the board
# and the falling piece live in sibling nodes that share one TileSet.
@onready var board: TileMapLayer = $Board   # walls + landed pieces
@onready var ghost: TileMapLayer = $Ghost   # landing preview (semi-transparent)
@onready var active: TileMapLayer = $Active # falling piece + next/hold panels

@onready var score_label: Label = $HUD/ScoreLabel
@onready var lines_label: Label = $HUD/LinesLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var game_over_label: Label = $HUD/GameOverLabel
@onready var start_button: Button = $HUD/StartButton

#tetrominoes — 4 rotation states each, in SRS order: 0=spawn, 1=CW, 2=180, 3=CCW
var i_0 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
var i_90 := [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]
var i_180 := [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
var i_270 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
var i := [i_0, i_90, i_180, i_270]

var t_0 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var t_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var t_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var t_270 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
var t := [t_0, t_90, t_180, t_270]

var o_0 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_90 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_180 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_270 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o := [o_0, o_90, o_180, o_270]

var z_0 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
var z_90 := [Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var z_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]
var z_270 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
var z := [z_0, z_90, z_180, z_270]

var s_0 := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
var s_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
var s_180 := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)]
var s_270 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
var s := [s_0, s_90, s_180, s_270]

var l_0 := [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var l_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]
var l_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)]
var l_270 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
var l := [l_0, l_90, l_180, l_270]

var j_0 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var j_90 := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)]
var j_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
var j_270 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
var j := [j_0, j_90, j_180, j_270]

var shapes := [i, t, o, z, s, l, j]
var shapes_full := shapes.duplicate()

#grid variables
const COLS: int = 10
const ROWS: int = 20

#SRS wall kicks — spec data copied from the Tetris Guideline.
#When a rotation collides, each offset is tried in order; the first that fits wins.
#Key = Vector2i(from_state, to_state). The published tables use y-up math
#coordinates; the y values here are already flipped for Godot's y-down grid.
const KICKS_JLSTZ := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
}
const KICKS_I := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
}

#movement timing (all in seconds, so behavior is identical at any frame rate)
const DAS: float = 0.17         #held key: delay before auto-repeat starts
const ARR: float = 0.05         #held key: interval between repeats
const SOFT_DROP_INTERVAL: float = 0.04
const LOCK_DELAY: float = 0.5   #grace period once the piece rests on the stack
const MAX_LOCK_RESETS: int = 15 #moves/rotations allowed to restart that grace period

const start_pos := Vector2i(4, 1)
var cur_pos: Vector2i
var gravity_timer: float
var das_dir: int
var das_timer: float
var lock_timer: float
var lock_resets: int

#game piece variables
var piece_type: Array
var next_piece_type: Array
var hold_type: Array
var rotation_index: int
var active_piece: Array
var can_hold: bool

#game variables
const LINE_SCORES := [0, 100, 300, 500, 800] #indexed by lines cleared at once
var score: int
var lines: int
var level: int
var game_running: bool

#tilemap variables
var tile_id: int = 0
var piece_atlas: Vector2i
var next_piece_atlas: Vector2i
var hold_atlas: Vector2i

func _ready() -> void:
	#a focused button would also react to Space (hard drop) and the arrow keys
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.pressed.connect(new_game)
	new_game()

func new_game() -> void:
	#reset variables
	score = 0
	lines = 0
	level = 1
	game_running = true
	das_dir = 0
	hold_type = []
	can_hold = true
	game_over_label.hide()
	#clear everything
	active.clear()
	ghost.clear()
	clear_board()
	shapes = shapes_full.duplicate()
	piece_type = pick_piece()
	piece_atlas = Vector2i(shapes_full.find(piece_type), 0)
	next_piece_type = pick_piece()
	next_piece_atlas = Vector2i(shapes_full.find(next_piece_type), 0)
	update_labels()
	create_piece()

func _process(delta: float) -> void:
	if not game_running:
		return
	handle_horizontal(delta)
	if Input.is_action_just_pressed("rotate_cw"):
		try_rotate(1)
	if Input.is_action_just_pressed("rotate_ccw"):
		try_rotate(-1)
	if Input.is_action_just_pressed("hold"):
		hold_piece()
	if Input.is_action_just_pressed("hard_drop"):
		hard_drop()
		return
	apply_gravity(delta)

func handle_horizontal(delta: float) -> void:
	var dir := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if dir == 0:
		das_dir = 0
		return
	if dir != das_dir:
		#fresh press: move once, then wait DAS before repeating
		das_dir = dir
		das_timer = DAS
		try_move(Vector2i(dir, 0))
	else:
		das_timer -= delta
		while das_timer <= 0.0:
			das_timer += ARR
			try_move(Vector2i(dir, 0))

func apply_gravity(delta: float) -> void:
	if not game_running:
		return
	var soft := Input.is_action_pressed("soft_drop")
	var interval := fall_interval()
	if soft:
		interval = minf(interval / 20.0, SOFT_DROP_INTERVAL)
	if can_move(Vector2i.DOWN):
		lock_timer = 0.0
		gravity_timer += delta
		while gravity_timer >= interval:
			gravity_timer -= interval
			if not can_move(Vector2i.DOWN):
				break
			shift_piece(Vector2i.DOWN)
			if soft:
				score += 1
				update_labels()
	else:
		gravity_timer = 0.0
		lock_timer += delta
		if lock_timer >= LOCK_DELAY:
			lock_piece()

func fall_interval() -> float:
	#seconds per row at the current level (Tetris Guideline gravity curve)
	return pow(0.8 - (level - 1) * 0.007, level - 1)

func pick_piece() -> Array:
	if shapes.is_empty():
		shapes = shapes_full.duplicate()
	shapes.shuffle()
	return shapes.pop_front()

func create_piece() -> void:
	#reset per-piece variables
	rotation_index = 0
	gravity_timer = 0.0
	lock_timer = 0.0
	lock_resets = 0
	#the O piece sits in the left of its box, so nudge it right to spawn centered
	cur_pos = start_pos + Vector2i(1, 0) if piece_type == o else start_pos
	active_piece = piece_type[rotation_index]
	draw_piece(active_piece, cur_pos, piece_atlas)
	update_ghost()
	#show next piece
	draw_piece(next_piece_type[0], Vector2i(15, 6), next_piece_atlas)

func clear_piece() -> void:
	for cell in active_piece:
		active.erase_cell(cur_pos + cell)

func draw_piece(piece: Array, pos: Vector2i, atlas: Vector2i) -> void:
	for cell in piece:
		active.set_cell(pos + cell, tile_id, atlas)

func try_rotate(dir: int) -> void:
	var new_index := posmod(rotation_index + dir, 4)
	var kicks: Array = [Vector2i.ZERO]
	if piece_type == i:
		kicks = KICKS_I[Vector2i(rotation_index, new_index)]
	elif piece_type != o:
		kicks = KICKS_JLSTZ[Vector2i(rotation_index, new_index)]
	for kick in kicks:
		if piece_fits(piece_type[new_index], cur_pos + kick):
			clear_piece()
			rotation_index = new_index
			active_piece = piece_type[rotation_index]
			cur_pos += kick
			draw_piece(active_piece, cur_pos, piece_atlas)
			reset_lock_delay()
			update_ghost()
			return

func try_move(dir: Vector2i) -> void:
	if can_move(dir):
		shift_piece(dir)
		reset_lock_delay()

func shift_piece(dir: Vector2i) -> void:
	clear_piece()
	cur_pos += dir
	draw_piece(active_piece, cur_pos, piece_atlas)
	if dir == Vector2i.DOWN:
		#reaching a new row grants a fresh set of lock-delay resets
		lock_resets = 0
	update_ghost()

func reset_lock_delay() -> void:
	#a grounded piece gets LOCK_DELAY of grace again after each move/rotation,
	#but only MAX_LOCK_RESETS times so it cannot hover forever
	if not can_move(Vector2i.DOWN) and lock_resets < MAX_LOCK_RESETS:
		lock_timer = 0.0
		lock_resets += 1

func can_move(dir: Vector2i) -> bool:
	return piece_fits(active_piece, cur_pos + dir)

func piece_fits(piece: Array, pos: Vector2i) -> bool:
	for cell in piece:
		if not is_free(pos + cell):
			return false
	return true

func is_free(pos: Vector2i) -> bool:
	return board.get_cell_source_id(pos) == -1

func drop_distance() -> int:
	var dist := 0
	while piece_fits(active_piece, cur_pos + Vector2i(0, dist + 1)):
		dist += 1
	return dist

func update_ghost() -> void:
	ghost.clear()
	var offset := Vector2i(0, drop_distance())
	for cell in active_piece:
		ghost.set_cell(cur_pos + offset + cell, tile_id, piece_atlas)

func hard_drop() -> void:
	var dist := drop_distance()
	if dist > 0:
		clear_piece()
		cur_pos += Vector2i(0, dist)
		draw_piece(active_piece, cur_pos, piece_atlas)
		score += 2 * dist
	lock_piece()

func hold_piece() -> void:
	if not can_hold:
		return
	can_hold = false #one hold per piece; re-enabled when a piece locks
	clear_piece()
	ghost.clear()
	var swapped := hold_type
	hold_type = piece_type
	hold_atlas = piece_atlas
	clear_hold_panel()
	draw_piece(hold_type[0], Vector2i(15, 11), hold_atlas)
	if swapped.is_empty():
		#nothing held yet: pull the next piece from the queue instead
		advance_queue()
	else:
		piece_type = swapped
		piece_atlas = Vector2i(shapes_full.find(piece_type), 0)
	create_piece()
	check_game_over()

func lock_piece() -> void:
	land_piece()
	var cleared := check_rows()
	if cleared > 0:
		lines += cleared
		score += LINE_SCORES[cleared] * level
		level = mini(1 + floori(lines / 10.0), 20)
	update_labels()
	advance_queue()
	can_hold = true
	create_piece()
	check_game_over()

func advance_queue() -> void:
	piece_type = next_piece_type
	piece_atlas = next_piece_atlas
	next_piece_type = pick_piece()
	next_piece_atlas = Vector2i(shapes_full.find(next_piece_type), 0)
	clear_next_panel()

func land_piece() -> void:
	#remove each segment from the active layer and move to the board layer
	for cell in active_piece:
		active.erase_cell(cur_pos + cell)
		board.set_cell(cur_pos + cell, tile_id, piece_atlas)

func clear_next_panel() -> void:
	for x in range(14, 19):
		for y in range(5, 9):
			active.erase_cell(Vector2i(x, y))

func clear_hold_panel() -> void:
	for x in range(14, 19):
		for y in range(10, 15):
			active.erase_cell(Vector2i(x, y))

func check_rows() -> int:
	var cleared := 0
	var row: int = ROWS
	while row > 0:
		var count := 0
		for col in range(COLS):
			if not is_free(Vector2i(col + 1, row)):
				count += 1
		#if row is full then erase it
		if count == COLS:
			shift_rows(row)
			cleared += 1
		else:
			row -= 1
	return cleared

func shift_rows(row: int) -> void:
	var atlas: Vector2i
	for y in range(row, 1, -1):
		for col in range(COLS):
			atlas = board.get_cell_atlas_coords(Vector2i(col + 1, y - 1))
			if atlas == Vector2i(-1, -1):
				board.erase_cell(Vector2i(col + 1, y))
			else:
				board.set_cell(Vector2i(col + 1, y), tile_id, atlas)
	#the loop above stops at row 2, so empty the top row by hand — otherwise
	#clearing a full top row would loop forever in check_rows()
	for col in range(COLS):
		board.erase_cell(Vector2i(col + 1, 1))

func clear_board() -> void:
	for y in range(ROWS):
		for col in range(COLS):
			board.erase_cell(Vector2i(col + 1, y + 1))

func update_labels() -> void:
	score_label.text = "SCORE: " + str(score)
	lines_label.text = "LINES: " + str(lines)
	level_label.text = "LEVEL: " + str(level)

func check_game_over() -> void:
	if piece_fits(active_piece, cur_pos):
		return
	land_piece()
	ghost.clear()
	game_over_label.show()
	game_running = false
