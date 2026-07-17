# Reference tables

## Controls

| Key | Action | Input action name |
|---|---|---|
| ← / → | move (auto-repeats after DAS) | `move_left` / `move_right` |
| ↓ | soft drop (+1 point per cell) | `soft_drop` |
| ↑ or X | rotate clockwise | `rotate_cw` |
| Z | rotate counter-clockwise | `rotate_ccw` |
| Space | hard drop (+2 points per cell) | `hard_drop` |
| C or Shift | hold (once per piece) | `hold` |

Defined in `project.godot` `[input]` with **physical** keycodes
(layout-independent). Arrow keys: LEFT 4194319, UP 4194320, RIGHT 4194321,
DOWN 4194322; SPACE 32; SHIFT 4194325; letters use ASCII (X 88, Z 90, C 67).

## Timing constants (board.gd)

| Constant | Value | Meaning |
|---|---|---|
| `DAS` | 0.17 s | held key: delay before auto-repeat |
| `ARR` | 0.05 s | held key: repeat interval |
| `SOFT_DROP_INTERVAL` | 0.04 s | fastest soft-drop step |
| `LOCK_DELAY` | 0.5 s | grace period on the stack |
| `MAX_LOCK_RESETS` | 15 | moves/rotations that restart the grace period |

Gravity (Guideline curve): seconds per row =
`pow(0.8 - (level - 1) * 0.007, level - 1)`; level = `1 + lines / 10`,
capped at 20. Soft drop = gravity/20, capped at `SOFT_DROP_INTERVAL`.

## Scoring

| Event | Points |
|---|---|
| 1 / 2 / 3 / 4 lines in one lock | 100 / 300 / 500 / 800 × level |
| soft drop | +1 per cell |
| hard drop | +2 per cell |

## Versus attack table (versus.gd `GARBAGE_FOR_CLEAR`)

| Lines cleared at once | Garbage rows sent |
|---|---|
| 1 | 0 |
| 2 | 1 |
| 3 | 2 |
| 4 (Tetris) | 4 |

Garbage rows are grey (wall tile, atlas x=7), rise from the bottom when the
receiver's current piece locks, and share ONE random hole column per attack.

## SRS wall kicks (already y-flipped for Godot in board.gd)

Rotation states: 0 = spawn, 1 = CW, 2 = 180°, 3 = CCW. On a blocked
rotation, try each offset in order; first fit wins; none fit → cancel.
J, L, S, T, Z share one table; I has its own; O never kicks.
Source: tetris.wiki "Super Rotation System" — **published y-up, negate
every y when copying into Godot** (the values below are already negated).

JLSTZ (from→to: 5 test offsets):
```
0→1: (0,0) (-1,0) (-1,-1) (0, 2) (-1, 2)      1→0: (0,0) ( 1,0) ( 1, 1) (0,-2) ( 1,-2)
1→2: (0,0) ( 1,0) ( 1, 1) (0,-2) ( 1,-2)      2→1: (0,0) (-1,0) (-1,-1) (0, 2) (-1, 2)
2→3: (0,0) ( 1,0) ( 1,-1) (0, 2) ( 1, 2)      3→2: (0,0) (-1,0) (-1, 1) (0,-2) (-1,-2)
3→0: (0,0) (-1,0) (-1, 1) (0,-2) (-1,-2)      0→3: (0,0) ( 1,0) ( 1,-1) (0, 2) ( 1, 2)
```
I piece:
```
0→1: (0,0) (-2,0) ( 1,0) (-2, 1) ( 1,-2)      1→0: (0,0) ( 2,0) (-1,0) ( 2,-1) (-1, 2)
1→2: (0,0) (-1,0) ( 2,0) (-1,-2) ( 2, 1)      2→1: (0,0) ( 1,0) (-2,0) ( 1, 2) (-2,-1)
2→3: (0,0) ( 2,0) (-1,0) ( 2,-1) (-1, 2)      3→2: (0,0) (-2,0) ( 1,0) (-2, 1) ( 1,-2)
3→0: (0,0) ( 1,0) (-2,0) ( 1, 2) (-2,-1)      0→3: (0,0) (-1,0) ( 2,0) (-1,-2) ( 2, 1)
```

## Piece data facts

- Each piece = 4 rotation-state arrays of 4 cell offsets, in SRS order
  (index 0 spawn, 1 CW, 2 180°, 3 CCW), inside a 3×3 box (I: 4×4, O: 2×2).
- Spawn at `start_pos = (4, 1)`; O nudged +1 x to sit guideline-centered.
- Atlas column in tetrominoes.png = index in `shapes_full` = [i,t,o,z,s,l,j]
  → columns 0..6; column 7 is the grey wall/garbage tile.

## Glossary

- **Guideline** — The Tetris Company's spec all modern Tetris follows.
- **7-bag** — randomizer dealing all 7 pieces in shuffled batches; max
  drought of 12 between repeats of a piece.
- **SRS** — Super Rotation System; spawn orientations + wall-kick tables.
- **Wall kick** — nudging a blocked rotation into a nearby fitting spot.
- **DAS / ARR** — delayed auto shift / auto repeat rate for held movement.
- **Lock delay** — grace period after landing before a piece freezes.
- **Ghost piece** — translucent preview of where the piece would land.
- **Hard / soft drop** — instant drop-and-lock / accelerated fall.
- **Garbage** — junk rows attacks push onto the opponent's board.
- **Top out** — losing by having no room to spawn the next piece.
- **ENet** — UDP-based networking library behind Godot's high-level
  multiplayer; **RPC** — calling a function on the remote peer's node.

## External links

- Tetris Guideline overview: https://tetris.wiki/Tetris_Guideline
- SRS + kick tables (y-up!): https://tetris.wiki/Super_Rotation_System
- Godot high-level multiplayer:
  https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- Original base tutorial (video + repo): russs123/tetris_tut,
  "Make Tetris in Godot 4" — MIT licensed; our commit cc24395 is its
  unmodified import, 8dd7449 the 4.1→4.7 upgrade.
- Trademark note for publishing: "Tetris" is a trademark of The Tetris
  Company; a publicly published tutorial/game should use a different name.
