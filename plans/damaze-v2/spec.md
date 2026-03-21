# Damaze v2 — Visual Overhaul & Content Expansion

## Overview

Damaze is an ice-sliding paint-maze puzzle game for iOS. The player swipes to
slide a ball in a cardinal direction until it hits a wall or boundary. Every
tile the ball crosses gets painted. Win = 100% tile coverage.

v1 shipped with 16 levels (3 hand-crafted + 13 generated) across easy/medium/hard
tiers, basic black-and-white visuals, and a linear level progression.

v2 improves the game across three axes: visuals, gameplay quality, and content.

## Current State (v1)

- **Visuals**: Flat rectangles. Walls are dark grey (`Color(white: 0.2)`), floors
  are near-white (`Color(white: 0.95)`), painted tiles are the level color at 35%
  opacity. Ball is a flat `Circle()` with a drop shadow. No depth, no texture, no
  visual identity.
- **Idle animation**: Ball scales 1.0-1.08 in a repeating pulse before the first
  move. Players perceive this as the ball "moving weirdly" — confusing, not inviting.
- **Grid limit**: 7x7 maximum.
- **Level quality**: Several levels have a "wrong first move = unsolvable" problem.
  Some levels let you get stuck in an area with no way to reach remaining tiles.
- **Navigation**: Linear progression only. Restart button exists but no level select
  or replay.

## Goals

### 1. Visual Overhaul

Create a distinctive, polished visual identity. Take inspiration from games like
Amaze (warm materials, depth, metallic ball) but develop an **original aesthetic**.
Do NOT replicate wood-grain or any specific existing game's look.

Design principles:
- **Depth and dimensionality**: Walls should feel raised or recessed. Tiles should
  have visible boundaries. The board should not look like a flat spreadsheet.
- **Warm, inviting palette**: Replace the stark black/white with colors that feel
  good to look at. Walls, floors, and painted tiles should all be clearly
  distinguishable in both light and dark mode.
- **Ball with presence**: The ball should look 3D — use gradients, highlights,
  and shadows to give it form. It should feel like a physical object, not a flat
  circle.
- **Painted tile visibility**: Painted tiles at 0.35 opacity are too subtle,
  especially purple on dark backgrounds. Painted tiles should be vibrant and
  satisfying — painting a tile should feel like progress.
- **Cohesive theme**: All elements (background, walls, floors, ball, painted tiles,
  HUD) should feel like they belong to the same visual world.

Specific fixes:
- **Kill the idle pulse animation**. Replace with something that doesn't change
  the ball's apparent size or position. Options: subtle glow oscillation, gentle
  shadow breathing, or a slow highlight rotation. The key constraint is that the
  ball should look alive but not appear to be moving.
- **Color contrast**: Painted tile colors must be clearly distinguishable from wall
  colors in both light and dark mode. Test all 6 color schemes (blue, green,
  orange, purple, teal, red) against both wall colors.

### 2. Gameplay Quality

Two distinct level design problems need fixing:

**Problem A: Area isolation ("getting stuck")**
The ball reaches a section of the board and has no moves that lead to unpainted
tiles elsewhere. The player has painted 70% of the board but can't reach the
remaining 30%. This is frustrating because it feels like a dead end with no
warning.

**Problem B: First-move dependency ("must make the right first move")**
Some levels are only solvable if the player's first move is in a specific
direction. Any other first move leads to an unsolvable state. This is punishing
because the player has no information to guide their first choice.

**Fix approach:**
- Audit all 16 current levels for both problems.
- Replace or redesign the worst offenders.
- Update the generator's quality metrics to detect and penalize:
  - Levels where >50% of starting directions lead to unsolvable states
  - Levels with isolated regions that become unreachable after any move sequence
- The goal is NOT to make levels trivially solvable. Hard levels are good. The
  challenge should be "how do I reach these last few tiles" not "I made one wrong
  move and now I'm stuck forever."

### 3. Level Select & Replay

Add a level select screen that lets players:
- See all levels with their completion status
- Replay any previously completed level
- Jump to the next unsolved level

The current restart button (HUDView) stays. This adds navigation, not replaces it.

### 4. Content Expansion

**Grid size increase:**
- Raise the max grid limit from 7x7 to at least 12x12.
- Larger grids enable more complex, interesting puzzles with corridors and rooms.

**More levels with interior walls:**
- v1 levels tend to have walls only at edges. More interesting puzzles have
  interior wall clusters that create corridors, rooms, and chokepoints.
- The generator should bias toward interior wall placement, not just random
  density.

**Level count targets:**
- Easy (4x4 to 5x5, 4-7 moves): keep existing 5 levels
- Medium (6x6 to 9x9, 8-14 moves, less tricky): add 8-10 more levels.
  Medium levels CAN be large — the defining trait is fewer trick moves, not
  smaller grids.
- Hard (8x8 to 12x12, 15-25+ moves, complex routing): add 5-8 more levels
- Target: ~30 total levels

## Architecture Constraints

- **Model layer has ZERO SwiftUI imports.** All files in `Sources/Model/` import
  only Foundation. This is a hard boundary.
- **Pure model, view animates.** GameEngine computes moves synchronously. The view
  layer receives results and animates to catch up.
- **LevelSolver and LevelGenerator** exist in the model layer and should be used
  to validate all new levels.
- **Every level in LevelStore must have a verified solution test** in
  `GameEngineTests.swift`.

## File Map

| File | Role |
|------|------|
| `Sources/Model/Level.swift` | Grid validation, 7x7 cap lives here (line 25) |
| `Sources/Model/LevelStore.swift` | All level definitions |
| `Sources/Model/LevelSolver.swift` | BFS solver with bitmask state |
| `Sources/Model/LevelGenerator.swift` | Procedural generation |
| `Sources/View/CellView.swift` | Single tile rendering (flat rectangles) |
| `Sources/View/BallView.swift` | Ball rendering (flat circle + shadow + idle pulse) |
| `Sources/View/GridView.swift` | Grid layout + ball overlay |
| `Sources/View/GameView.swift` | Main game screen, swipe gestures, level color |
| `Sources/View/HUDView.swift` | Level counter, move counter, restart button |
| `Sources/View/CompletionView.swift` | End screen |
| `Sources/App/GameViewModel.swift` | Animation sequencing, level progression |

## Implementation Phases

### Phase 1: Model — Raise Grid Limit
One-line change in `Level.swift` (raise 7x7 to 12x12). Update validation tests.
No other changes. Unblocks level generation.

### Phase 2: Visual Overhaul
Complete rework of all View files. This is the largest phase. Includes:
- New board theme (CellView, GridView background)
- New ball design (BallView)
- Fix idle animation (BallView)
- Color palette update (GameView, LevelColorScheme)
- Painted tile contrast fix (CellView)

### Phase 3: Level Select UI
New LevelSelectView. Modify GameViewModel to support non-linear level access.
Modify GameView to include navigation to level select.

### Phase 4: Level Quality & Content
- Audit and fix existing levels
- Update generator quality metrics
- Generate new medium and hard levels at larger grid sizes
- Verify all new levels with solver tests

Phases 2 and 3 can run in parallel. Phase 4 depends on Phase 1 (grid limit).
