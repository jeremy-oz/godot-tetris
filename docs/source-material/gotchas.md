# Gotchas — real bugs and surprises from building this project

Every entry below actually happened during development. These make the best
teaching moments: each one is a concrete story with a visible symptom, a
wrong first theory, and a verifiable fix.

## 1. The frame-rate bug (the original tutorial's biggest flaw)

The base tutorial accumulated fixed amounts per `_process` frame
(`steps[2] += speed` against a threshold), so **the game ran twice as fast
on a 120 Hz monitor**. Fix: express all timing in seconds and use `delta`.
Great opener lesson because students can *see* it (change the editor's
Max FPS, or compare a 60 Hz and a 144 Hz laptop). Also foreshadows
networking: two clients at different frame rates could never stay in step.

## 2. Row 1 could never be cleared (inherited infinite loop)

`shift_rows()` copied every row from the one above it, but its loop stopped
at row 2 — row 1 was never overwritten. A completely full top row made
`check_rows()` detect the same full row forever: the game froze. Nobody had
noticed for years because you normally top out before filling row 1.
**The headless test suite found it** (a game-over test hung). Lesson:
tests explore states humans rarely reach.

## 3. Space restarted the game (button focus)

After clicking NEW GAME the button kept keyboard focus, so pressing Space
(hard drop) activated the button again. Fix: `focus_mode = FOCUS_NONE` on
gameplay-adjacent buttons. Classic UI-toolkit surprise.

## 4. SRS tables are published y-up; Godot is y-down

Every kick table on tetris.wiki uses math coordinates (+y = up). Godot's
grid has +y = down, so **every y in the kick data must be negated** when
copying. Getting this wrong makes floor kicks dig into the floor. The
tables in board.gd are already flipped — the comment above them says so.

## 5. `Array.shuffle()` broke determinism

The bag originally used `shapes.shuffle()`, which draws from Godot's global
RNG — unseedable across machines in any useful way. Replaced with drawing
via an owned, seeded `RandomNumberGenerator`. Lesson: "random" is a
resource you must control before you can share it.

## 6. Renaming a script confused Godot's UID cache

After `git mv main.gd board.gd`, the stale `.godot/uid_cache.bin` still
mapped the script's UID to the old path, and the board scene silently got
the WRONG script attached (UID wins over path in ext_resource references).
Fix: reference new scripts by path and let one editor pass
(`godot --headless -e --quit`) rebuild the cache. Related: deleting
`uid_cache.bin` outright breaks `run/main_scene="uid://..."` at runtime,
because only the editor rebuilds the cache. This is why `.uid` sidecar
files should be committed.

## 7. The editor's embedded game window refuses to resize

Since Godot 4.4 the first F5 instance runs embedded in the editor's Game
tab. `window.size = ...` from the game is ignored there, so the 1300px
versus scene showed only one board. Fix: `canvas_items` stretch mode +
per-scene `content_scale_size` — the engine scales and centers content in
whatever window it actually gets. For real testing: Debug → Run Multiple
Instances, and/or disable game embedding.

## 8. `tile_map_data` is not byte-stable

Assigning one layer's `tile_map_data` to another **replaces** its content
correctly — but reading the property back does not return byte-identical
data. A test comparing mirrors by `PackedByteArray` equality failed while
the screens looked identical. Verified with a minimal probe script.
Lesson: compare *meaning* (cells + atlas coords), not serialization bytes.

## 9. A never-started board showed GAME OVER

The GameOverLabel was visible-by-default in the scene and only
`new_game()` hid it — the versus mirror board never runs `new_game()`, so
it sat there announcing GAME OVER before the first sync arrived. Fix:
hide it in the scene. Lesson: "default state" bugs appear the first time a
scene is used a *second* way.

## 10. The screenshot caught what the tests could not

The solo scene's NEW GAME button overlapped the board's LEVEL label —
pixels, not logic, so 52 passing headless tests said nothing about it. The
first rendered screenshot exposed it instantly. Lesson: tests check logic,
pictures check layout; a tutorial needs both.

## 11. `_ready` doesn't fire during a SceneTree script's `_initialize`

Headless test harness trap: adding a scene to `root` before the tree
iterates means `@onready` vars are still null. The fix is
`await process_frame` before (and after) `add_child`. Only matters for the
test scripts, but it's the first wall anyone hits writing one.

## 12. Simultaneous events in a distributed game

Two loose ends we handled explicitly, worth discussing:
- Both players topping out near-simultaneously: each shows YOU LOSE locally
  and a `match_over` guard ignores the late win notice.
- Both players pressing REMATCH at once: if each machine picked its own
  seed, reliable RPCs could arrive in different orders and the players
  would get different bags. Fix: requests go to the host; only the host
  picks and broadcasts the seed. This is *arbitration*, the seed of the
  entire server-authority topic in the future security module.

## 13. The TileSet atlas got source ID 1, not 0 (blank window)

Hit by the first real tutorial-follower. TileSet source IDs count up and
deleted IDs are never reused: add the texture atlas, remove it, add it
again, and it silently becomes `sources/1`. The tutorial code draws with
source ID 0 (`tile_id`), and `set_cell` with an unknown source renders
NOTHING — no error, just a blank window. Tutorial must warn at the
TileSet step: after adding the atlas, check it shows **ID 0** in the
TileSet panel (or compare `sources/0 =` in the .tscn); if it's 1, delete
the TileSet and rebuild it in one pass. Debugging hint for students:
blank window + no errors ⇒ check what `get_cell_source_id` returns vs
what the TileSet actually contains.
