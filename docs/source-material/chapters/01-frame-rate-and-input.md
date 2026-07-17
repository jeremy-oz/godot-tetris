# Chapter 01 — Frame-rate independence and real input handling

**Git ref:** part of `b08589a` (functions `_process`/`run_frame`,
`handle_horizontal`, `apply_gravity`, `fall_interval`, `[input]` section of
project.godot).

**Learning goals:** why per-frame accumulation is a bug; delta time;
input actions vs hardcoded keys; DAS/ARR — the feel of every real Tetris.

## The hook (do this live)

The base game adds fixed amounts per frame, so at 120 Hz it plays twice as
fast as at 60 Hz (gotchas.md #1). Demonstrate, then fix. This is the
strongest "professional games do it differently" moment in the course.

## What gets built

1. **Named input actions** in Project Settings replace `ui_left` etc.:
   `move_left/move_right/soft_drop/rotate_cw/rotate_ccw/hard_drop/hold`
   (bindings in reference.md). Use *physical* keycodes.
2. **Gravity in seconds.** A `gravity_timer` accumulates `delta`; every
   `fall_interval()` seconds the piece moves down one row:

```gdscript
func apply_gravity(delta: float) -> void:
    ...
    gravity_timer += delta
    while gravity_timer >= interval:
        gravity_timer -= interval
        if not can_move(Vector2i.DOWN):
            break
        shift_piece(Vector2i.DOWN)
```

   The `while` (not `if`) matters: at very high gravity a single frame may
   owe more than one row.
3. **DAS/ARR** for held movement — first press moves immediately, then
   after `DAS` seconds it repeats every `ARR` seconds:

```gdscript
func handle_horizontal(delta: float) -> void:
    var dir := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
    if dir == 0:
        das_dir = 0
        return
    if dir != das_dir:          # fresh press
        das_dir = dir
        das_timer = DAS
        try_move(Vector2i(dir, 0))
    else:                       # held
        das_timer -= delta
        while das_timer <= 0.0:
            das_timer += ARR
            try_move(Vector2i(dir, 0))
```

4. **Soft drop** = gravity interval / 20 (capped at `SOFT_DROP_INTERVAL`)
   while `soft_drop` is held.

## Verify

- Editor → Debug → Settings "Max FPS" (or a high-Hz monitor): game speed
  no longer changes with frame rate.
- Tapping ← moves exactly one column; holding it glides after a beat.

## Pitfalls

- `int(bool)` trick for direction: -1/0/+1 from two keys; also resolves
  both-keys-held to 0.
- Timers are per-piece state: reset them on spawn or the next piece
  inherits stale progress.
