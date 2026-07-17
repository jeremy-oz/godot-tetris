# Chapter 05 — Guideline scoring, levels and the gravity curve

**Git ref:** part of `b08589a` (const `LINE_SCORES`, functions `lock_piece`
scoring branch, `fall_interval`, `update_labels`; LINES/LEVEL labels).

**Learning goals:** data-driven design (a table instead of if-chains),
returning values from functions that used to just "do things",
a real-world formula.

## What gets built

1. `check_rows()` returns HOW MANY rows it cleared (it used to score
   inline). Enables the multi-line bonus:

```gdscript
const LINE_SCORES := [0, 100, 300, 500, 800]   # indexed by lines cleared

# in lock_piece():
var cleared := check_rows()
if cleared > 0:
    lines += cleared
    score += LINE_SCORES[cleared] * level
    level = mini(1 + floori(lines / 10.0), 20)
```

   Emphasize the array-as-table idiom: 4 lines = 800, not 4×100 — clearing
   big is disproportionately rewarded (sets up the versus attack table).
2. **Levels**: +1 every 10 lines, capped at 20.
3. **Gravity curve** (official Guideline formula):

```gdscript
func fall_interval() -> float:
    return pow(0.8 - (level - 1) * 0.007, level - 1)
```

   Level 1 → 1.0 s per row; level 10 → ~0.16 s; level 20 → ~0.007 s.
   Nice cross-curricular moment: graph it.
4. Drop scoring recap (already wired in ch01/02): soft +1/cell, hard
   +2/cell — both flat, not multiplied by level.
5. LINES/LEVEL labels + `update_labels()` (one function, called
   everywhere state changes).

## Verify

- Clear 2 lines at once: +300×level (not +200).
- Reach 10 lines: LEVEL flips to 2 and pieces visibly fall faster.
- Headless tests: `scoring:` and `gravity:` test group.

## Pitfalls

- Integer division warning: `lines / 10` trips GDScript's warning; use
  `floori(lines / 10.0)`.
- Score the clear BEFORE inserting garbage (matters in ch10; keeping
  `lock_piece` ordered now avoids a later refactor).
