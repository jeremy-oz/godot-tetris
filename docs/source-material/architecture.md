# Architecture

Final state of the project after all chapters.

## Files

```
project.godot            settings: 650x704 window, canvas_items stretch, input actions
board.gd      (510 ln)   THE GAME. One self-contained Tetris board, no networking
lobby.gd      (111 ln)   entry menu: solo / host / join; ENet setup; seed handshake
versus.gd     (120 ln)   two boards side by side; ALL wire traffic lives here
solo.gd       ( 18 ln)   one board + NEW GAME/MENU buttons
scenes/board.tscn        playfield layers + side-panel UI (instanced 1x solo, 2x versus)
scenes/lobby.tscn        menus (main / join / wait) — the main scene
scenes/solo.tscn         Board instance + buttons
scenes/versus.tscn       MyBoard + OpponentBoard + result label + end menu
assets/tetrominoes.png   8-column tile sheet: 7 piece colors + grey (walls/garbage)
test_headless.gd         52 behavioral tests (logic only, runs headless)
test_net_host.gd/.client end-to-end 2-process ENet test (handshake/mirror/garbage)
tools/screenshots.gd     regenerates docs/img/*.png from seeded states
```

## Scene trees

```
board.tscn: PlayerBoard (Node2D, board.gd)
├── Board  (TileMapLayer)  walls + landed pieces + garbage
├── Ghost  (TileMapLayer)  landing preview, modulate alpha ≈ 0.10
├── Active (TileMapLayer)  falling piece + next/hold panel drawings
└── NextLabel, NextPanel, HoldLabel, HoldPanel,
    ScoreLabel, LinesLabel, LevelLabel, GameOverLabel   (Controls)

versus.tscn: Versus (Node2D, versus.gd)
├── MyBoard       (board.tscn)  at (0,0)    — played locally
├── OpponentBoard (board.tscn)  at (650,0)  — dumb mirror, never started
├── ResultLabel   "YOU WIN!/YOU LOSE!"      hidden until match end
└── EndMenu: RematchButton, MenuButton      hidden until match end
```

Node order matters: `Ghost` renders under `Active`, so a grounded ghost
hides behind the real piece. The side-panel UI is plain `Control`s under a
`Node2D` root — NOT a CanvasLayer — so the whole board moves as one unit
when versus places the second instance at x=650.

## Board coordinates

TileMapLayer grid, 32px tiles. Playfield: **x 1..10, y 1..20**. Grey wall
tiles occupy x=0, x=11, y=0 (ceiling!) and y=21 (floor), painted in
board.tscn. Collision is simply "is that Board-layer cell painted?"
(`is_free()` → `get_cell_source_id(pos) == -1`), so walls need no special
code. Side panels draw on the Active layer around tiles x 14–18.

## board.gd public surface

Mode scenes drive a board exclusively through:

```
new_game(bag_seed := -1)        start/restart; seed >= 0 → deterministic bag
game_running: bool              gameplay + input gate
queue_garbage(count)            attack arrives; rows rise at next lock
capture_display() -> Array      3 tile layers + score/lines/level + game-over flag
apply_display(state)            paint a captured state (mirror use; doesn't start it)
reset_display()                 blank a mirror back to pre-match look
signal topped_out               emitted once on game over
signal lines_cleared(count)     emitted per lock that cleared lines
signal display_changed          emitted max once/frame when anything visible changed
```

## Design decisions and their rationale

1. **The board knows nothing about the network.** All RPCs are in versus.gd
   (~40 lines of wire code). Solo mode and the headless tests run the exact
   same board. Teaching value: the "game" and the "wire" are separable
   concerns and the file tree shows the boundary. This is also where a
   future security module plugs in — the wire protocol is in one file.
2. **Determinism instead of piece-sync.** The host sends ONE random seed at
   match start; both boards deal identical 7-bag sequences from their own
   seeded `RandomNumberGenerator`. Nothing about pieces ever crosses the
   network. (`Array.shuffle()` was replaced because it uses the global RNG,
   which two machines cannot share.)
3. **Mirror = display stream, not simulation.** The opponent board is never
   started; it just gets `tile_map_data` snapshots painted onto it. Full
   snapshots are idempotent, so a lost packet is healed by the next one —
   which is why the display RPC can be `unreliable_ordered` while events
   (seed, garbage, win) are `reliable`.
4. **Trust-the-client, deliberately.** Each machine is authoritative over
   its own board and simply tells the other what happened. This is the
   simplest teachable architecture AND the intended setup for the future
   security lessons (cheating demos, then host validation).
5. **Mode scenes own the lifecycle.** A board never calls its own
   `new_game()`; solo/versus decide when. That is what makes countdowns,
   rematches and synchronized starts possible without touching board.gd.
6. **Garbage applies between pieces** (queued until the current piece
   locks), matching modern Tetris and avoiding every mid-fall collision
   edge case.
7. **Scene-level window management.** The project uses `canvas_items`
   stretch with aspect `keep`; versus widens `content_scale_size` to
   1300×704 and the lobby restores 650×704. In a window that cannot resize
   (the editor's embedded game view) content scales down and centers.

## The versus wire protocol (complete)

| RPC (all on /root/Versus or /root/Lobby) | Mode | When |
|---|---|---|
| `Lobby._receive_seed(seed)` | authority, reliable | host → guest after connect |
| `Lobby._start_match()` | any_peer, call_local, reliable | guest ack; switches both scenes |
| `Versus._receive_display(state)` | any_peer, unreliable_ordered | on display_changed + 1 s heartbeat |
| `Versus._receive_garbage(n)` | any_peer, reliable | after a 2+/3/4-line clear |
| `Versus._notify_win()` | any_peer, reliable | sender topped out |
| `Versus._request_rematch()` | any_peer, call_local, reliable | REMATCH pressed (host acts) |
| `Versus._do_rematch(seed)` | authority, call_local, reliable | host broadcasts new seed |

Wire cost: one display state ≈ 1–3 KB; sent only on change (max 60/s
during motion) plus 1/s heartbeat. ENet over UDP, port 8910.
