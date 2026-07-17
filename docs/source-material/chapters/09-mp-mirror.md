# Chapter 09 — Multiplayer 3: mirroring the opponent's board

**Git ref:** `1c9a15c` (`git diff e836f7d 1c9a15c`). The right-hand board
comes alive.

**Learning goals:** state replication via snapshots; reliable vs
unreliable delivery; keeping subsystems decoupled (board still has no
networking); change-detection batching.

## Architecture (draw this)

```
your machine                         their machine
MyBoard (plays) ──capture_display()──► _receive_display() ──apply_display()──► OpponentBoard (paints)
OpponentBoard (paints) ◄─────────────── MyBoard (plays)          [symmetric — same script both sides]
```

The mirror is a DISPLAY, not a simulation: it is never started, receives
no input, just gets pictures painted onto it.

## What gets built

1. **board.gd — still network-free** (~40 lines):
   - `capture_display()` → `[board.tile_map_data, active.tile_map_data,
     ghost.tile_map_data, score, lines, level, game_over_label.visible]`.
     The `tile_map_data` trick: a TileMapLayer's entire content is one
     assignable `PackedByteArray` — zero hand-written serialization.
   - `apply_display(state)` assigns the three layers, sets the label
     numbers, does NOT touch gameplay state.
   - `signal display_changed`, emitted **at most once per frame**: the
     ~7 cell-touching functions set `display_dirty = true`; `_process`
     emits once and clears it. Teach this as event batching — without it,
     one hard drop would spam a dozen sends.
2. **versus.gd — all the wire code** (~15 lines):

```gdscript
my_board.display_changed.connect(_send_display)

func _send_display() -> void:
    _receive_display.rpc(my_board.capture_display())

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _receive_display(state: Array) -> void:
    opponent_board.apply_display(state)
```

   Plus a 1 s heartbeat resend (`RESEND_INTERVAL`) in `_process`.

## The reliability lesson (core of the chapter)

Why `unreliable_ordered` here but `reliable` for the seed? Full snapshots
are idempotent — a lost display packet is healed by the next one, and
fresher beats retransmitted-stale. Events (seed, garbage, win) must arrive
exactly once → reliable. The heartbeat covers the corner case "the LAST
packet of a burst was dropped and nothing else is changing".

## Verify

- Two instances: your moves appear on the other window's right board in
  real time — stack, falling piece, ghost, score, even GAME OVER.
- Network test now plays pieces on both sides and passes only when each
  machine's mirror shows the other's pieces (both directions).
- Headless: mirror capture/apply tests — which is where the
  bytes-vs-meaning lesson comes from (gotchas.md #8).

## Screenshots

`versus.png` — right board shows a mirrored game incl. the opponent's
garbage rows and hold panel.

## Pitfalls

- RPCs target the same node PATH on the remote machine — both scenes must
  be structurally identical (they run the same versus.tscn, so they are).
- A board that was never started must look idle: gotchas.md #9.
