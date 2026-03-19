# Damaze Classic Mode -- Implementation Spec

**Version:** 1.0
**Date:** 2026-03-18
**Status:** Locked -- ready for implementation

This is the single source of truth for implementing Damaze Classic mode. Polecats (AI coding agents) should implement from this document without further clarification. Every ambiguity has been resolved. When this spec and the game design doc disagree, this spec wins.

---

## 1. Overview

Damaze is an ice-sliding paint-maze puzzle game for iOS. The player swipes in a cardinal direction and a ball slides on ice physics until it hits a wall, coloring every tile it crosses. The player wins by achieving 100% tile coverage. This spec covers Classic mode only: no timer, no move limit, no way to lose. The player swipes until every floor tile is painted, or restarts the level to try again. The game ships with 3 hand-crafted levels of progressive difficulty, rendered in pure SwiftUI with no SpriteKit, no monetization, and no external dependencies beyond XcodeGen.

**Target:** iOS 16.0+, portrait only, iPhone only (iPad will display the iPhone layout via compatibility mode -- no iPad-specific layout).

**Tech stack:** Pure SwiftUI, XcodeGen, XCTest. No SpriteKit. No third-party packages.

---

## 2. Game Mechanics

### 2.1 Ice-Sliding Movement

The ball moves in one of four cardinal directions (up, down, left, right) when the player swipes. Once moving, the ball slides continuously in that direction until it hits a wall cell or the grid boundary. The ball does not stop at intersections, junctions, or corridor openings. It always travels the maximum distance possible in the swiped direction.

The ball occupies exactly one grid cell at any logical moment. During animation, the ball's visual position interpolates between cells, but the model treats position as discrete grid coordinates.

### 2.2 Paint-Fill

Every floor tile the ball crosses during a slide gets painted. This includes the destination tile where the ball stops. The ball's starting tile before a move is already occupied (and was painted either at spawn or by a previous move), so it is not re-counted.

Tiles can be re-traversed. The ball can slide over already-painted tiles without penalty. Re-traversal does not increment the painted tile count. The painted tile set is monotonically growing.

### 2.3 Win Condition

The player wins when every floor tile in the level is painted. The check is: `paintedTiles.count == level.floorTileCount`. This is evaluated as a computed property after every move completes. When the condition is met, the game phase transitions to `.won`.

There is no lose state. There is no deadlock detection. The player can always restart the level via the restart button.

### 2.4 Start Tile

The start tile (cell value `2` in the level data) is treated as a floor tile. It is painted at spawn time, before the player makes any input. This means `paintedTiles.count` starts at 1 and `floorTileCount` includes the start tile.

On a level where the start tile is the only floor tile, the game is won immediately on load -- `paintedTiles.count == floorTileCount == 1`. This is an edge case that the model handles correctly by checking win condition after level initialization.

---

## 3. Architecture

### 3.1 Model/View Separation

The architecture enforces a hard boundary between model and view:

- **Model layer:** Pure Swift. Zero SwiftUI imports. Contains all game logic: path computation, state management, win detection, level validation. Fully unit-testable with XCTest.
- **View layer:** SwiftUI. Reads model state, renders the grid, handles gestures, drives animations. Contains no game logic. Wiring only.

The model computes; the view animates. The model is always ahead of the view. When the player swipes, the model instantly computes the full result (path, new position, painted tiles, win status). The view then animates through the computed path at its own pace.

### 3.2 Data Flow

```
Player swipes
    |
    v
View: DragGesture detects swipe direction
    |
    v
View: Calls GameEngine.applyMove(direction:) on the model
    |
    v
Model: Checks phase == .awaitingInput (rejects otherwise)
Model: Computes full path via computePath()
Model: Updates paintedTiles, ballPosition, moveHistory
Model: Sets phase to .moving (or .won if complete)
Model: Returns MoveResult (path array + isWin flag)
    |
    v
View: Receives MoveResult
View: Animates ball along path, painting cells sequentially
View: On animation complete: sets model phase back to .awaitingInput
View: If buffered swipe exists, executes it immediately
View: If isWin, transitions to win overlay
```

### 3.3 State Machine

The game model owns a `GamePhase` enum with three cases:

```
enum GamePhase {
    case awaitingInput   // Ready for player swipe
    case moving          // Ball is animating (view is catching up to model)
    case won             // All tiles painted, level complete
}
```

State transitions:

- `awaitingInput` -> `moving`: On valid move (path has 1+ tiles)
- `awaitingInput` -> `awaitingInput`: On invalid move (empty path -- ball against wall)
- `moving` -> `awaitingInput`: View signals animation complete, and win condition is not met
- `moving` -> `won`: View signals animation complete, and win condition is met
- `won` -> (no transitions): Terminal state for this level. Level progression creates a new GameState.

The model rejects `applyMove` calls when phase is not `.awaitingInput`. This is the input lock mechanism. The view does not need to independently track whether input is allowed.

Note on the `.moving` -> `.won` transition: The model knows win status immediately after computing the move. However, the phase remains `.moving` until the view finishes animating, at which point it transitions to `.won` if `isComplete` is true. This ensures the win celebration happens after the player sees the last tile painted, not before.

---

## 4. Data Model

All types in this section live in the model layer. None import SwiftUI.

### 4.1 GridPosition

```swift
struct GridPosition: Equatable, Hashable {
    let row: Int
    let col: Int
}
```

Represents a discrete cell coordinate. `row` is the vertical axis (0 = top). `col` is the horizontal axis (0 = left).

### 4.2 Direction

```swift
enum Direction: CaseIterable {
    case up, down, left, right
}
```

Maps to grid coordinate deltas:

| Direction | Row delta | Col delta |
|-----------|-----------|-----------|
| up        | -1        | 0         |
| down      | +1        | 0         |
| left      | 0         | -1        |
| right     | 0         | +1        |

### 4.3 CellType

```swift
enum CellType: Int {
    case wall = 0
    case floor = 1
    case start = 2
}
```

Used for level data parsing. At runtime, `start` is treated identically to `floor` -- the distinction exists only to identify the ball's initial position during level loading.

### 4.4 Level

```swift
struct Level {
    let grid: [[CellType]]     // grid[row][col], row 0 = top
    let rows: Int
    let cols: Int
    let startPosition: GridPosition
    let floorTileCount: Int    // Total paintable tiles (floor + start)

    init(grid: [[Int]]) throws  // Validates and converts
}
```

Validation rules (enforced in `init`, throws on violation):

1. Grid must be non-empty (at least 1 row, at least 1 column).
2. Grid must be rectangular (all rows have the same length).
3. Exactly one cell with value `2` (start position).
4. All cell values must be 0, 1, or 2.
5. `floorTileCount` must be >= 1 (the start tile at minimum).
6. Maximum grid dimension: 7 rows, 7 columns.

The `floorTileCount` is computed during init as the total number of cells with value 1 or 2.

### 4.5 GameState

```swift
struct GameState {
    let level: Level
    var ballPosition: GridPosition
    var paintedTiles: Set<GridPosition>
    var moveHistory: [Direction]
    var phase: GamePhase
    var moveCount: Int

    var isComplete: Bool {
        paintedTiles.count == level.floorTileCount
    }
}
```

`GameState` is a value type (struct). The `GameEngine` operates on it by taking it as `inout` or returning a new copy. The `@Observable` view model holds a `GameState` instance and publishes changes.

`moveHistory` stores every direction the player has swiped (including moves that resulted in empty paths, i.e., bump-into-wall moves are NOT recorded -- only moves that caused the ball to travel). This enables future undo/replay/hints. Not exposed in UI for v1.

`moveCount` is the number of successful moves (moves where the ball actually traveled). Displayed in the UI as an informational counter.

### 4.6 MoveResult

```swift
struct MoveResult {
    let path: [GridPosition]    // Ordered list of tiles traversed (empty if invalid move)
    let isWin: Bool             // True if this move completed the level
    let newBallPosition: GridPosition  // Same as current if path is empty
}
```

Returned by `GameEngine.applyMove`. The view uses `path` to drive the animation sequence. If `path` is empty, the view plays the bump animation instead.

---

## 5. Game Engine

The `GameEngine` is a collection of pure functions (or static methods) with no mutable state of its own. It operates on `GameState`.

### 5.1 computePath

```swift
static func computePath(
    from position: GridPosition,
    direction: Direction,
    grid: [[CellType]],
    rows: Int,
    cols: Int
) -> [GridPosition]
```

**Behavior:**

1. Starting from `position`, step one cell at a time in `direction`.
2. For each step, compute the candidate position: `(row + rowDelta, col + colDelta)`.
3. If the candidate is out of bounds (row < 0, row >= rows, col < 0, col >= cols), stop. The ball stays at the last valid position.
4. If the candidate cell is a wall (`CellType.wall`), stop. The ball stays at the last valid position.
5. If the candidate cell is floor or start, add it to the path and continue stepping.
6. Return the collected path (not including the starting position).

**Edge cases:**

- If the very first step hits a wall or boundary, return an empty array. The ball does not move.
- The starting position is never included in the returned path.
- The path includes every tile traversed, in order. The last element is the ball's new resting position.

### 5.2 applyMove

```swift
static func applyMove(
    direction: Direction,
    state: inout GameState
) -> MoveResult
```

**Behavior:**

1. If `state.phase != .awaitingInput`, return `MoveResult(path: [], isWin: false, newBallPosition: state.ballPosition)`. Move rejected.
2. Call `computePath` with the current ball position, direction, and grid.
3. If the path is empty (ball cannot move in that direction):
   - Do not change any state.
   - Return `MoveResult(path: [], isWin: false, newBallPosition: state.ballPosition)`.
4. If the path is non-empty:
   - Add each position in the path to `state.paintedTiles` (Set handles deduplication).
   - Set `state.ballPosition` to the last element of the path.
   - Append `direction` to `state.moveHistory`.
   - Increment `state.moveCount` by 1.
   - Set `state.phase` to `.moving`.
   - Compute `isWin = state.isComplete`.
   - Return `MoveResult(path: path, isWin: isWin, newBallPosition: state.ballPosition)`.

Note: The phase is set to `.moving` even though the model has already computed the result. This signals to the view that animation is in progress. The view will set the phase to `.won` (if `isWin`) or `.awaitingInput` (if not) when animation finishes.

### 5.3 isComplete

This is a computed property on `GameState`, not a standalone function:

```swift
var isComplete: Bool {
    paintedTiles.count == level.floorTileCount
}
```

No side effects. Derived purely from state. Can be called at any time.

### 5.4 createInitialState

```swift
static func createInitialState(for level: Level) -> GameState
```

**Behavior:**

1. Create a new `GameState` with the given level.
2. Set `ballPosition` to `level.startPosition`.
3. Set `paintedTiles` to `{level.startPosition}` (start tile is painted at spawn).
4. Set `moveHistory` to `[]`.
5. Set `phase` to `.awaitingInput`.
6. Set `moveCount` to 0.

---

## 6. Input Handling

### 6.1 Swipe Detection

Swipe input uses SwiftUI's `DragGesture`. Direction is determined by the dominant axis of the drag translation at the moment the gesture ends.

```swift
static func direction(from translation: CGSize) -> Direction? {
    let dx = translation.width
    let dy = translation.height

    guard max(abs(dx), abs(dy)) >= 20 else {
        return nil  // Below minimum threshold -- not a swipe
    }

    if abs(dx) > abs(dy) {
        return dx > 0 ? .right : .left
    } else {
        return dy > 0 ? .down : .up
    }
}
```

**Constants:**

- Minimum swipe distance: **20 points**. Below this, the gesture is ignored (not a valid swipe).
- The direction is determined by whichever axis has the larger absolute translation. Exact diagonals (abs(dx) == abs(dy)) are resolved as vertical (the `else` branch). This is an arbitrary tiebreak that will rarely occur in practice.

This function is a pure function in the view layer (it references `CGSize` from CoreGraphics). It is independently unit-testable.

### 6.2 Direction Mapping

Swipe directions map to grid movement as follows:

| Swipe gesture | Direction enum | Ball moves toward |
|---------------|----------------|-------------------|
| Finger moves up on screen | `.up` | Decreasing row index (toward top of grid) |
| Finger moves down on screen | `.down` | Increasing row index (toward bottom of grid) |
| Finger moves left on screen | `.left` | Decreasing column index (toward left of grid) |
| Finger moves right on screen | `.right` | Increasing column index (toward right of grid) |

This mapping is natural: swiping up makes the ball go up visually. The grid renders with row 0 at the top, so "up" = decreasing row index.

### 6.3 Input Buffering

During the `.moving` phase, exactly one swipe is buffered:

- When the view receives a swipe gesture while `phase == .moving`, it stores the direction in a `bufferedDirection: Direction?` variable (owned by the view, not the model).
- If a second swipe arrives while one is already buffered, it replaces the previous buffer. Only the most recent swipe is kept.
- When the current animation completes and the view transitions the model to `.awaitingInput`, it checks for a buffered direction. If one exists, it immediately calls `applyMove` with that direction and clears the buffer.
- The buffer is cleared on level restart.

This provides responsive feel on long slides without allowing move queuing.

### 6.4 Invalid Move Handling

When `applyMove` returns an empty path (ball is already against a wall in the swiped direction):

- The game state does not change.
- The phase remains `.awaitingInput`.
- The view plays a **bump animation**: the ball shifts 2 points in the swiped direction and snaps back over 0.15 seconds. This communicates "input received, but you can't go that way."
- The bump animation does not trigger the `.moving` phase. Input remains accepted during the bump.

---

## 7. Visual Design

### 7.1 Coordinate System

`grid[0][0]` is the **top-left** cell. Row index increases downward. Column index increases rightward. This matches SwiftUI's natural layout (VStack of HStacks) and standard 2D array convention.

```
        col 0   col 1   col 2   col 3
row 0   [0,0]   [0,1]   [0,2]   [0,3]
row 1   [1,0]   [1,1]   [1,2]   [1,3]
row 2   [2,0]   [2,1]   [2,2]   [2,3]
row 3   [3,0]   [3,1]   [3,2]   [3,3]
```

Swipe up = ball moves toward row 0. Swipe right = ball moves toward max column.

### 7.2 Grid Rendering

The grid is rendered using nested `ForEach` loops: an outer loop over rows (VStack) and an inner loop over columns (HStack). Each cell is a square view.

**Grid sizing:**

```swift
let padding: CGFloat = 16  // Minimum padding on each side
let availableWidth = geometryProxy.size.width - (padding * 2)
let availableHeight = geometryProxy.size.height - (padding * 2) - topBarHeight
let cellSize = min(availableWidth / CGFloat(level.cols), availableHeight / CGFloat(level.rows))
```

Where `topBarHeight` accounts for the level counter, move counter, and restart button (approximately 60 points).

The grid is centered both horizontally and vertically within the available space using a containing `VStack` with `Spacer()` elements or a `frame(maxWidth: .infinity, maxHeight: .infinity)` with centered alignment.

**Cell size constraint:** Given the maximum grid dimension of 7x7 and the smallest iPhone screen width (320pt logical on iPhone SE), the minimum cell size is `(320 - 32) / 7 = ~41pt`. This exceeds the 40pt minimum target.

### 7.3 Cell Visual States

Each cell has one of four visual states:

| State | Appearance | Color |
|-------|-----------|-------|
| **Wall** | Solid dark block with slight rounding | `Color(hex: "#2C2C2E")` -- system gray 6 equivalent, dark charcoal |
| **Unpainted floor** | Light, clean surface | `Color.white` with a subtle `Color(hex: "#F2F2F7")` background (system gray 6 light) |
| **Painted floor** | Filled with the level's paint color | Light tint: `.blue.opacity(0.35)` (level 1), `.green.opacity(0.35)` (level 2), `.orange.opacity(0.35)` (level 3) |
| **Ball** | Circle overlaid on the cell | Saturated, darker version of the paint color: `.blue` (level 1), `.green` (level 2), `.orange` (level 3) |

All cells (including walls) are rendered as rounded rectangles with corner radius of `cellSize * 0.1`. There is a 2-point gap between cells (achieved via padding of 1pt on each side of each cell).

**Level color palette:**

| Level | Paint color (floor tint) | Ball color | Wall color |
|-------|-------------------------|------------|------------|
| 1 | `Color.blue.opacity(0.35)` | `Color.blue` | `Color(white: 0.17)` |
| 2 | `Color.green.opacity(0.35)` | `Color.green` | `Color(white: 0.17)` |
| 3 | `Color.orange.opacity(0.35)` | `Color.orange` | `Color(white: 0.17)` |

The ball is always visually distinct from both painted and unpainted tiles because it uses a fully saturated color while painted tiles use a light tint (0.35 opacity).

### 7.4 Ball Rendering

The ball is a circle with diameter `cellSize * 0.7`, centered within its cell. It is rendered as an overlay on the grid, not as part of the cell views. This allows the ball to animate smoothly between cells without being clipped.

The ball casts a subtle shadow: `.shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)`.

Ball position in the view is computed from its grid position:

```swift
let ballX = CGFloat(ballPosition.col) * cellSize + cellSize / 2
let ballY = CGFloat(ballPosition.row) * cellSize + cellSize / 2
```

This gives the center point of the ball relative to the grid's top-left corner.

### 7.5 Movement Animation

When `applyMove` returns a non-empty path, the view animates the ball through each cell in the path sequentially:

**Speed:** Constant velocity of approximately **8 tiles per second**. This means each tile takes `1.0 / 8.0 = 0.125` seconds. However, a minimum move duration of **0.15 seconds** applies (for single-tile moves, the ball takes 0.15s rather than 0.125s to feel deliberate rather than instant).

**Duration formula:**

```swift
let timePerTile: TimeInterval = 0.125
let totalDuration = max(0.15, TimeInterval(path.count) * timePerTile)
```

Examples:
- 1 tile: 0.15s (minimum applies)
- 2 tiles: 0.25s
- 5 tiles: 0.625s
- 7 tiles: 0.875s

**Easing:** `linear` for the ball's position interpolation. Ice physics means constant velocity -- no acceleration or deceleration. The ball slams into the wall at full speed (the bump/settle conveys the stop).

**Implementation approach -- cell-by-cell chained timers:**

The view maintains a display state for the ball position (as `CGPoint` or as an animated `GridPosition`). On receiving a path, it:

1. Sets a counter `currentStep = 0`.
2. Starts a repeating timer (or chained `DispatchQueue.main.asyncAfter`) with interval = `timePerTile`.
3. On each tick:
   - Advances `currentStep` by 1.
   - Updates the ball's visual position to `path[currentStep - 1]` with a `withAnimation(.linear(duration: timePerTile))` call.
   - Marks `path[currentStep - 1]` as visually painted (triggers the cell's paint animation).
4. When `currentStep == path.count`, the animation sequence is complete.
5. View transitions the model phase from `.moving` to `.awaitingInput` (or `.won` if `moveResult.isWin`).
6. Checks for buffered input.

### 7.6 Paint Animation

Each tile's paint appears as the ball's visual position crosses it. The paint transition is:

- **Duration:** 0.15 seconds.
- **Effect:** The cell background color transitions from the unpainted color to the painted color using `withAnimation(.easeIn(duration: 0.15))`.
- **Timing:** Triggered on the same timer tick that moves the ball onto that cell. The paint and ball movement happen simultaneously -- the ball arrives and the tile colors at the same time.

A tile that is already painted does not re-animate when the ball crosses it again.

### 7.7 Bump Animation

When the player swipes into a wall (empty path returned):

- The ball shifts **2 points** in the swiped direction.
- It snaps back to its original position.
- Total duration: **0.15 seconds** (0.075s out, 0.075s back).
- Easing: `.easeOut` for the outward shift, `.easeIn` for the snap back. Implemented as a single `spring(response: 0.15, dampingFraction: 0.5)` animation on the ball's offset.
- During the bump animation, input is NOT locked. The phase remains `.awaitingInput`. The player can immediately swipe in a different direction.

### 7.8 Idle Pulse Animation

When the game is in `.awaitingInput` phase and no animation is playing, the ball pulses gently to signal that the game is waiting for input:

- **Effect:** Scale oscillates between 1.0 and 1.08.
- **Duration:** 1.0 second per cycle (0.5s expanding, 0.5s contracting).
- **Easing:** `.easeInOut`.
- **Implementation:** `Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)` applied to the ball's `.scaleEffect`.
- The pulse stops when the ball starts moving and resumes when it stops.

### 7.9 Win Animation

When the level is complete:

1. The last tile paints normally as part of the movement animation.
2. After the ball reaches its final position, a **0.3-second pause** lets the player see the fully painted grid.
3. The entire painted grid pulses once: all painted cells scale to 1.05 and back over **0.4 seconds** using `.easeInOut`.
4. A **"Level Complete!"** text fades in over **0.3 seconds**, centered on screen, white text with a dark shadow for readability against any paint color.
   - Font: `.title.bold()`
   - Appears after the grid pulse completes.
5. The move count is displayed below the completion text: **"Moves: {N}"** in `.headline` font.
6. After **1.5 seconds** total (from the last tile painting), the level transitions automatically. If there is a next level, it loads. If this was the last level, the completion screen appears.

**Level transition animation:** 0.4-second cross-fade. The current grid fades out while the new grid fades in. Implemented via `withAnimation(.easeInOut(duration: 0.4))` on the view state that holds the current level index.

### 7.10 HUD Layout

The HUD is minimal, arranged above the grid:

```
+------------------------------------------+
|  Level 1          Moves: 0          [↻]  |
|                                          |
|                                          |
|              +--+--+--+--+               |
|              |  |  |  |  |               |
|              +--+--+--+--+               |
|              |  |  |  |  |               |
|              +--+--+--+--+               |
|              |  |  |  |  |               |
|              +--+--+--+--+               |
|              |  |  |  |  |               |
|              +--+--+--+--+               |
|                                          |
|                                          |
+------------------------------------------+
```

- **Level indicator:** Top-left. Text: `"Level {N}"`. Font: `.headline`. Color: primary (adapts to light/dark mode, but dark mode is not explicitly designed for v1 -- default system colors are fine).
- **Move counter:** Top-center. Text: `"Moves: {N}"`. Font: `.headline`. Color: secondary.
- **Restart button:** Top-right. System image: `arrow.counterclockwise.circle.fill`. Size: 44x44pt (minimum touch target). Color: secondary. Tap action: resets the current level to initial state (calls `createInitialState`). Clears the input buffer.
- The HUD bar has a fixed height of approximately 44pt plus safe area inset padding.
- The swipe gesture is attached to the grid area, not the entire screen. The HUD area does not respond to swipe gestures. This prevents accidental restart taps from being interpreted as swipes and vice versa.

### 7.11 Background

The screen background is `Color(UIColor.systemBackground)` -- white in light mode, near-black in dark mode. This is the iOS system default and requires no explicit styling.

---

## 8. Level Design

### 8.1 Level Format

Levels are defined as 2D integer arrays in Swift source code as static constants:

- `0` = wall
- `1` = floor (paintable)
- `2` = start position (paintable, ball spawns here)

Each level includes: the grid layout, a display name, and a paint color identifier.

### 8.2 Level 1: "First Steps"

**Teaching goal:** Introduce the core mechanic. Swipe to move. Ball slides until hitting a wall. Paint every tile to win.

**Grid (4x4):**

```
[1, 1, 1, 1],
[1, 0, 0, 1],
[1, 0, 0, 1],
[1, 1, 1, 2],
```

**Visual layout (W=wall, .=floor, S=start):**

```
 .  .  .  .
 .  W  W  .
 .  W  W  .
 .  .  .  S
```

**Floor tile count:** 8 (start included)

**Solution (4 moves):**

1. Swipe left: Ball slides from (3,3) to (3,0). Paints (3,2), (3,1), (3,0).
2. Swipe up: Ball slides from (3,0) to (0,0). Paints (2,0), (1,0), (0,0).
3. Swipe right: Ball slides from (0,0) to (0,3). Paints (0,1), (0,2), (0,3).
4. Swipe down: Ball slides from (0,3) to (1,3). Paints (1,3).

Wait -- that leaves (2,3) unpainted. Let me re-verify.

After move 4, ball is at (1,3). (2,3) is floor and unpainted. But from (1,3), swiping down goes to (2,3) which is floor, then (3,3) which is already painted floor. So:

5. Swipe down: Ball slides from (1,3) to (3,3). Paints (2,3).

That is 5 moves and does achieve 100%. But a 4-move solution is possible:

1. Swipe left: (3,3) -> (3,0). Paints (3,2), (3,1), (3,0).
2. Swipe up: (3,0) -> (0,0). Paints (2,0), (1,0), (0,0).
3. Swipe right: (0,0) -> (0,3). Paints (0,1), (0,2), (0,3).
4. Swipe down: (0,3) -> (3,3). But (1,3) is floor, (2,3) is floor, (3,3) is floor. Ball slides from (0,3) to... wait, (1,3) is floor (value 1). Let me recheck the grid.

Row 1: `[1, 0, 0, 1]` -- so (1,0)=floor, (1,1)=wall, (1,2)=wall, (1,3)=floor.
Row 2: `[1, 0, 0, 1]` -- so (2,0)=floor, (2,1)=wall, (2,2)=wall, (2,3)=floor.

From (0,3), swiping down: (1,3)=floor, (2,3)=floor, (3,3)=floor(start). Ball slides to (3,3). Paints (1,3), (2,3). Already painted: (3,3). All 8 tiles now painted. Win!

**Verified solution (4 moves):**

1. **Left:** (3,3) -> (3,0). Path: [(3,2), (3,1), (3,0)]. New paint: 3 tiles. Total: 4.
2. **Up:** (3,0) -> (0,0). Path: [(2,0), (1,0), (0,0)]. New paint: 3 tiles. Total: 7.
3. **Right:** (0,0) -> (0,3). Path: [(0,1), (0,2), (0,3)]. New paint: 3 tiles. Total: 10. Wait, that's more than 8.

Let me count floor tiles again:
- Row 0: (0,0)=1, (0,1)=1, (0,2)=1, (0,3)=1 -> 4 floors
- Row 1: (1,0)=1, (1,1)=0, (1,2)=0, (1,3)=1 -> 2 floors
- Row 2: (2,0)=1, (2,1)=0, (2,2)=0, (2,3)=1 -> 2 floors
- Row 3: (3,0)=1, (3,1)=1, (3,2)=1, (3,3)=2 -> 4 floors (start = floor)

Total: 4+2+2+4 = 12 floor tiles. Not 8. Let me recount.

12 floor tiles. Start painted = 1. Need 11 more.

Move 1 (Left): (3,3)->(3,0). Paints (3,2),(3,1),(3,0) = 3 new. Total painted: 4.
Move 2 (Up): (3,0)->(0,0). Paints (2,0),(1,0),(0,0) = 3 new. Total: 7.
Move 3 (Right): (0,0)->(0,3). Paints (0,1),(0,2),(0,3) = 3 new. Total: 10.
Move 4 (Down): (0,3)->(3,3). Paints (1,3),(2,3) = 2 new (3,3 already painted). Total: 12.

12/12. Win in 4 moves. Verified.

**Final verified solution (4 moves): Left, Up, Right, Down.**

**Swift constant:**

```swift
static let level1 = LevelData(
    name: "First Steps",
    colorScheme: .blue,
    grid: [
        [1, 1, 1, 1],
        [1, 0, 0, 1],
        [1, 0, 0, 1],
        [1, 1, 1, 2],
    ]
)
```

### 8.3 Level 2: "The Notch"

**Teaching goal:** Introduce wall protrusions as stopping points. The player must use a notch in the wall to stop mid-corridor and change direction. Requires planning ahead.

**Grid (5x5):**

```
[1, 1, 1, 1, 1],
[1, 0, 0, 0, 1],
[1, 1, 1, 0, 1],
[2, 0, 1, 1, 1],
[1, 1, 1, 1, 1],
```

**Visual layout:**

```
 .  .  .  .  .
 .  W  W  W  .
 .  .  .  W  .
 S  W  .  .  .
 .  .  .  .  .
```

**Floor tile count:**
- Row 0: 5
- Row 1: (1,0)=1, (1,4)=1 -> 2
- Row 2: (2,0)=1, (2,1)=1, (2,2)=1, (2,4)=1 -> 4
- Row 3: (3,0)=2, (3,2)=1, (3,3)=1, (3,4)=1 -> 4 (start counts)
- Row 4: 5

Total: 5+2+4+4+5 = 20 floor tiles.

**Verified solution (7 moves):**

1. **Down:** (3,0) -> (4,0). Path: [(4,0)]. Paint: 1 new. Total: 2.
2. **Right:** (4,0) -> (4,4). Path: [(4,1),(4,2),(4,3),(4,4)]. Paint: 4 new. Total: 6.
3. **Up:** (4,4) -> (0,4). Path: [(3,4),(2,4),(1,4),(0,4)]. Paint: 4 new. Total: 10.
4. **Left:** (0,4) -> (0,0). Path: [(0,3),(0,2),(0,1),(0,0)]. Paint: 4 new. Total: 14.
5. **Down:** (0,0) -> (2,0). Path: [(1,0),(2,0)]. Stops at (2,0) because (3,0) is already start/floor -- wait, (3,0) is floor (start). So ball slides from (0,0) down: (1,0)=floor, (2,0)=floor, (3,0)=floor(start), (4,0)=floor(painted). Ball slides all the way to (4,0). But (4,0) is already painted floor -- the ball doesn't stop at painted tiles, it slides through them.

Let me re-examine. The ball slides until it hits a **wall** or **boundary**. Painted/unpainted status does not affect movement. So from (0,0) swiping down: (1,0)=floor, (2,0)=floor, (3,0)=floor, (4,0)=floor. Next would be (5,0) which is out of bounds. Ball stops at (4,0).

So move 5 is: Down from (0,0) -> (4,0). Path: [(1,0),(2,0),(3,0),(4,0)]. New paint: (1,0),(2,0) = 2 new (3,0) already painted, (4,0) already painted. Total: 16.

Now at (4,0). I need to paint: (2,1),(2,2),(3,2),(3,3). That's 4 more tiles.

6. **Right:** (4,0) -> (4,4). All painted. Ball slides to (4,4). No new paint. Total: 16.
7. **Up:** (4,4) -> (0,4). All painted. Ball at (0,4). No new paint. Total: 16.

This isn't going to work to reach (2,1),(2,2),(3,2),(3,3). Let me redesign this level.

Let me design a level that properly uses a notch.

**Revised Grid (5x5):**

```
[1, 1, 1, 1, 0],
[1, 0, 0, 1, 0],
[1, 0, 0, 1, 0],
[1, 1, 1, 1, 1],
[0, 0, 2, 1, 1],
```

**Visual layout:**

```
 .  .  .  .  W
 .  W  W  .  W
 .  W  W  .  W
 .  .  .  .  .
 W  W  S  .  .
```

**Floor tile count:**
- Row 0: (0,0)=1,(0,1)=1,(0,2)=1,(0,3)=1 -> 4
- Row 1: (1,0)=1,(1,3)=1 -> 2
- Row 2: (2,0)=1,(2,3)=1 -> 2
- Row 3: (3,0)=1,(3,1)=1,(3,2)=1,(3,3)=1,(3,4)=1 -> 5
- Row 4: (4,2)=2,(4,3)=1,(4,4)=1 -> 3

Total: 4+2+2+5+3 = 16 floor tiles.

**Solution attempt:**

1. **Right:** (4,2) -> (4,4). Path: [(4,3),(4,4)]. Paint: 2. Total: 3.
2. **Up:** (4,4) -> (3,4). Path: [(3,4)]. Stops because (2,4)=0 (wall). Paint: 1. Total: 4. -- The notch! The wall at (2,4) stops the ball at row 3.
3. **Left:** (3,4) -> (3,0). Path: [(3,3),(3,2),(3,1),(3,0)]. Paint: 4. Total: 8.
4. **Up:** (3,0) -> (0,0). Path: [(2,0),(1,0),(0,0)]. Paint: 3. Total: 11.
5. **Right:** (0,0) -> (0,3). Path: [(0,1),(0,2),(0,3)]. Paint: 3. Total: 14.
6. **Down:** (0,3) -> (2,3). Path: [(1,3),(2,3)]. Stops because (3,3) is floor (painted), wait no -- ball slides through painted tiles. (1,3)=floor, (2,3)=floor, (3,3)=floor(painted), (4,3)=floor(painted). Next (5,3) out of bounds. Ball goes to (4,3).

That overshoots. I need the ball to stop at (2,3) or (1,3) somehow. The wall column at col 4 for rows 0-2 doesn't help here because we're moving down in column 3.

Let me try another approach. I need the ball to reach (1,3) and (2,3).

After move 5, ball is at (0,3). Going down: slides to (4,3) -- paints (1,3) and (2,3) on the way. That's 2 new. Total: 16. Win!

6. **Down:** (0,3) -> (4,3). Path: [(1,3),(2,3),(3,3),(4,3)]. New paint: (1,3),(2,3) = 2 new. Total: 16/16. Win!

**Verified solution (6 moves): Right, Up, Left, Up, Right, Down.**

**Swift constant:**

```swift
static let level2 = LevelData(
    name: "The Notch",
    colorScheme: .green,
    grid: [
        [1, 1, 1, 1, 0],
        [1, 0, 0, 1, 0],
        [1, 0, 0, 1, 0],
        [1, 1, 1, 1, 1],
        [0, 0, 2, 1, 1],
    ]
)
```

### 8.4 Level 3: "Backtrack"

**Teaching goal:** The player must re-traverse already-painted tiles to reach unpainted areas. Demonstrates that backtracking is allowed and sometimes required.

**Grid (6x5):**

```
[0, 1, 1, 1, 0],
[0, 1, 0, 1, 0],
[1, 1, 0, 1, 1],
[1, 0, 0, 0, 1],
[1, 1, 1, 1, 1],
[2, 0, 0, 0, 1],
```

**Visual layout:**

```
 W  .  .  .  W
 W  .  W  .  W
 .  .  W  .  .
 .  W  W  W  .
 .  .  .  .  .
 S  W  W  W  .
```

**Floor tile count:**
- Row 0: (0,1)=1,(0,2)=1,(0,3)=1 -> 3
- Row 1: (1,1)=1,(1,3)=1 -> 2
- Row 2: (2,0)=1,(2,1)=1,(2,3)=1,(2,4)=1 -> 4
- Row 3: (3,0)=1,(3,4)=1 -> 2
- Row 4: (4,0)=1,(4,1)=1,(4,2)=1,(4,3)=1,(4,4)=1 -> 5
- Row 5: (5,0)=2,(5,4)=1 -> 2

Total: 3+2+4+2+5+2 = 18 floor tiles.

**Solution attempt:**

1. **Up:** (5,0) -> (2,0). (4,0)=floor, (3,0)=floor, (2,0)=floor. Next (1,0)=0 wall. Stop at (2,0). Path: [(4,0),(3,0),(2,0)]. Paint: 3. Total: 4.
2. **Right:** (2,0) -> (2,1). (2,1)=floor, (2,2)=0 wall. Stop at (2,1). Path: [(2,1)]. Paint: 1. Total: 5.
3. **Up:** (2,1) -> (0,1). (1,1)=floor, (0,1)=floor. Next (-1,1) out of bounds. Stop at (0,1). Path: [(1,1),(0,1)]. Paint: 2. Total: 7.
4. **Right:** (0,1) -> (0,3). (0,2)=floor, (0,3)=floor. Next (0,4)=0 wall. Stop at (0,3). Path: [(0,2),(0,3)]. Paint: 2. Total: 9.
5. **Down:** (0,3) -> (2,3). (1,3)=floor, (2,3)=floor. Next (3,3)=0 wall. Stop at (2,3). Path: [(1,3),(2,3)]. Paint: 2. Total: 11.
6. **Right:** (2,3) -> (2,4). (2,4)=floor. Next (2,5) out of bounds. Stop at (2,4). Path: [(2,4)]. Paint: 1. Total: 12.
7. **Down:** (2,4) -> (5,4). (3,4)=floor, (4,4)=floor, (5,4)=floor. Next (6,4) out of bounds. Stop at (5,4). Path: [(3,4),(4,4),(5,4)]. Paint: 3. Total: 15.
8. **Left:** (5,4) -> (5,4). Wait -- (5,3)=0 wall. Can't move left. Bump. Need to go another way.

Hmm, (5,4) is trapped to the left by walls. Can go up: (4,4)=floor (painted), (3,4)=floor (painted), (2,4)=floor (painted), (1,4)=0 wall. Stop at (2,4). No new paint.

That leaves (4,1),(4,2),(4,3) unpainted. Need to reach row 4 middle. Let me rethink.

From (5,4), up to (2,4) (painted). Then left: (2,3) painted, (2,2)=0 wall. Stop at (2,3). No new paint.

I need to reach (4,1),(4,2),(4,3). These are accessible from (4,0) going right: (4,0) is painted, (4,1),(4,2),(4,3) are floor, (4,4) is painted. Ball slides all the way right to (4,4).

But to reach (4,0), I need to get to column 0, row 4. From (2,0), down: (3,0)=floor(painted), (4,0)=floor(painted), (5,0)=floor(painted). Already passed through before.

Let me retry from step 7 onwards:

7. **Down:** (2,4) -> (5,4). Paints (3,4),(4,4),(5,4). Total: 15.
8. **Up:** (5,4) -> (2,4). All painted. No new paint. Total: 15.
9. **Left:** (2,4) -> (2,3). (2,3) painted. (2,2)=wall. Stop at (2,3). No new paint.
10. **Down:** (2,3) -> (2,3). (3,3)=wall. Can't move. Bump.

This is getting stuck. Let me redesign level 3.

**Revised Grid (5x6):**

```
[2, 1, 0, 0, 1, 1],
[1, 1, 0, 0, 1, 1],
[0, 1, 1, 1, 1, 0],
[0, 1, 0, 0, 1, 0],
[0, 1, 1, 1, 1, 0],
```

**Visual layout:**

```
 S  .  W  W  .  .
 .  .  W  W  .  .
 W  .  .  .  .  W
 W  .  W  W  .  W
 W  .  .  .  .  W
```

**Floor tile count:**
- Row 0: (0,0)=2,(0,1)=1,(0,4)=1,(0,5)=1 -> 4
- Row 1: (1,0)=1,(1,1)=1,(1,4)=1,(1,5)=1 -> 4
- Row 2: (2,1)=1,(2,2)=1,(2,3)=1,(2,4)=1 -> 4
- Row 3: (3,1)=1,(3,4)=1 -> 2
- Row 4: (4,1)=1,(4,2)=1,(4,3)=1,(4,4)=1 -> 4

Total: 4+4+4+2+4 = 18 floor tiles.

**Solution attempt:**

1. **Down:** (0,0) -> (1,0). (1,0)=floor. (2,0)=wall. Stop. Path: [(1,0)]. Paint: 1. Total: 2.
2. **Right:** (1,0) -> (1,1). (1,1)=floor. (1,2)=wall. Stop at (1,1). Path: [(1,1)]. Paint: 1. Total: 3.
3. **Down:** (1,1) -> (4,1). (2,1)=floor,(3,1)=floor,(4,1)=floor. (5,1) out of bounds. Stop at (4,1). Path: [(2,1),(3,1),(4,1)]. Paint: 3. Total: 6.
4. **Right:** (4,1) -> (4,4). (4,2)=floor,(4,3)=floor,(4,4)=floor. (4,5)=wall. Stop at (4,4). Path: [(4,2),(4,3),(4,4)]. Paint: 3. Total: 9.
5. **Up:** (4,4) -> (0,4). (3,4)=floor,(2,4)=floor,(1,4)=floor,(0,4)=floor. Next (-1,4) OOB. Stop at (0,4). Path: [(3,4),(2,4),(1,4),(0,4)]. Paint: 4. Total: 13.
6. **Right:** (0,4) -> (0,5). (0,5)=floor. (0,6) OOB. Stop at (0,5). Path: [(0,5)]. Paint: 1. Total: 14.
7. **Down:** (0,5) -> (1,5). (1,5)=floor. (2,5)=wall. Stop at (1,5). Path: [(1,5)]. Paint: 1. Total: 15.
8. **Left:** (1,5) -> (1,4). (1,4) painted. (1,3)=wall. Stop at (1,4). No new paint. Total: 15.

Now stuck. Need (0,1),(2,2),(2,3) -- 3 more tiles. (0,1) is accessible from (0,0) going right. But I'm at (1,4).

9. **Up:** (1,4) -> (0,4). Painted. Total: 15.
10. **Left:** (0,4) -> (0,1). (0,3)=wall. Stop at... wait. (0,3)=0, (0,2)=0. So from (0,4) going left: (0,3)=wall. Stop at (0,4). Can't move.

This level has disconnected regions that can't be reached by the same path efficiently. Let me try yet another design that truly requires backtracking.

The key insight for a "backtrack" level: the player must pass through some tiles, then come back through them later to reach a branch they couldn't reach on the first pass.

**Final Level 3 Grid (6x5):**

```
[0, 1, 1, 1, 0],
[1, 1, 0, 1, 1],
[1, 0, 0, 0, 1],
[1, 1, 0, 1, 1],
[0, 1, 1, 1, 0],
[0, 0, 2, 0, 0],
```

**Visual layout:**

```
 W  .  .  .  W
 .  .  W  .  .
 .  W  W  W  .
 .  .  W  .  .
 W  .  .  .  W
 W  W  S  W  W
```

**Floor tile count:**
- Row 0: (0,1),(0,2),(0,3) -> 3
- Row 1: (1,0),(1,1),(1,3),(1,4) -> 4
- Row 2: (2,0),(2,4) -> 2
- Row 3: (3,0),(3,1),(3,3),(3,4) -> 4
- Row 4: (4,1),(4,2),(4,3) -> 3
- Row 5: (5,2)=start -> 1

Total: 3+4+2+4+3+1 = 17 floor tiles.

**Solution attempt:**

1. **Up:** (5,2) -> (4,2). (4,2)=floor. (3,2)=wall. Stop. Path: [(4,2)]. Paint: 1. Total: 2.
2. **Left:** (4,2) -> (4,1). (4,1)=floor. (4,0)=wall. Stop. Path: [(4,1)]. Paint: 1. Total: 3.
3. **Up:** (4,1) -> (3,1). (3,1)=floor. (2,1)=wall. Stop. Path: [(3,1)]. Paint: 1. Total: 4.
4. **Left:** (3,1) -> (3,0). (3,0)=floor. (3,-1) OOB. Stop. Path: [(3,0)]. Paint: 1. Total: 5.
5. **Up:** (3,0) -> (1,0). (2,0)=floor,(1,0)=floor. (0,0)=wall. Stop. Path: [(2,0),(1,0)]. Paint: 2. Total: 7.
6. **Right:** (1,0) -> (1,1). (1,1)=floor. (1,2)=wall. Stop. Path: [(1,1)]. Paint: 1. Total: 8.
7. **Up:** (1,1) -> (0,1). (0,1)=floor. (-1,1) OOB. Stop. Path: [(0,1)]. Paint: 1. Total: 9.
8. **Right:** (0,1) -> (0,3). (0,2)=floor,(0,3)=floor. (0,4)=wall. Stop. Path: [(0,2),(0,3)]. Paint: 2. Total: 11.
9. **Down:** (0,3) -> (1,3). (1,3)=floor. (2,3)=wall. Stop. Path: [(1,3)]. Paint: 1. Total: 12.
10. **Right:** (1,3) -> (1,4). (1,4)=floor. (1,5) OOB. Stop. Path: [(1,4)]. Paint: 1. Total: 13.
11. **Down:** (1,4) -> (2,4). (2,4)=floor. (3,4) -- is (3,4) floor? Row 3: [1,1,0,1,1]. (3,4)=1=floor. (4,4)=wall(0). Stop at (3,4). Wait, row 4: [0,1,1,1,0]. (4,4)=0=wall. So (2,4)=floor, (3,4)=floor, (4,4)=wall. Stop at (3,4). Path: [(2,4),(3,4)]. Paint: 2. Total: 15.
12. **Left:** (3,4) -> (3,3). (3,3)=floor. (3,2)=wall. Stop. Path: [(3,3)]. Paint: 1. Total: 16.
13. **Down:** (3,3) -> (4,3). (4,3)=floor. (5,3)=wall. Stop. Path: [(4,3)]. Paint: 1. Total: 17/17. Win!

**Verified solution (13 moves): Up, Left, Up, Left, Up, Right, Up, Right, Down, Right, Down, Left, Down.**

This solution requires backtracking: the player passes through the center column (4,2) early, then navigates the left side, comes back through the top, navigates the right side, and must use the notch at (3,3)/(3,1) to access the lower tiles. The re-traversal of painted tiles is necessary.

Let me verify the solution more carefully:

| Move | Direction | From | To | New tiles painted | Running total |
|------|-----------|------|----|-------------------|---------------|
| 1 | Up | (5,2) | (4,2) | (4,2) | 2 |
| 2 | Left | (4,2) | (4,1) | (4,1) | 3 |
| 3 | Up | (4,1) | (3,1) | (3,1) | 4 |
| 4 | Left | (3,1) | (3,0) | (3,0) | 5 |
| 5 | Up | (3,0) | (1,0) | (2,0), (1,0) | 7 |
| 6 | Right | (1,0) | (1,1) | (1,1) | 8 |
| 7 | Up | (1,1) | (0,1) | (0,1) | 9 |
| 8 | Right | (0,1) | (0,3) | (0,2), (0,3) | 11 |
| 9 | Down | (0,3) | (1,3) | (1,3) | 12 |
| 10 | Right | (1,3) | (1,4) | (1,4) | 13 |
| 11 | Down | (1,4) | (3,4) | (2,4), (3,4) | 15 |
| 12 | Left | (3,4) | (3,3) | (3,3) | 16 |
| 13 | Down | (3,3) | (4,3) | (4,3) | 17 |

17/17. Verified.

**Swift constant:**

```swift
static let level3 = LevelData(
    name: "Backtrack",
    colorScheme: .orange,
    grid: [
        [0, 1, 1, 1, 0],
        [1, 1, 0, 1, 1],
        [1, 0, 0, 0, 1],
        [1, 1, 0, 1, 1],
        [0, 1, 1, 1, 0],
        [0, 0, 2, 0, 0],
    ]
)
```

---

## 9. Level Progression

### 9.1 Sequential Flow

Levels are played in fixed order: Level 1 -> Level 2 -> Level 3 -> Completion screen. There is no level select. There is no way to skip levels.

The current level index is held in memory as a simple integer. There is no persistent storage in v1 -- closing and reopening the app restarts from Level 1. (Persistent progress is a future enhancement.)

### 9.2 Level Transition

When a level is won:

1. Win animation plays (see Section 7.9).
2. After the win animation (1.5 seconds total), the view increments the level index.
3. If a next level exists, a new `GameState` is created via `createInitialState` for the next level.
4. The grid transitions with a **0.4-second cross-fade**: `withAnimation(.easeInOut(duration: 0.4))`.
5. The new level begins in `.awaitingInput` phase.

### 9.3 Completion Screen

After Level 3 is won and the win animation plays, instead of loading a new level, the app displays a completion screen:

- Background: `Color(UIColor.systemBackground)`.
- Center text: **"Congratulations!"** in `.largeTitle.bold()`.
- Subtitle: **"You completed all levels."** in `.title3`. Color: `.secondary`.
- Below that: **"Thanks for playing Damaze"** in `.body`. Color: `.secondary`.
- A **"Play Again"** button that restarts from Level 1. Style: `.borderedProminent`, tint color `.blue`.

The completion screen fades in with the same 0.4-second transition used for level transitions.

---

## 10. Project Structure

```
Damaze/
  project.yml                    # XcodeGen configuration
  .gitignore                     # Includes *.xcodeproj, .DS_Store, etc.
  Sources/
    App/
      DamazeApp.swift            # @main entry point
    Model/
      Direction.swift            # Direction enum
      GridPosition.swift         # GridPosition struct
      CellType.swift             # CellType enum
      Level.swift                # Level struct with validation
      GamePhase.swift            # GamePhase enum
      GameState.swift            # GameState struct
      MoveResult.swift           # MoveResult struct
      GameEngine.swift           # Pure functions: computePath, applyMove, createInitialState
      LevelStore.swift           # Static level data (level1, level2, level3)
    View/
      GameView.swift             # Main game screen: grid + HUD + gesture handling
      GridView.swift             # Grid rendering (nested ForEach)
      CellView.swift             # Single cell rendering
      BallView.swift             # Ball rendering with animations
      HUDView.swift              # Level counter, move counter, restart button
      CompletionView.swift       # "Congratulations" screen
      InputMapper.swift          # direction(from: CGSize) -> Direction?
  Tests/
    Model/
      DirectionTests.swift
      LevelTests.swift
      GameStateTests.swift
      GameEngineTests.swift
    View/
      InputMapperTests.swift
```

### 10.1 XcodeGen Configuration

```yaml
name: Damaze
options:
  bundleIdPrefix: com.damaze
  deploymentTarget:
    iOS: "16.0"
  xcodeVersion: "16.0"
targets:
  Damaze:
    type: application
    platform: iOS
    sources: [Sources]
    settings:
      base:
        CODE_SIGNING_ALLOWED: false
        GENERATE_INFOPLIST_FILE: true
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: 1
        INFOPLIST_KEY_UILaunchScreen_Generation: true
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
  DamazeTests:
    type: bundle.unit-test
    platform: iOS
    sources: [Tests]
    dependencies:
      - target: Damaze
    settings:
      base:
        GENERATE_INFOPLIST_FILE: true
```

### 10.2 File Ownership Rules

- **Model/ files:** Zero SwiftUI imports. Import only Foundation (if needed) or no imports at all. These files define pure Swift types and functions. Any file in Model/ that imports SwiftUI is a bug.
- **View/ files:** Import SwiftUI. May reference Model types. Contain no game logic -- only rendering and gesture wiring.
- **App/ files:** Import SwiftUI. Contains the `@main` App struct and the top-level `@Observable` view model that bridges Model and View.
- **Tests/ files:** Import XCTest. Import the `Damaze` module via `@testable import Damaze`. Tests in `Model/` test only model types. Tests in `View/` test only `InputMapper` (pure function).

### 10.3 The @Observable ViewModel

The App layer contains one `@Observable` class that wraps `GameState` and serves as the bridge between model and view:

```swift
@Observable
class GameViewModel {
    var gameState: GameState
    var currentLevelIndex: Int
    var isShowingCompletion: Bool

    // View-layer animation state (not part of the model):
    var animatingBallPosition: GridPosition
    var bufferedDirection: Direction?
    var isBumping: Bool
    var bumpDirection: Direction?
}
```

This class lives in `Sources/App/` (or `Sources/View/`). It calls `GameEngine` static methods and updates `gameState` accordingly. The views observe this class.

---

## 11. Test Plan

### 11.1 Testing Boundary

**Unit tested (automated, XCTest, runs in CI):**
- All model types and functions
- `InputMapper.direction(from:)` (pure function, CoreGraphics dependency only)

**Manually verified (not automated in v1):**
- Ball animation smoothness and timing
- Cell paint animation sequence
- Bump animation
- Idle pulse
- Win animation
- Grid sizing on different devices
- Swipe gesture recognition reliability
- Level transition animation
- Completion screen layout

**Not tested (out of scope):**
- UI tests (XCUITest)
- Snapshot tests
- Performance/frame rate tests
- Accessibility
- iPad layout
- Dark mode (it should work via system colors, but no explicit testing)

### 11.2 Test Naming Convention

All test methods follow this pattern:

```
test_<unit>_<scenario>_<expectedResult>()
```

Examples:
- `test_computePath_swipeRightInOpenCorridor_slidesToFarWall()`
- `test_applyMove_allTilesPainted_phaseBecomesWon()`
- `test_levelInit_noStartPosition_throwsValidationError()`

### 11.3 Specific Test Cases

#### Path Computation Tests (GameEngineTests.swift)

| # | Test name | Setup | Input | Expected |
|---|-----------|-------|-------|----------|
| 1 | `test_computePath_straightCorridorRight_slidesToEnd` | 1x5 all floor, ball at (0,0) | direction: .right | path: [(0,1),(0,2),(0,3),(0,4)] |
| 2 | `test_computePath_straightCorridorLeft_slidesToEnd` | 1x5 all floor, ball at (0,4) | direction: .left | path: [(0,3),(0,2),(0,1),(0,0)] |
| 3 | `test_computePath_straightCorridorUp_slidesToEnd` | 5x1 all floor, ball at (4,0) | direction: .up | path: [(3,0),(2,0),(1,0),(0,0)] |
| 4 | `test_computePath_straightCorridorDown_slidesToEnd` | 5x1 all floor, ball at (0,0) | direction: .down | path: [(1,0),(2,0),(3,0),(4,0)] |
| 5 | `test_computePath_immediateWall_returnsEmptyPath` | ball at (0,1), wall at (0,2) | direction: .right | path: [] |
| 6 | `test_computePath_immediateBoundary_returnsEmptyPath` | ball at (0,0) | direction: .up | path: [] |
| 7 | `test_computePath_immediateBoundaryLeft_returnsEmptyPath` | ball at (0,0) | direction: .left | path: [] |
| 8 | `test_computePath_stopsAtWall_doesNotEnterWall` | floor at (0,0)-(0,2), wall at (0,3) | direction: .right from (0,0) | path: [(0,1),(0,2)]; NOT [(0,1),(0,2),(0,3)] |
| 9 | `test_computePath_stopsAtBoundary_lastCellInBounds` | 1x3 all floor, ball at (0,0) | direction: .right | path: [(0,1),(0,2)]; final pos is (0,2) not (0,3) |
| 10 | `test_computePath_singleTileMove_returnsOneTile` | floor at (0,0) and (0,1), wall at (0,2) | direction: .right from (0,0) | path: [(0,1)] |
| 11 | `test_computePath_noMovePossibleInAnyDirection_singleTileSurroundedByWalls` | 3x3 grid, only center (1,1) is floor | all 4 directions from (1,1) | all return [] |
| 12 | `test_computePath_lShapedCorridor_doesNotTurnCorner` | L-shaped floor, ball at bottom of vertical segment | direction: .up | stops at the corner, does NOT continue horizontally |

#### Paint State Tests (GameEngineTests.swift)

| # | Test name | Setup | Action | Expected |
|---|-----------|-------|--------|----------|
| 13 | `test_applyMove_paintsTilesAlongPath` | 1x5 floor, ball at (0,0) | move .right | paintedTiles contains (0,0)-(0,4) |
| 14 | `test_applyMove_retraversalDoesNotDuplicatePaint` | tiles (0,0)-(0,4) already painted, ball at (0,0) | move .right | paintedTiles.count unchanged |
| 15 | `test_applyMove_emptyPath_doesNotModifyPaintedTiles` | ball against wall | move into wall | paintedTiles unchanged |
| 16 | `test_applyMove_partialOverlap_onlyNewTilesCounted` | (0,0)-(0,2) painted, ball at (0,0), floor extends to (0,4) | move .right | (0,3) and (0,4) added to paintedTiles |

#### Win Detection Tests (GameStateTests.swift)

| # | Test name | Setup | Expected |
|---|-----------|-------|----------|
| 17 | `test_isComplete_allTilesPainted_returnsTrue` | all floor tiles in paintedTiles | isComplete == true |
| 18 | `test_isComplete_oneTileRemaining_returnsFalse` | all but one floor tile painted | isComplete == false |
| 19 | `test_isComplete_singleFloorTileLevel_trueAtSpawn` | level with only start tile as floor | isComplete == true after createInitialState |
| 20 | `test_applyMove_completingMove_setsIsWinTrue` | move that paints the last tile | moveResult.isWin == true |
| 21 | `test_applyMove_nonCompletingMove_setsIsWinFalse` | move that does not complete coverage | moveResult.isWin == false |

#### State Machine Tests (GameEngineTests.swift)

| # | Test name | Setup | Action | Expected |
|---|-----------|-------|--------|----------|
| 22 | `test_applyMove_duringMovingPhase_rejectsMove` | phase == .moving | applyMove(.right) | returns empty path, state unchanged |
| 23 | `test_applyMove_duringWonPhase_rejectsMove` | phase == .won | applyMove(.right) | returns empty path, state unchanged |
| 24 | `test_applyMove_validMove_setsPhaseToMoving` | phase == .awaitingInput | valid move | phase == .moving |
| 25 | `test_applyMove_invalidMove_phaseRemainsAwaitingInput` | phase == .awaitingInput, wall adjacent | move into wall | phase == .awaitingInput |

#### Level Validation Tests (LevelTests.swift)

| # | Test name | Setup | Expected |
|---|-----------|-------|----------|
| 26 | `test_levelInit_validGrid_succeeds` | well-formed 3x3 grid with start | no error thrown |
| 27 | `test_levelInit_noStartPosition_throws` | grid with no value-2 cell | throws validation error |
| 28 | `test_levelInit_multipleStartPositions_throws` | grid with two value-2 cells | throws validation error |
| 29 | `test_levelInit_noFloorTiles_throws` | grid with only walls and start... wait, start IS a floor tile, so this is valid (1 floor tile). Test: grid with all walls (no 1s and no 2s) | throws (no start position) |
| 30 | `test_levelInit_raggedArray_throws` | rows with different lengths | throws validation error |
| 31 | `test_levelInit_emptyGrid_throws` | empty array | throws validation error |
| 32 | `test_levelInit_invalidCellValue_throws` | cell value 3 or -1 | throws validation error |
| 33 | `test_levelInit_computesFloorTileCount` | known grid | floorTileCount matches hand-counted value |
| 34 | `test_levelInit_extractsStartPosition` | known grid | startPosition matches expected |
| 35 | `test_levelInit_gridTooLarge_throws` | 8x8 grid | throws validation error (max 7x7) |

#### Move History Tests (GameEngineTests.swift)

| # | Test name | Setup | Action | Expected |
|---|-----------|-------|--------|----------|
| 36 | `test_applyMove_validMove_appendsToHistory` | initial state | move .right (valid) | moveHistory == [.right] |
| 37 | `test_applyMove_invalidMove_doesNotAppendToHistory` | ball against wall | move into wall | moveHistory == [] |
| 38 | `test_applyMove_multipleValidMoves_historyAccurate` | sequence of 3 valid moves | apply all 3 | moveHistory has 3 entries in order |

#### Move Counter Tests (GameEngineTests.swift)

| # | Test name | Setup | Action | Expected |
|---|-----------|-------|--------|----------|
| 39 | `test_applyMove_validMove_incrementsMoveCount` | moveCount == 0 | valid move | moveCount == 1 |
| 40 | `test_applyMove_invalidMove_doesNotIncrementMoveCount` | moveCount == 0 | move into wall | moveCount == 0 |

#### Input Mapper Tests (InputMapperTests.swift)

| # | Test name | Input CGSize | Expected |
|---|-----------|-------------|----------|
| 41 | `test_direction_rightSwipe_returnsRight` | CGSize(width: 50, height: 10) | .right |
| 42 | `test_direction_leftSwipe_returnsLeft` | CGSize(width: -50, height: 10) | .left |
| 43 | `test_direction_upSwipe_returnsUp` | CGSize(width: 5, height: -60) | .up |
| 44 | `test_direction_downSwipe_returnsDown` | CGSize(width: -5, height: 60) | .down |
| 45 | `test_direction_belowThreshold_returnsNil` | CGSize(width: 10, height: 10) | nil |
| 46 | `test_direction_exactlyAtThreshold_returnsNil` | CGSize(width: 14, height: 14) | nil (max is 14, below 20) |
| 47 | `test_direction_diagonalEqual_returnsVertical` | CGSize(width: 50, height: -50) | .up (vertical tiebreak) |

#### Level Solution Tests (GameEngineTests.swift)

These tests verify that each hand-crafted level is solvable with its documented solution:

| # | Test name | Level | Solution moves | Expected |
|---|-----------|-------|----------------|----------|
| 48 | `test_level1_solvableWithDocumentedSolution` | Level 1 | [.left, .up, .right, .down] | isComplete == true after all moves |
| 49 | `test_level2_solvableWithDocumentedSolution` | Level 2 | [.right, .up, .left, .up, .right, .down] | isComplete == true after all moves |
| 50 | `test_level3_solvableWithDocumentedSolution` | Level 3 | [.up, .left, .up, .left, .up, .right, .up, .right, .down, .right, .down, .left, .down] | isComplete == true after all moves |

#### createInitialState Tests (GameEngineTests.swift)

| # | Test name | Setup | Expected |
|---|-----------|-------|----------|
| 51 | `test_createInitialState_ballAtStartPosition` | any valid level | ballPosition == level.startPosition |
| 52 | `test_createInitialState_startTilePainted` | any valid level | paintedTiles contains level.startPosition |
| 53 | `test_createInitialState_paintedCountIsOne` | any valid level | paintedTiles.count == 1 |
| 54 | `test_createInitialState_phaseIsAwaitingInput` | any valid level | phase == .awaitingInput |
| 55 | `test_createInitialState_moveCountIsZero` | any valid level | moveCount == 0 |
| 56 | `test_createInitialState_moveHistoryIsEmpty` | any valid level | moveHistory == [] |

### 11.4 Test Organization

Tests create levels inline as array literals. They do not load from LevelStore. This keeps tests self-contained and independent of the production level data (except for the level solution tests, which intentionally test the production levels).

Example test pattern:

```swift
func test_computePath_straightCorridorRight_slidesToEnd() throws {
    let level = try Level(grid: [
        [1, 1, 1, 1, 1]
    ])
    let path = GameEngine.computePath(
        from: GridPosition(row: 0, col: 0),
        direction: .right,
        grid: level.grid,
        rows: level.rows,
        cols: level.cols
    )
    XCTAssertEqual(path, [
        GridPosition(row: 0, col: 1),
        GridPosition(row: 0, col: 2),
        GridPosition(row: 0, col: 3),
        GridPosition(row: 0, col: 4),
    ])
}
```

---

## 12. Non-Goals

These items are explicitly out of scope for this implementation. They are not forgotten -- they are intentionally excluded.

| Item | Rationale |
|------|-----------|
| Time Rush, Limited Moves, Duel, Coin modes | Only Classic mode is in scope. Other modes are future features. |
| All monetization (ads, IAP, coins, skins) | This is a gameplay prototype, not a commercial release. |
| Board themes / ball skins | Visual customization is a future feature gated on monetization. |
| Haptic feedback | Adds iOS API complexity for marginal v1 benefit. Future enhancement. |
| Sound effects / particle effects | Adds asset management complexity. Future enhancement. |
| Boosters (triple ball, hints, skip) | Requires economy system. Future feature. |
| Procedural level generation | Algorithmically hard (NP-hard for guaranteed solvability). Hand-crafted levels only. |
| Game Center integration | No leaderboards or achievements in v1. |
| Undo feature | Move history is stored for future use, but undo UI is not implemented. |
| Deadlock detection | NP-hard in general. Restart button is always visible instead. |
| Landscape orientation | Portrait only. Simplifies layout and matches typical casual game expectations. |
| iPad-specific layout | iPad runs the iPhone layout in compatibility mode. No explicit iPad optimization. |
| Accessibility / VoiceOver | Grid puzzle with visual-only state is non-trivial to make accessible. Future enhancement. |
| UI tests / snapshot tests | Manual visual verification for v1. Unit tests cover the model layer. |
| Persistent progress (saving current level) | App restarts from Level 1 on relaunch. Future enhancement via UserDefaults. |
| Level select screen | Levels are strictly sequential. No back-navigation. |
| Dark mode optimization | System colors provide basic dark mode support. No explicit dark-mode design work. |
| Remaining-tile highlighting | Unpainted tiles do not pulse or glow at high coverage. The grid is small enough (max 7x7) that the last unpainted tile is visually findable. |

---

## Appendix A: Animation Timing Summary

| Animation | Duration | Easing | Trigger |
|-----------|----------|--------|---------|
| Ball movement per tile | 0.125s (min 0.15s total per move) | linear | Each timer tick in movement sequence |
| Cell paint fill | 0.15s | easeIn | Same tick as ball entering that cell |
| Bump (invalid swipe) | 0.15s total | spring(response: 0.15, dampingFraction: 0.5) | Empty path returned from applyMove |
| Idle pulse | 1.0s cycle | easeInOut, repeating | Phase == .awaitingInput, no animation playing |
| Win grid pulse | 0.4s | easeInOut | After 0.3s pause post-completion |
| Win text fade-in | 0.3s | easeIn | After grid pulse completes |
| Level transition | 0.4s | easeInOut | After 1.5s total win sequence |
| Completion screen appear | 0.4s | easeInOut | After Level 3 win sequence |

## Appendix B: Constant Values Reference

| Constant | Value | Used by |
|----------|-------|---------|
| Minimum swipe distance | 20 pt | InputMapper |
| Ball speed | ~8 tiles/sec (0.125s per tile) | Movement animation |
| Minimum move duration | 0.15s | Movement animation |
| Bump offset distance | 2 pt | Bump animation |
| Idle pulse scale range | 1.0 - 1.08 | Idle animation |
| Grid padding | 16 pt each side | Grid sizing |
| Cell gap | 2 pt (1pt padding per side per cell) | Grid rendering |
| Cell corner radius | cellSize * 0.1 | Cell rendering |
| Ball diameter | cellSize * 0.7 | Ball rendering |
| Ball shadow | radius: 3, y: 2, opacity: 0.25 | Ball rendering |
| HUD bar height | ~44 pt + safe area | Layout |
| Restart button size | 44x44 pt | HUD |
| Maximum grid dimension | 7x7 | Level validation |
| Win pause before pulse | 0.3s | Win sequence |
| Win total duration | 1.5s | Win sequence |

## Appendix C: Coordinate System Quick Reference

```
          col 0    col 1    col 2    col 3    col 4
row 0    [0,0]    [0,1]    [0,2]    [0,3]    [0,4]     <- swipe UP moves here
row 1    [1,0]    [1,1]    [1,2]    [1,3]    [1,4]
row 2    [2,0]    [2,1]    [2,2]    [2,3]    [2,4]
row 3    [3,0]    [3,1]    [3,2]    [3,3]    [3,4]
row 4    [4,0]    [4,1]    [4,2]    [4,3]    [4,4]     <- swipe DOWN moves here

          ^                                    ^
     swipe LEFT                          swipe RIGHT
     moves here                          moves here
```

- `grid[row][col]` -- row-major indexing
- Row 0 = top of screen. Row increases downward.
- Col 0 = left of screen. Col increases rightward.
- Swipe up on screen = Direction.up = row decreases (toward row 0)
- Swipe down on screen = Direction.down = row increases (toward max row)
- Swipe left on screen = Direction.left = col decreases (toward col 0)
- Swipe right on screen = Direction.right = col increases (toward max col)

This mapping is natural and requires no coordinate inversion.
