# Chapter 03 — Both rotations and SRS wall kicks

**Git ref:** part of `b08589a` (function `try_rotate`, consts
`KICKS_JLSTZ`/`KICKS_I`, `rotate_ccw` input).

**Learning goals:** generalizing a function with a parameter; implementing
a published specification; separating algorithm (written by students) from
data (copied from the spec).

## Design decision to state explicitly

Full SRS kick tables are ~25 lines of coordinate data students cannot
derive. The intended pedagogy: **students write the algorithm, copy the
data** — like physics constants. They validate the copied data
behaviorally (see Verify). A simpler alternative ("try shifting left,
right, up" — ~8 lines, no tables) gives 90% of the feel; the pack assumes
full SRS but the tutorial may offer the simple version first and SRS as
the "how the pros do it" upgrade.

## What gets built

1. **CCW rotation**: `rotate_piece()` becomes `try_rotate(dir: int)` with
   `posmod(rotation_index + dir, 4)`; Z key sends -1, Up/X send +1.
2. **The kick algorithm** (the students' part):

```gdscript
func try_rotate(dir: int) -> void:
    var new_index := posmod(rotation_index + dir, 4)
    var kicks: Array = [Vector2i.ZERO]
    if piece_type == i:
        kicks = KICKS_I[Vector2i(rotation_index, new_index)]
    elif piece_type != o:
        kicks = KICKS_JLSTZ[Vector2i(rotation_index, new_index)]
    for kick in kicks:
        if piece_fits(piece_type[new_index], cur_pos + kick):
            # apply rotation at cur_pos + kick, update ghost, done
            ...
            return
    # nothing fit: rotation is cancelled
```

3. **The tables** (the copied part): keyed `Vector2i(from_state, to_state)`,
   5 offsets each, 8 transitions per table; full values in reference.md.
   CRITICAL: published tables are y-up; ours are already y-flipped for
   Godot (gotchas.md #4). O rotates in place (`[Vector2i.ZERO]`).

## Why the piece data already fits SRS

The base tutorial's hardcoded rotation states happen to match SRS spawn
orientations, bounding boxes, and CW state order exactly — verified during
development. So the tables drop in with no rework. Worth telling students:
data conventions compose when both sides follow the same spec.

## Verify (the copied-data checklist)

- I piece vertical against the left wall, rotate: it kicks 2 right
  (`wallkick-before.png` shows the setup for the T version).
- T pointing right, flush on the left wall, rotate CCW: kicks 1 right
  (`wallkick-before.png` → `wallkick-after.png`).
- In a slot where nothing fits, rotation does nothing (no teleporting).
- Headless tests cover all three (`wall kick`, `I kick`, `rotation
  cancelled` tests).

## Pitfalls

- `posmod`, not `%`: GDScript `%` returns negative for negative operands.
- Kick table lookup only has adjacent transitions (no 0→2): correct — you
  can only rotate one step at a time.
