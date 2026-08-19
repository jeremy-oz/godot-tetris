# Exercise 3 — The Full Cycle: Test, Locate, Rectify, Re-run (and record it)

*Branch: `c8-debug-rectify` · Skill: the complete fix cycle your C8-1 screen recording must show (rubric levels 5–10) · Time: ~25 min*

## The feature that shipped broken

The lobby now **validates the IP address** before trying to connect in versus mode, so a typo gets an instant "Invalid IP address" message instead of a slow connection timeout. The code is in `lobby.gd` — `_looks_like_ip()` and one new check in `_on_connect_pressed()`.

QA says some rubbish addresses still get through.

## The testing table

Run every row (Lobby → **Versus / Join**, type the input, press Connect). Fill in the last two columns yourself — that's the point.

| ID | Input | Type | Expected output | Actual output | Pass/Fail |
|---|---|---|---|---|---|
| TC1 | `127.0.0.1` | normal | "Connecting to 127.0.0.1..." | | |
| TC2 | *(empty)* | boundary | defaults to `127.0.0.1`, attempts connection | | |
| TC3 | `banana` | erroneous | "Invalid IP address" message, no connection attempt | | |
| TC4 | `a.b.c.d` | erroneous | "Invalid IP address" message, no connection attempt | | |
| TC5 | `300.1.2.3` | erroneous (out of range) | "Invalid IP address" message, no connection attempt | | |
| TC6 | `1.2.3.4.5` | erroneous | "Invalid IP address" message, no connection attempt | | |

Two rows will fail. Those failing rows are your debugging targets — this is how a testing table and the debugger connect: **the table finds the fault, the debugger locates it.**

## The cycle

1. **Run the table.** Record actual output for every row. Mark Pass/Fail honestly.
2. **Locate the fault.** For each failing row, use a breakpoint on the `elif not _looks_like_ip(ip):` line (or a `print_debug` inside `_looks_like_ip`) and inspect what the check actually returns for that input. Ask: *what property of `a.b.c.d` fools this test?*
3. **Rectify.** Counting dots is not validating an IP. Godot has a built-in that does it properly — find it in the `String` class reference. Replace the naive check.
4. **Re-run the whole table** — not just the failed rows. All six should now pass (a fix that breaks TC1 or TC2 is not a fix).
5. **Record the corrective action.** In the table (or beside it), write what was wrong, what you changed, and the re-run result — one line per failed test. This is exactly the "Corrective Action" column of your alpha testing plan.
6. **Commit** with a message that names the fault.

## Now record it — practice for your C8-1 screen recording

Do the cycle **once more from scratch, on camera** (`git reset --hard` back to the branch tip first). Your recording must show **all three skills**: debugging statements, breakpoints, and the rectification. Two rows fail, so locate one with a **debugging statement** (`print_debug` inside `_looks_like_ip`) and the other with a **breakpoint** → diagnose aloud → fix → re-run to green. Narrate the whole time — *test result → diagnosis → fix* — exactly the unbroken take your real C8-1 recording requires.

> **This practice run is NOT your C8-1 evidence.** The real recording must show **your own SAT project** — your git log, your testing table, your code. Tetris is the training ground; your project is the assessment. See the C8-1 recording checklist for the four requirements (continuous narration, unbroken fix cycle, identity anchors, your actual codebase).

## What this practises

Levels 5–10 of the C8-1 rubric in one loop: test data with expected output and a **validation check** (5–6), expected vs actual with **corrective actions documented** (7–8), the complete list of actions for failed tests with everything re-run to green (9–10).

**Next:** build the same table for one module of your own SAT project — and let its failing rows pick your breakpoints.
