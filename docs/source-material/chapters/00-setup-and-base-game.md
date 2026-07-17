# Chapter 00 — Setup and the base game

**Git ref:** `cc24395` (original import) → `8dd7449` (Godot 4.7 upgrade).
The upgraded base game is the students' starting build target: one script
(~240 lines), one scene, one sprite sheet.

**Learning goals:** Godot project anatomy, TileMapLayer as a game grid,
the `_process` loop, arrays of coordinates as shapes, collision as lookup.

## Setup facts

- Godot 4.7.x (Forward Plus). Window 650×704, stretch `canvas_items`/`keep`.
- Assets: `assets/tetrominoes.png` — 8 tiles of 32×32 in one row: 7 piece
  colors + grey. One `TileSet` with `texture_region_size = 32×32`; all
  layers share it.
- The original art/code base is russs123's `tetris_tut` (MIT), upgraded:
  deprecated `TileMap` (multi-layer node) → separate `TileMapLayer` nodes.
  If students start directly in 4.7 they never see the old API; the
  upgrade diff (`git diff cc24395 8dd7449`) is optional background.

## What gets built

Scene: a Node2D root with two TileMapLayers — `Board` (walls painted in
the editor around a 10×20 well: borders at x=0, x=11, y=0, y=21) and
`Active` (falling piece + next-piece preview) — plus HUD labels/button.

Core script concepts, in build order:

1. **Pieces as data.** Each tetromino = 4 arrays (rotation states) of 4
   `Vector2i` cell offsets. State order matters later (SRS): 0 spawn,
   1 CW, 2 180°, 3 CCW. See reference.md piece facts.
2. **The bag.** `pick_piece()` deals from `shapes`, refilling from
   `shapes_full` when empty — this IS a real "7-bag" randomizer, a
   Guideline feature, worth naming.
3. **Drawing = cells.** `draw_piece`/`clear_piece` set/erase Active-layer
   cells at `cur_pos + cell`. There is no sprite movement anywhere.
4. **Collision is a lookup.** `is_free(pos)` = "no cell painted on the
   Board layer there". Walls block movement with zero special code.
5. **Falling and landing.** Gravity moves the piece down; when a down-move
   fails, `land_piece()` copies its cells onto the Board layer and the
   next piece spawns.
6. **Line clears.** `check_rows()` scans rows 20→1; a full row is removed
   by `shift_rows()` copying everything above down one.
7. **Game over.** New piece spawns overlapping the stack → stop.

## Verify

Run (F5): pieces fall, stack, clear lines; score counts; NEW GAME resets.

## Screenshots

`docs/img/solo-game.png` shows the finished game *after* chapters 01–05 —
usable in ch00 as "where we're heading". A plain base-game shot can be
staged in `tools/screenshots.gd` if wanted.

## Pitfalls

- Painting the walls: they live on the **Board** layer; if painted on
  Active they'd be erased by piece drawing.
- The ceiling (y=0) exists; spawn position must keep the piece box below it.
- gotchas.md #3 (button focus) applies from the first NEW GAME button.

## Split point

This chapter is large. Natural split: (a) project+scene+piece data with a
piece drawn statically, (b) movement+landing, (c) line clears+game over.
