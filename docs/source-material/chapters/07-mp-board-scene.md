# Chapter 07 — Multiplayer 1: extract the board scene

**Git ref:** `9b0fd82` (`git diff b08589a 9b0fd82`). Zero new gameplay —
pure restructuring, and solo must play IDENTICALLY afterwards.

**Learning goals:** scenes as reusable components; ownership/lifecycle
(who starts whom); signals as a component's outward interface; refactoring
under test protection.

## Why (motivate before doing)

Versus mode needs TWO boards side by side. Today "the game" and "the app"
are the same scene. The refactor separates them:

- `board.tscn` + `board.gd` — one complete board: layers, side panels,
  all gameplay. Instantiable any number of times, positioned anywhere.
- `solo.tscn` + `solo.gd` (~18 lines) — a *mode scene*: one board
  instance + NEW GAME/MENU buttons.

## The two structural rules

1. **No CanvasLayer in the board.** The old HUD was a CanvasLayer, which
   ignores parent transforms — two boards would pile their UI on top of
   each other. Side-panel UI becomes plain Controls under the board's
   Node2D root, so `position = (650, 0)` moves everything.
2. **The board never starts itself.** `_ready` no longer calls
   `new_game()`; the mode scene does. Rationale to state now: versus will
   need synchronized starts and rematches — only the mode scene can know
   *when*. New signal `topped_out` is the board reporting outward;
   `game_running` + `new_game()` complete the interface.

## Migration checklist (what actually moves)

- `main.gd` → `board.gd` (git mv keeps history); `@onready` label paths
  lose their `HUD/` prefix; start-button code moves to solo.gd.
- Walls: board.tscn gets a walls-only tile layout (the old scene carried
  leftover editor decorations that `clear_board()` wiped at runtime).
- Buttons live in solo.tscn (incl. `FOCUS_NONE` — gotchas.md #3).
- Tests point at the Board child; every existing test must still pass.

## The UID trap (teach it — students WILL hit it)

After renaming the script, Godot's UID cache still mapped the old UID →
old path, silently attaching the WRONG script to the scene
(gotchas.md #6). Fix: reference fresh scripts by path, run one editor
scan. Explains what `.uid` sidecar files are for and why they're committed.

## Verify

- Solo plays exactly as before (same feel, same features).
- All headless tests pass unchanged — the point of having them before
  refactoring. This chapter is the payoff of ch06.

## Screenshots

`solo-game.png` (unchanged look proves the refactor was invisible).
