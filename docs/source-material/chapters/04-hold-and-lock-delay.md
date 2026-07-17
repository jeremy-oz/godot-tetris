# Chapter 04 — Hold piece and lock delay

**Git ref:** part of `b08589a` (functions `hold_piece`, `reset_lock_delay`,
lock branch of `apply_gravity`; HOLD panel in the scene).

**Learning goals:** state machines with flags (one hold per piece), timers
with capped resets, designing against exploits (infinite stalling).

## Hold

Rules: press C/Shift to stash the current piece; the stashed piece comes
back on the NEXT hold; only one hold per piece (re-enabled when a piece
locks). First-ever hold has nothing to swap with, so it pulls from the
queue instead:

```gdscript
func hold_piece() -> void:
    if not can_hold:
        return
    can_hold = false          # re-enabled in lock_piece()
    ...swap or pull-from-queue, redraw HOLD panel, respawn...
```

Teaching note: the reference implementation we studied had a real bug here
— a setter-ordering mistake let players hold repeatedly after the first
hold. Our flag ordering avoids it; the tests pin it
(`hold: second hold refused`).

## Lock delay

Without it, a piece freezes the instant it touches the stack. With it, the
piece gets `LOCK_DELAY` (0.5 s) of grace, and each successful move or
rotation while grounded restarts the timer — but only
`MAX_LOCK_RESETS` (15) times, so you cannot wiggle forever:

```gdscript
func reset_lock_delay() -> void:
    if not can_move(Vector2i.DOWN) and lock_resets < MAX_LOCK_RESETS:
        lock_timer = 0.0
        lock_resets += 1
```

In `apply_gravity`: airborne → `lock_timer = 0`; grounded → accumulate,
and lock at `LOCK_DELAY`. Falling to a new row resets `lock_resets` to 0
(in `shift_piece` when moving DOWN).

The cap is the interesting design conversation: the reference project we
studied reset the timer on EVERY move with no cap — infinite stalling.
Ask students how they'd exploit that, then how to fix it.

## Verify

- Land a piece, keep tapping ←/→: it stays alive briefly, then locks
  anyway (the cap).
- Slide a piece off a ledge during the grace period: it falls again.
- Hold twice in a row: second press does nothing until the piece locks.

## Pitfalls

- `can_hold` must be reset in `lock_piece()`, NOT when the held piece
  respawns — otherwise hold→hold ping-pongs forever.
- Hard drop must lock immediately, ignoring lock delay entirely.
