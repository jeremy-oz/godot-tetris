# Exercise 2 — The Bonus That Never Pays (breakpoints)

*Branch: `c8-debug-breakpoint` · Skill: breakpoints, Step Into, Locals (C8-1 rubric, level 5–6) · Time: ~20 min*

## The feature that shipped broken

We just added a **Perfect Clear bonus**: clear lines and leave the whole well empty, and you earn **+3000 × level** on top of the line score. The code is in `board.gd` — `is_board_empty()` and two new lines in `lock_piece()`.

Players report it **never pays**. Not once.

## The failing test

This is a row from a testing table — you will reproduce it with the debugger already watching:

| Test | Input / setup | Expected output | Actual output |
|---|---|---|---|
| Perfect clear pays bonus | Level 1: clear four rows at once leaving the well empty | SCORE jumps by **3800** (800 quad + 3000 bonus) + drop points | only ~800 |

**Test scaffolding (build it yourself):** a Perfect Clear is too rare in normal play to test on demand, so rig the deal. In `board.gd`, find `var shapes := [i, t, o, z, s, l, j]` near the top, comment it out, and put `var shapes := [i]` under it — every piece is now the flat I (the bag refill copies `shapes`, so it sticks). To leave the well empty you must clear **four rows at once**: two flat I's per row across columns 1–8, stacked four high, then two rotated verticals standing in columns 9 and 10. Remove the scaffold line again before you commit — your fix is in the same file, so swap the comment back by hand rather than using `git restore`.

## Your job — with the debugger, not with prints

1. **Set a breakpoint** on the `if is_board_empty():` line in `lock_piece()` — click left of the line number so the red dot appears — *before* you run the test.
2. **Reproduce the test.** Run solo and build the four lines. The moment the last piece locks and the rows clear, the game pauses on your line and the Debugger opens — `cleared` is `4`.
3. **Step Into** `is_board_empty()` and watch the **Locals** panel as you **Step Over** through the loop. Ask the debugger's question: *which cell makes this return `false` when the board looks empty?* Watch the values of `y` and `col` at the moment it bails out. Then **Continue** and watch the fail complete: the rows clear, the bonus never lands.
4. **Diagnose.** The playfield columns are **1 to 10** — what column does the loop check first? Compare with how `check_rows()` addresses the same cells.
5. **Fix it, re-run the same test.** SCORE should jump by 3800. That's the failing row turned green.
6. **Remove the scaffold, then commit** the fix with a message that says what was wrong, not just "fixed bug".

## What this practises

This is the C8-1 rubric's level 5–6 skill: *"uses breakpoints to support debugging and testing."* Two habits that matter: pause where the decision is made and **read the Locals panel** instead of guessing — and when a condition is too rare to test, **build temporary scaffolding to make it cheap**, then take the scaffolding out again.

**Next:** on your own SAT project, put the next breakpoint on the line where a wrong decision gets made — not where the symptom appears.
