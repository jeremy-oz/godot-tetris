# Extension menu — graded follow-up exercises

Rough sizes assume a student who completed the tutorial. "Lines" = new
GDScript. All are optional; none are prerequisites for anything else.

## Easy (an afternoon)

| Exercise | ~Lines | What it teaches |
|---|---|---|
| Sound effects (move/rotate/drop/clear/garbage) | 15 + assets | AudioStreamPlayer, asset import |
| Pause (Esc): stop gravity+input, dim screen | 15 | process modes / gating |
| High score in a file, shown in lobby | 20 | FileAccess, user:// vs res:// |
| 3-piece NEXT queue | 25 | queues; panel layout |
| Guideline piece colors / own tile art | 0 | asset pipeline only |
| Rename the game + new title screen | 5 | (also solves the trademark issue) |

## Medium (a week of lessons)

| Exercise | ~Lines | What it teaches |
|---|---|---|
| Match countdown (3-2-1-GO on both machines) | 30 | synchronized start; mode owns lifecycle |
| Garbage warning bar (pending rows shown before they rise) | 30 | `_draw()`, reading `pending_garbage` incl. mirror side |
| Combo + back-to-back scoring bonuses | 30 | streak state across locks |
| Line-clear animation (flash before shift) | 35 | async/await in gameplay without breaking tests |
| Best-of-N match score shown in versus | 35 | persistent match state across rematches |
| Marathon/sprint/ultra solo modes | 40 | mode scenes really pay off |

## Hard (project-sized)

| Exercise | ~Lines | What it teaches |
|---|---|---|
| T-spin detection + scoring + attack bonus | 60 | corner rules; reading a spec precisely |
| Garbage cancellation (your clears offset incoming) | 40 | two queues interacting |
| 3–4 player free-for-all (attack targeting) | 150+ | N-peer topologies; the 2-player assumptions surface fast |
| Replay recording + playback (inputs + seed) | 100 | determinism as a feature; input streams |
| Spectator mode (third peer receives both displays) | 80 | roles beyond host/guest |

## The security module (stub — curriculum to come)

The codebase was deliberately built trust-the-client so these lessons work
against the REAL project, not a toy. Natural sequence:

1. **Observe**: ENet traffic is plaintext UDP on port 8910 — watch a match
   in Wireshark; find the display snapshots and garbage messages.
2. **Cheat**: modify your client — send `_receive_garbage.rpc(20)` on a
   single line clear, or lie in `capture_display()` so your mirror looks
   clean. Every RPC is `any_peer` and unvalidated: enumerate the abuses.
3. **Defend**: host-side validation (bounds-check garbage counts, sanity-
   check display states, rate-limit), then discuss real answers: server
   authority (host simulates both boards from *inputs*, not results — a
   large refactor, which is exactly the point), encryption (Godot supports
   DTLS on ENet), and why "hide the protocol" is not a defense.
4. **Reflect**: the rematch arbitration (ch10) was already a tiny server-
   authority pattern; seed-picking, garbage, and display are the same
   decision at different trust levels.

Hooks already in place: single-file wire protocol (versus.gd), the
architecture.md RPC table as the "attack surface" inventory, and the
two-process test scripts as a scaffold for writing a malicious client.
