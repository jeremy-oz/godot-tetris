# Chapter 06 — Testing the game without playing it

**Git ref:** `test_headless.gd` (introduced in `b08589a`, grown every
chapter since; 52 checks at final state).

**Learning goals:** automated verification; driving game code through its
functions instead of the keyboard; why tests catch what playtesting
cannot. Optional/advanced chapter — the tutorial works without it, but it
pays off every later chapter ("does solo still pass?").

## How the harness works

A `SceneTree` script run with `godot --headless -s res://test_headless.gd`.
It instantiates the real scenes, then calls gameplay functions directly
(`hard_drop()`, `try_rotate(-1)`, `lock_piece()`) and asserts on state.
No window, no keyboard, runs in seconds — same board code as the game.

Two harness facts students must know (gotchas.md #11):
- `_ready` only fires once the tree iterates: `await process_frame` before
  and after `add_child`.
- Frames only advance across `await` — between awaits, the test body runs
  with the game frozen, which is what makes assertions deterministic.

Pattern:

```gdscript
func check(cond: bool, label: String) -> void:
    print(("PASS: " if cond else "FAIL: ") + label)   # + failure tally
```

## What the suite covers (grouped)

- Core: spawn, ghost-vs-drop agreement, hard drop cells+scoring
- SRS: T wall kick, I wall kick, rotation cancelled when nothing fits
- Hold: store / next-activates / refused-second / swap-after-lock
- Line clears: detection, shifting, the row-1 regression (see below)
- Scoring/levels/gravity, game over on blocked spawn
- Determinism: same seed → same pieces; different seeds differ (ch08)
- Mirror: capture/apply equality, display_changed batching (ch09)
- Versus: garbage geometry, lose/win/rematch sequence (ch10)

## The star exhibit

The suite's game-over test HUNG the first time it ran — and the hang was a
real, inherited bug: a full top row could never be cleared and froze the
game in an infinite loop (gotchas.md #2). Years of human playtesting never
found it; the second-ever automated test did. Lead with this story.

## Comparing the right thing

The mirror tests originally compared `tile_map_data` bytes and failed on
identical-looking boards — the serialization is not byte-stable
(gotchas.md #8). The suite's `boards_mirror()` compares used cells +
atlas coords instead. Lesson: assert on meaning, not representation.

## Verify

`godot --headless -s res://test_headless.gd` → 52 PASS lines and
"ALL TESTS PASSED", exit code 0.

## Related tools (mention, don't teach)

- `test_net_host.gd` / `test_net_client.gd`: two real processes doing the
  full network arc (ch08–10 verify sections use them).
- `tools/screenshots.gd`: rendered screenshots from seeded states — caught
  a layout bug tests cannot see (gotchas.md #10); pairs nicely with this
  chapter's "what can each kind of check see?" discussion.
