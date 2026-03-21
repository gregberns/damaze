# Level Design Reference — Good Patterns

Reference levels from a polished ice-sliding puzzle game. These demonstrate
what makes levels interesting vs. boring corridor snakes.

## Notation

- `0` = wall, `1` = floor, `2` = ball start
- Grid is row-major: `grid[row][col]`
- ■ = floor tile, . = wall, ● = ball start

---

## Reference A — "Interior Block" (7×7)

An L-shaped playable area with a 2×3 interior wall block that creates routing
decisions. The ball must navigate around the block, choosing which side to take.
Open floor areas are 2-3 tiles wide — NOT single-tile corridors.

```
. . . ■ ■ ■ ■
. . ■ ■ . . ■
. . ■ . . . ■
■ ■ ■ ■ ■ ■ ■
■ . . . . ■ .
■ . ■ ■ ■ ● .
■ ■ ■ . . . .
```

Grid data:
```
[0, 0, 0, 1, 1, 1, 1],
[0, 0, 1, 1, 0, 0, 1],
[0, 0, 1, 0, 0, 0, 1],
[1, 1, 1, 1, 1, 1, 1],
[1, 0, 0, 0, 0, 1, 0],
[1, 0, 1, 1, 1, 2, 0],
[1, 1, 1, 0, 0, 0, 0],
```

**Why it works:**
- Interior wall block (rows 1-2, cols 4-5) forces the ball to choose routes
- Wide connecting corridor at row 3 gives multiple slide options
- Open 3×3 floor area in bottom-left gives multi-directional choices
- Wall notch at (5,0) creates a stopping point for precise positioning
- NOT a snake — the ball has real decisions at every stop

**Design patterns used:**
- Interior wall block as routing obstacle
- L-shaped footprint (top-left cut off) — asymmetry creates interest
- Open areas (2+ tiles wide) where ice-sliding constraint matters
- Strategic stopping points from wall edges

---

## Reference B — "Dual Chambers" (10×6)

Two separate chambers (left=backward-S, right=6-shape) connected by a narrow
central corridor with a wide bottom highway. The bottleneck forces sequencing
decisions — which chamber to clear first?

```
. ■ ■ . . . . ■ ■ .
. ■ . . . . . . ■ .
. ■ ■ ■ . ■ ■ ■ ■ .
. . ■ . ● . ■ . . .
. . ■ ■ ■ ■ ■ . . .
■ ■ ■ . . . ■ ■ ■ ■
```

Grid data:
```
[0, 1, 1, 0, 0, 0, 0, 1, 1, 0],
[0, 1, 0, 0, 0, 0, 0, 0, 1, 0],
[0, 1, 1, 1, 0, 1, 1, 1, 1, 0],
[0, 0, 1, 0, 2, 0, 1, 0, 0, 0],
[0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
[1, 1, 1, 0, 0, 0, 1, 1, 1, 1],
```

**Why it works:**
- Two distinct zones require planning which to tackle first
- Interior walls within each chamber (rows 1 cols 2 and 7) create mini-routing puzzles
- Central bottleneck (col 4, rows 3-4) — once you slide through, repositioning costs moves
- Split bottom corridor (cols 0-2 and cols 6-9) means no single horizontal sweep
- Chambers have dead-end pockets (top corners) that punish wrong ordering

**Design patterns used:**
- Multi-chamber layout with bottleneck connections
- Interior walls within chambers (not just perimeter walls)
- Asymmetric chamber shapes (S vs 6) add variety
- Dead-end traps in top corners require correct sequencing
- Horizontal + vertical corridor intersection at ball start

---

## Anti-Patterns (What Our Bad Levels Do)

Our levels 12-24 are mostly **1-wide corridor snakes wrapped around voids**.
The ball follows the only possible path with zero routing decisions.

Bad example — "Courtyard" (level 15):
```
. . ■ ■ ■ ■ ■ .
. . ■ . . . ■ .
■ ■ ■ . . . ■ ■
■ . . . . . . ■     ← 4×4 void, corridor wraps around it
■ . . . . . . ■     ← only ONE path possible
■ ■ ■ . . . ■ ■
. . ■ . . . ■ .
. . ■ ■ ● ■ ■ .
```

**Why it fails:**
- 1-tile-wide corridor throughout — no width for ice-sliding to matter
- Massive interior void wastes grid space
- Only one direction possible at every point — it's a tube, not a puzzle
- Ice-sliding constraint is irrelevant when there's only one way to go

---

## Key Principles for New Levels

1. **Open areas (2+ tiles wide)** — the ice-sliding constraint only matters when
   the ball can slide multiple tiles in multiple directions

2. **Interior wall blocks** — not just perimeter walls. Place 1×1, 2×1, 2×2 blocks
   INSIDE open areas to create stopping points and routing decisions

3. **Wall notches/protrusions** — single-cell bumps off walls give the ball places
   to stop mid-area, creating decision points that don't exist in corridors

4. **Multiple possible move sequences** — good levels have many ways to START but
   few that achieve 100% coverage. The player must THINK.

5. **Dead-end pockets** — small areas reachable from only one direction that must
   be painted in the correct sequence (first or last)

6. **Bottleneck connections** — use narrow passages to connect larger areas,
   forcing the player to plan which area to clear first

7. **60-80% floor coverage** — aim for grids that are mostly floor with strategic
   wall placement, not mostly wall with thin corridors

8. **Asymmetry** — symmetric levels feel predictable. Break symmetry to create
   surprising routing requirements
