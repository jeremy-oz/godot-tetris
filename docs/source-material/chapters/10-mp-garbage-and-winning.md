# Chapter 10 — Multiplayer 4: garbage attacks, winning, rematch

**Git ref:** `c9f0817` (`git diff 1c9a15c c9f0817`). Versus becomes a
complete game.

**Learning goals:** game economies (attack table), deferred effects
(garbage queues until lock), terminal states in a distributed system,
arbitration (host decides) as a race-condition fix.

## Garbage — what and why

See reference.md attack table (1→0, 2→1, 3→2, 4→4): singles send nothing,
so safe play exerts no pressure — the risk/reward core of versus Tetris.

Board side (network-free, ~45 lines):
- `signal lines_cleared(count)` emitted in `lock_piece`.
- `queue_garbage(count)` accumulates into `pending_garbage`; applied in
  `lock_piece` AFTER scoring, BEFORE the next spawn — garbage arrives
  *between pieces* (modern-Tetris rule; avoids all mid-fall collisions).
- `insert_garbage(count)`: shift all playfield rows up by `count`
  (content pushed past the ceiling vanishes; the next spawn failing there
  ends the game naturally), then fill the bottom rows with grey tiles
  (`GARBAGE_ATLAS`, same tile as walls) leaving ONE shared random hole
  column per attack. The hole uses the GLOBAL RNG on purpose — it must
  NOT consume the shared bag generator (ask students why: piece
  sequences would desync).

Versus side (~10 lines): `lines_cleared` → look up table →
`_receive_garbage.rpc(n)` (reliable); receiving side calls
`my_board.queue_garbage(n)` — "my board" because on the receiving machine
the attack targets THEIR playing board.

## Win / lose

Your board's `topped_out` → show YOU LOSE + `_notify_win.rpc()`
(reliable); the other machine freezes its board and shows YOU WIN. Guard:
`match_over` flag makes a late win notice a no-op — near-simultaneous
top-outs otherwise flip a loss into a win (gotchas.md #12).

## Rematch — the arbitration lesson

Either player presses REMATCH, but if each machine picked its own seed,
two simultaneous presses could leave different bags on each side
(reliable ≠ same order from different senders!). Fix — requests funnel to
one decider:

```gdscript
@rpc("any_peer", "call_local", "reliable")
func _request_rematch() -> void:
    if multiplayer.is_server():
        _do_rematch.rpc(randi())        # authority picks; broadcasts

@rpc("authority", "call_local", "reliable")
func _do_rematch(bag_seed: int) -> void:
    ...hide result UI, reset the mirror (reset_display()), new_game(bag_seed)
```

This is the course's first taste of server authority — name it as the
bridge to the (future) security module. MENU leaves; the other side's
`peer_disconnected` handler returns it to the lobby.

## Verify

- Two instances: clear a double/triple/Tetris → grey rows with one hole
  rise on the other board when their piece locks.
- Top out → YOU LOSE / YOU WIN banners; REMATCH → fresh identical bags.
- Network test exchanges garbage both directions; headless tests cover
  garbage geometry, the shared hole, queue accumulation, and the full
  lose → late-win-guard → rematch → win sequence.

## Screenshots

`garbage.png` (three risen rows + hole, solo-staged), `versus.png`
(mirror shows opponent's garbage), `versus-win.png` (result + end menu).

## Pitfalls

- Insert garbage only at lock time; inserting mid-fall teleports the
  falling piece into the stack.
- Don't touch the bag RNG for the hole position.
- Cap inserted rows at 20 (`mini(count, ROWS)`).
