# Chapter 08 — Multiplayer 2: lobby, connection, seed handshake

**Git ref:** `e836f7d` (`git diff 9b0fd82 e836f7d`). First networking
chapter: two machines connect and agree on a shared random seed. The
opponent's board stays EMPTY this chapter (set that expectation).

**Learning goals:** client/server over ENet; `multiplayer.multiplayer_peer`;
signals for connect/disconnect; RPCs; determinism as a networking
technique (sync the seed, not the data).

## What gets built

1. **`lobby.tscn`/`lobby.gd`** — new main scene: SINGLE PLAYER (→ solo),
   HOST GAME, JOIN GAME (IP field; empty = 127.0.0.1 for local testing).
   Hosting:

```gdscript
var peer := ENetMultiplayerPeer.new()
var err := peer.create_server(PORT, 1)       # port 8910, max 1 guest
multiplayer.multiplayer_peer = peer
```

   Joining: `peer.create_client(ip, PORT)`. Handle
   `connection_failed` / `server_disconnected` / cancel by restoring an
   `OfflineMultiplayerPeer` (Godot's official "not networked" state — the
   reason solo mode needs zero special-casing).
   Nice touch: show the host their LAN IP (`IP.get_local_addresses()`,
   first `192.168.*`/`10.*` entry) for the other player to type.

2. **The handshake** — a three-line protocol, diagram-worthy:

```
host                             guest
  peer_connected fires ──────────► (also fires)
  seed := randi()
  _receive_seed.rpc(seed) ───────► stores seed
                                   _start_match.rpc()   (call_local!)
  changes to versus scene ◄──────► changes to versus scene
```

   `_receive_seed` is `authority`+`reliable`; `_start_match` is
   `any_peer`+`call_local`+`reliable` — the guest's ack that ALSO starts
   the guest. RPC facts to teach: an RPC runs the same-named function on
   the same-pathed node on the other machine; `call_local` = "and here".
   Seed carried across the scene change in `static var match_seed`.

3. **Seeded bag in board.gd** (the only gameplay change, ~10 lines):
   `Array.shuffle()` uses the global RNG — unshareable (gotchas.md #5).
   The bag draws via an owned `RandomNumberGenerator`;
   `new_game(seed)` seeds it, `new_game()` randomizes (solo unchanged).

4. **`versus.tscn` skeleton**: MyBoard (0,0) + OpponentBoard (650,0);
   `_ready` starts MyBoard with `Lobby.match_seed`. Window widening via
   `content_scale_size` 1300×704 (embedded-window story: gotchas.md #7).

## Verify

- Editor → Debug → **Run Multiple Instances → 2**, F5: host in one, join
  in the other → both land in versus.
- THE observable: both windows' NEXT PIECE panels show the identical
  piece at all times — the handshake made visible.
- End-to-end proof: run `test_net_host.gd` then `test_net_client.gd` as
  two headless processes; both print the same seed.

## Screenshots

`lobby.png`, `join-menu.png`, `versus.png` (partial — full mirror is ch09).

## Pitfalls

- Both machines get `peer_connected`; only the host may pick the seed
  (guard with `multiplayer.is_server()`).
- ENet is UDP — a firewall prompt on first hosting is normal.
