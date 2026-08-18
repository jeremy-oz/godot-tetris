# Exercise 1 — Find the Phantom Points (debugging statements)

*Branch: `c8-debug-statements` · Skill: debugging statements (C8-1 rubric, level 3–4) · Time: ~15 min*

## The bug report

> Players say the score creeps up **on its own** while a piece is falling — no soft drop, no hard drop, no line clear. Start a solo game, take your hands off the keyboard, and watch the SCORE label.

**Expected behaviour:** the score only changes from a **soft drop** (+1 per row), a **hard drop** (+2 per row), or a **line clear** (100/300/500/800 × level).

## Your job

Find the line that adds the phantom points — using **debugging statements only**. No breakpoints this time, and no fair reading `git diff main`: the point is to practise the tool, not to win.

1. **Reproduce it.** Run the solo scene and watch the SCORE label while a piece falls untouched. Confirm the bug is real before touching any code — that's your failing test.
2. **List the suspects.** Search `board.gd` for every line containing `score +=`. Each one is a place the points could come from.
3. **Instrument each suspect.** Above each `score +=`, add a debugging statement, e.g.:

   ```gdscript
   print_debug("score +%d here" % 1)
   ```

   `print_debug` prints the script and line number with the message — so the Output panel tells you exactly which site fired.
4. **Run and read the Output panel.** Which line prints while the piece just falls? That's your culprit.
5. **Fix it.** Work out what condition is missing on that line, and restore it.
6. **Re-run the same test.** Hands off the keyboard — the score should now hold still, and soft drop should still pay +1 per row.
7. **Clean up and commit.** Comment out (or remove) your debugging statements and commit the fix. The added-then-removed prints in your git history are themselves debugging evidence.

## What this practises

This is the C8-1 rubric's level 3–4 skill: *"uses debugging statements to check the functionality of the software solution."* A debugging statement earns its keep when it answers a question — here: *which line ran?*

**Next:** do exactly this on your own SAT project the next time a number is wrong and you don't know who changed it.
