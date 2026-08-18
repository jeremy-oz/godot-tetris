# Exercise 2 — The Bonus That Never Pays (breakpoints)

*Branch: `c8-debug-breakpoint` · Skill: breakpoints, Step Into, Locals (C8-1 rubric, level 5–6) · Time: ~20 min*

## The feature that shipped broken

We just added a **Perfect Clear bonus**: clear a line and leave the whole well empty, and you earn **+3000 × level** on top of the line score. The code is in `board.gd` — `is_board_empty()` and two new lines in `lock_piece()`.

Players report it **never pays**. Not once.

## The failing test

This is a row from a testing table — reproduce it first:

| Test | Input / setup | Expected output | Actual output |
|---|---|---|---|
| Perfect clear pays bonus | Level 1: clear the bottom row leaving the well empty | SCORE jumps by **3100** (100 line + 3000 bonus) + drop points | only ~100 |

**Quick setup (test helper):** start a solo game and press **T** — the bottom row fills except columns 7–10, so one flat I-piece finishes it. Use **Hold (C)** to bank pieces until the I arrives, move it right over the gap, and hard-drop (**Space**). The row clears, the well is empty — watch the SCORE label.

## Your job — with the debugger, not with prints

1. **Set a breakpoint** on the `if is_board_empty():` line in `lock_piece()` — click left of the line number so the red dot appears.
2. **Reproduce the test.** Run solo, press T, place the I. When the piece locks, the game pauses on your line and the Debugger opens.
3. **Step Into** `is_board_empty()` and watch the **Locals** panel as you **Step Over** through the loop. Ask the debugger's question: *which cell makes this return `false` when the board looks empty?* Watch the values of `y` and `col` at the moment it bails out.
4. **Diagnose.** The playfield columns are **1 to 10** — what column does the loop check first? Compare with how `check_rows()` addresses the same cells.
5. **Fix it, re-run the same test.** SCORE should jump by 3100. That's the failing row turned green.
6. **Commit** the fix with a message that says what was wrong, not just "fixed bug".

## What this practises

This is the C8-1 rubric's level 5–6 skill: *"uses breakpoints to support debugging and testing."* The habit that matters: pause where the decision is made, then **read the Locals panel** instead of guessing.

**Next:** on your own SAT project, put the next breakpoint on the line where a wrong decision gets made — not where the symptom appears.
