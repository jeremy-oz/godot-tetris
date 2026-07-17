# godot-tetris

A Tetris clone for **Godot 4.7**, upgraded from [russs123/tetris_tut](https://github.com/russs123/tetris_tut)
(originally written for Godot 4.1, from the tutorial video ["Make Tetris in Godot 4"](https://www.youtube.com/@Russ123)).

## Running

Open the project in Godot 4.7.x and press Play (`F5`). `scenes/main.tscn` is set as the main scene.

Controls: arrow keys — left/right to move, down for soft drop, up to rotate. Click **NEW GAME** to restart.

## What changed in the 4.1 → 4.7 upgrade

The first commit in this repo is the untouched 4.1 tutorial project, so you can see the
entire upgrade with:

```sh
git diff <first-commit> HEAD
```

### 1. `TileMap` → `TileMapLayer` (the big one)

Since **Godot 4.3**, the `TileMap` node — one node containing multiple layers addressed by
index — is deprecated. Each layer is now its own **`TileMapLayer`** node. The old scene:

```text
TileMap (script, 2 layers: "board", "active")
└── HUD
```

became:

```text
Main (Node2D, script)
├── Board  (TileMapLayer)  ← walls + landed pieces
├── Active (TileMapLayer)  ← falling piece + next-piece preview
└── HUD
```

Both layer nodes share the same `TileSet` resource, exactly like the old layers did.

Every cell call loses its `layer` index argument and moves to the layer node instead:

| Godot 4.1 (`TileMap`)                          | Godot 4.7 (`TileMapLayer`)             |
| ---------------------------------------------- | -------------------------------------- |
| `set_cell(layer, pos, source_id, atlas)`       | `board.set_cell(pos, source_id, atlas)` |
| `erase_cell(layer, pos)`                       | `active.erase_cell(pos)`               |
| `get_cell_source_id(layer, pos)`               | `board.get_cell_source_id(pos)`        |
| `get_cell_atlas_coords(layer, pos)`            | `board.get_cell_atlas_coords(pos)`     |

The script also no longer extends `TileMap` — it extends `Node2D` and grabs the layers
with `@onready` variables:

```gdscript
@onready var board: TileMapLayer = $Board
@onready var active: TileMapLayer = $Active
```

In the scene file, the painted border tiles were converted from the old
`layer_0/tile_data = PackedInt32Array(...)` format to the new
`tile_map_data = PackedByteArray(...)` format (the Godot editor does this conversion for
you via the TileMap panel's *"Extract TileMap layers as individual TileMapLayer nodes"*
tool — here it was done with a headless conversion script).

### 2. Project settings

- `config/features` bumped from `"4.1"` to `"4.7"`.
- `run/main_scene` now set, so the project runs without asking which scene to play.
- Scene files are `format=4` and scripts have `.uid` sidecar files (introduced in 4.4 —
  commit them; they let Godot track files when you move/rename them).

### 3. Small script modernizations

- Typed function signatures (`func move_piece(dir: Vector2i) -> void:`) — not required,
  but idiomatic modern GDScript and catches mistakes earlier.
- HUD nodes cached in `@onready` vars instead of `$HUD.get_node(...)` lookups everywhere.
- Bug fix: the score label now resets to `SCORE: 0` when you start a new game (the
  original kept showing the old score until you cleared a row).

## Credits

Game code and art from [russs123/tetris_tut](https://github.com/russs123/tetris_tut), MIT licensed.
