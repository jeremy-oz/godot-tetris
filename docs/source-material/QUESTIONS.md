# Open questions & requests from the tutorial author

Compiled while writing the mkdocs tutorial (2026-07-18, Lisa). Items 1–4
are pack corrections found by verifying against the actual git history;
5–6 are screenshot requests for `tools/screenshots.gd`.

## Pack corrections (please confirm / fix the pack)

1. **`chapters/00-setup-and-base-game.md` "Setup facts" claims stretch
   `canvas_items`/`keep` at the base stage.** `project.godot` at `8dd7449`
   has only `viewport_width=650`/`viewport_height=704` — no stretch keys.
   `window/stretch/mode="canvas_items"` first appears in `e836f7d`
   (lobby/handshake commit), which fits gotcha #7's story. The tutorial
   teaches window size only in its Chapter 1 and introduces stretch mode in
   Chapter 11 (the e836f7d chapter). Suggest correcting the ch00 bullet.

2. **`chapters/05-scoring-and-levels.md` approximate gravity figures look
   wrong.** The pack says level 10 → ~0.16 s/row and level 20 → ~0.007
   s/row. Recomputed from the actual formula
   `pow(0.8 - (level - 1) * 0.007, level - 1)`: level 10 ≈ 0.064 s,
   level 20 ≈ 0.0005 s. The tutorial uses the recomputed values — please
   confirm and correct the pack.

3. **Test count: "52 behavioral tests" is the FINAL count, not the count
   when tests are introduced.** Running the suite at each commit gives
   28 (`b08589a`) → 28 (`9b0fd82`) → 37 (`e836f7d`) → 42 (`1c9a15c`) →
   52 (`c9f0817`). The tutorial's testing chapter (its ch9, at `b08589a`)
   teaches 28 and notes the growth. Consider stating the growth curve in
   `chapters/06-testing.md` so future authors don't trip on it.

4. **Dead code in `test_headless.gd`** (scoring/level bookkeeping test):
   a no-op loop — `for cell in main.active_piece:` / `pass` — whose comment
   claims it avoids double-land collisions, but the following lines achieve
   that on their own. The tutorial omits it; consider deleting it from the
   repo so students diffing against the real file aren't confused.

## Screenshot requests (extend `tools/screenshots.gd`)

5. **DONE.** `base-game.png` — added to `tools/screenshots.gd` (seed 3, 4
   hard drops + `try_move(DOWN)` to walk the next piece mid-well; Ghost,
   HoldLabel/Panel and Lines/Level hidden, solo.tscn's MenuButton hidden).
   Shows the `8dd7449`-era look: a stacked well, one piece mid-fall, NEXT
   populated, SCORE 124, NEW GAME only. Wired into `03-lines-and-game-over.md`
   (Part 1's verify) and linked from `01-setup-and-pieces.md`.

6. **DONE.** `hold-panel.png` — added to `tools/screenshots.gd` (seed 7, 2
   hard drops then `hold_piece()`; Lines/Level and MenuButton hidden, Ghost
   left visible). Shows an L piece sitting in HOLD, a different piece (O)
   falling, NEXT populated. Wired into `07-hold-and-lock-delay.md` at the
   hold checkpoint.

7. **Screenshot pipeline nondeterminism** (found 2026-07-18 while adding
   the two shots above): `garbage.png`, `versus.png` and `versus-win.png`
   drift slightly between generator runs — `insert_garbage()`'s hole column
   uses Godot's *global* `randi_range()`, so it isn't covered by the seeded
   bag RNG. That global-RNG choice is deliberate and correct in the game
   (see gotcha #5 / the ch10 chapter's determinism note) — the fix belongs
   in `tools/screenshots.gd`: call `seed(<constant>)` before the stages
   that trigger garbage, restoring the README's "re-running regenerates
   identical images" promise. (`lobby/join-menu/solo-game/wallkick-*` and
   the two new shots are byte-stable — verified by double-run.)

8. **Suggest a `.gdignore` in `docs/`** — opening the project in the
   desktop editor auto-imports every PNG under `docs/img/`, littering the
   repo with untracked `*.png.import` files (happened 2026-07-18; cleaned
   up). A one-byte `.gdignore` file in `docs/` stops Godot scanning the
   folder entirely — the images are documentation, not game assets.

## Non-technical

- **Naming/trademark: RESOLVED** (Jeremy, 2026-07-19) — dealt with
  correctly; no further reminders needed from any agent.
