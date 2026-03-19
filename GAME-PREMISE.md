# Damaze: Game design and mechanics breakdown

**Damaze is a hyper-casual paint-maze puzzle where a ball slides on ice-physics through grid corridors, coloring every tile it touches — and the player wins only by achieving 100% coverage.** The core idea combines a dead-simple one-finger swipe input with the constraint that the ball never stops until it hits a wall, turning what looks like a trivial maze into a genuine routing puzzle. What follows is a complete design specification.

## The ice-sliding core: swipe, slide, paint

The entire game rests on one mechanic. The player swipes in a cardinal direction (up, down, left, right), and the ball **rolls continuously until it hits a wall or maze boundary** — it does not stop at intersections, junctions, or halfway through a corridor. Every tile the ball passes over gets painted with a vibrant color. The ball can freely re-traverse already-painted tiles without penalty, but the goal is to paint every single white floor tile in the maze. This "ice-sliding" constraint is what transforms simple mazes into real puzzles: you cannot just navigate freely; you must plan your sequence of swipes so the ball reaches every tile, knowing it will overshoot any open corridor.

Input is one-finger swipe detection on mobile (comparing touch-start and touch-end positions to determine dominant axis). On console ports, it maps to d-pad or analog stick. **Input is locked during ball movement** — the player cannot queue moves while the ball is sliding. After the ball reaches its stopping point, the game checks the win condition and accepts the next swipe. The ball's movement is animated smoothly (typically via `MoveTowards` or `Lerp` in a coroutine), and the phone provides **haptic feedback** during movement, with vibration intensity varying by equipped ball skin.

## Visual design: minimal, bright, satisfying

Damaze uses a **3D top-down camera** with a slight isometric angle — not pure orthographic. Maze corridors have visible depth, with low 3D walls forming channels. The aesthetic is quintessential hyper-casual: **flat, clean, minimal geometry** with bright saturated colors against a neutral background.

Unpainted floor tiles appear **white or light gray**. As the ball rolls, it fills each tile with a single vibrant color (blue, pink, green, orange, etc.) that changes between levels for visual variety. The paint-fill animation is smooth and real-time — tiles color as the ball passes over them, creating a satisfying visual of white space transforming into a solid color field. The game includes subtle particle or splash effects on paint contact, accompanied by gentle sound design. On level completion, seeing the fully-colored maze provides the primary dopamine hit.

Four **board themes** are available: Classic (clean default), Watermelon, Wood (textured), and Dark (night mode), unlocked by completing Classic levels. Ball skins are unlockable with coins and include novelty designs like a hamburger. The UI during gameplay is deliberately **sparse**: a level counter, coin counter, skip-level button, and hint button. There's no cluttered HUD — the maze itself dominates the screen. The camera dynamically sizes to frame each level's grid, with orthographic size calculated from grid dimensions plus padding.

## Grid-based mazes with hand-crafted progression

Every level is built on a **rectangular grid** of square cells. Each cell is either a wall block or a floor tile. The maze is fully enclosed — the ball cannot exit the boundary. Internally, this is represented as a simple 2D integer array where 0 = wall, 1 = paintable floor, and 2 = ball starting position.

All levels in Damaze are **hand-crafted, not procedurally generated**. Early levels are tiny grids solvable in 3–5 moves; difficulty escalates through larger grids, more intricate wall placement, and tighter routing constraints requiring 15+ moves.

Key level design patterns include:

- **Wall protrusions ("notches")**: Deliberate indentations in walls that serve as stopping points, signaling the player should change direction from that position
- **Dead-end traps**: Areas reachable from only one direction that must be painted in the correct sequence — typically last
- **Backtracking requirements**: Some levels force the player to retrace already-painted corridors to reach a single missed tile
- **Spiral patterns**: The ball must spiral inward or outward through concentric corridors
- **Symmetrical layouts**: Many levels use symmetry, designed for natural directional flow from one section to the next
- **Single-solution levels**: Harder puzzles have only one valid move sequence that achieves 100% coverage

## Win conditions differ across five game modes

**Classic Mode** is the primary experience: no timer, no move limit, no way to lose. The player simply swipes until every floor tile is painted. The win condition is **binary — 100% coverage or nothing**. Every single tile must be colored.

**Time Rush Mode** adds urgency: the player must solve a series of mazes (typically 5) within **30 seconds**. Failing to finish in time triggers a retry option. **Limited Moves Mode** constrains the player to a set number of swipes per level, turning the routing puzzle into a strict optimization problem. **Duel Mode** is a PvP mode where two players race to complete three mazes simultaneously — first to finish wins. **Coin Levels** are bonus stages interspersed in the progression where the ball collects coins scattered across the grid.

The win-condition check is technically simple: maintain a counter of total paintable tiles (counted at level load) and increment a painted-tile counter each time a new tile is colored. When `paintedTiles >= totalPaintableTiles`, trigger level completion. This check runs after every move finishes.

## Sequential progression with coins, skins, and themes

Levels progress **strictly sequentially** — complete one to unlock the next. There is no level-select map (a common player complaint). The current level number is saved via persistent storage (PlayerPrefs in Unity implementations). On completion, the game transitions immediately to the next maze with a brief animation and a color-scheme change.

The in-game economy revolves around **coins**, earned through regular puzzle completion, daily login rewards, achievement milestones, and dedicated coin bonus levels. Coins purchase cosmetic **ball skins** and unlock **board themes**. Board themes specifically require completing a threshold number of Classic levels. There is no star rating or scoring system in the traditional sense — the core progression metric is simply whether you completed the level. The game supports Game Center integration for broader tracking.

Boosters include a **triple ball powerup** (activated by watching a video ad) that gives three simultaneous balls to paint the maze faster, and a **hint system** that walks through the solution move-by-move, also gated behind an ad view. A skip-level button is available for frustrating puzzles.

## Monetization with layered IAP

Damaze follows the hyper-casual playbook of **ad monetization**. Interstitial ads appear between levels. Ads also gate boosters and hints (rewarded video format).

In-app purchases layer on top: **ad removal**, coin packs, a lives pack (relevant to Limited Moves mode), and themed content packs. The target is a hyper-casual retention profile with **strong Day 1 retention**.

## What makes it work: the elegant constraint

The single design insight that elevates Damaze above a generic maze game is the **ice-sliding constraint**. In a normal maze, navigation is trivial — you simply walk to every tile. The inability to stop mid-corridor transforms the problem into a **Hamiltonian path puzzle under movement constraints**: the player must find an ordering of directional swipes that visits every tile, knowing each swipe commits the ball to travel the full length of a corridor. This is computationally equivalent to a constrained path-cover problem, making even small grids non-trivial.

The paint-fill visual reinforces this mechanically and psychologically. Seeing white space disappear creates a tangible sense of progress. The moment of painting the last tile delivers a clean completion signal. The color-change between levels provides just enough visual novelty to sustain engagement across thousands of levels. Combined with one-finger controls, instant-start gameplay, and sub-30-second level completion times, this creates the classic hyper-casual loop: **pick up, swipe a few levels, put down, come back later**.

## Conclusion

Damaze succeeds by finding one good constraint — ice-sliding on a grid — and executing it with polish. The technical implementation is straightforward: a 2D array of wall/floor cells, grid-based movement iteration in four directions until a wall is hit, a painted-tile counter for win detection, hand-crafted levels stored as simple data arrays, and a top-down camera sized to fit each grid. The real craftsmanship is in the **level design** — hand-authored puzzles with carefully tuned difficulty curves, strategic wall-notch placement, and single-solution routing challenges. A substantial library of hand-designed levels or a validated procedural generator that guarantees solvability under ice-sliding constraints is needed — itself an NP-hard problem in the general case.
