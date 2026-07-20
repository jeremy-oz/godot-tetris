# Tutorial source pack

Technical source material for writing the student tutorial of this project.
**Audience of this pack: the tutorial author (human or agent) — not students.**
It contains verified facts about the codebase; the pedagogy, pacing, tone and
exercise selection are the tutorial author's job.

## The project in one paragraph

A Tetris clone for Godot 4.7 that grows, chapter by chapter, from a 240-line
single-file game into a ~760-line project with modern-Tetris mechanics (SRS
wall kicks, hold, ghost, lock delay, guideline scoring) and a two-player LAN
versus mode (lobby, deterministic shared piece bag, live board mirroring,
garbage attacks, win/lose/rematch). It was deliberately built in
tutorial-sized increments: **the git history is the lesson plan.**

## Tutorial framing

Students **build the project from scratch, following along**. Each chapter
file in `chapters/` describes one increment: its goal, the concepts it
introduces, what gets built, annotated key code, how to verify, pitfalls,
and screenshots. Chapters are ordered and cumulative. The author may split
or merge chapters freely — files note where a natural split point exists.

## Files

| File | Contents |
|---|---|
| `architecture.md` | Final file/scene layout, board API, design decisions with rationale |
| `chapters/00...10` | One file per build increment (see below) |
| `gotchas.md` | Real bugs and surprises hit while building — high-value teaching moments |
| `reference.md` | Controls, SRS kick tables, scoring/attack tables, glossary, external links |
| `extensions.md` | Graded follow-up exercises, incl. the planned security module stub |

## Chapter map and git history

Each chapter corresponds to a commit range; `git diff <prev> <commit>` shows
exactly what that lesson adds. Chapters 01–05 all live inside one commit
(`b08589a`) — the diff subsections are identified by function name instead.

| Chapter | Content | Commit |
|---|---|---|
| 00 | Setup + the base single-file game | `cc24395` → `8dd7449` |
| 01 | Frame-rate independence, DAS/ARR | part of `b08589a` |
| 02 | Hard drop + ghost piece | part of `b08589a` |
| 03 | CCW rotation + SRS wall kicks | part of `b08589a` |
| 04 | Hold piece + lock delay | part of `b08589a` |
| 05 | Guideline scoring + levels | part of `b08589a` |
| 06 | Headless testing | `b08589a` (test_headless.gd) |
| 07 | Multiplayer 1: extract the board scene | `9b0fd82` |
| 08 | Multiplayer 2: lobby + seed handshake | `e836f7d` |
| 09 | Multiplayer 3: mirror the opponent | `1c9a15c` |
| 10 | Multiplayer 4: garbage, win/lose, rematch | `c9f0817` |

## Images

All screenshots live in `docs/img/` and are **generated, not hand-taken**:
`godot -s res://tools/screenshots.gd` re-creates every image from seeded
game states (needs a real window — rendering does not work headless).
If code or layout changes, regenerate instead of re-staging by hand.

Available: `lobby.png`, `join-menu.png`, `solo-game.png`, `garbage.png`,
`wallkick-before.png`, `wallkick-after.png`, `versus.png`, `versus-win.png`,
`base-game.png`, `hold-panel.png`
(650×704, versus shots 1300×704). Chapter files state which images they use.
To stage a new state for a new image, extend `tools/screenshots.gd` — it
manipulates boards through the same public functions the tests use.

## Conventions used in this pack

- Code excerpts are copied from the real files and verified; when a chapter
  says "students write this", the excerpt is the intended end state.
- Functions are referenced by name (`lock_piece()`), not line number.
- "Guideline" always means the official Tetris Guideline (see reference.md).
- Every chapter's **Verify** section is executable as written and was
  actually run during development.
