# Chapter 02 — Hard drop and the ghost piece

**Git ref:** part of `b08589a` (functions `drop_distance`, `hard_drop`,
`update_ghost`; new `Ghost` TileMapLayer in board.tscn).

**Learning goals:** extracting a shared helper (DRY), layers as rendering
tricks (modulate), scoring hooks.

## The key insight to teach

Both features are the same question — "how far can this piece fall?" —
so both are built on ONE helper:

```gdscript
func drop_distance() -> int:
    var dist := 0
    while piece_fits(active_piece, cur_pos + Vector2i(0, dist + 1)):
        dist += 1
    return dist
```

Because hard drop and the ghost share it, they can never disagree: the
ghost is a *promise* the hard drop always keeps.

## What gets built

1. **Hard drop** (Space): move down by `drop_distance()`, +2 points per
   cell, lock immediately.
2. **Ghost layer**: a third TileMapLayer (`Ghost`) between Board and
   Active, same TileSet, `modulate = Color(1,1,1,0.1)` — same tiles, drawn
   translucent. `update_ghost()` clears it and redraws the piece shifted
   down by `drop_distance()`; call it after every spawn/move/rotate.
   Node order makes a grounded ghost hide behind the real piece.

## Verify

Ghost always matches where Space actually puts the piece — move/rotate
around overhangs and confirm. Screenshots: `solo-game.png` (ghost visible
above the stack), `wallkick-before.png` (ghost at bottom of empty well).

## Pitfalls

- Erase the piece from Active BEFORE landing it on Board, or stale cells
  linger (ordering inside `hard_drop`).
- Forgetting one `update_ghost()` call site (e.g. after rotation) leaves a
  lying ghost — students find this genuinely fun to hunt.
- The ghost must be cleared on game over (`ghost.clear()`).
