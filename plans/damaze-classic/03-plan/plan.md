# Damaze Classic Mode -- Implementation Plan

**Version:** 1.0
**Date:** 2026-03-18
**Spec:** `plans/damaze-classic/02-spec/spec.md` (v1.0, locked)

---

## 1. Overview

This plan breaks the Damaze Classic mode implementation into 5 sequential phases. Each phase produces a compiling, testable project. Phases are designed so that a polecat can implement any single phase given only the spec, this plan, and the output of all prior phases.

The existing project scaffolding consists of:
- `project.yml` -- XcodeGen config with `Sources/` and `Tests/` source roots
- `Sources/DamazeApp.swift` -- Minimal `@main` App struct rendering `ContentView()`
- `Sources/Views/ContentView.swift` -- Placeholder "Damaze" text
- `Tests/DamazeTests.swift` -- Single placeholder test

Each phase restructures, extends, or replaces parts of this scaffolding as needed.

**Base paths** (all file paths in this plan are relative to the rig root):
- Rig root: `<rig>/` (the directory containing `project.yml`)
- Sources: `<rig>/Sources/`
- Tests: `<rig>/Tests/`

---

## 2. Phases

### Phase 1: Model Layer
**ID:** `phase-1`
**Complexity:** L
**Dependencies:** None

#### Description

Build the entire model layer as pure Swift with zero SwiftUI imports. This is the foundation for all subsequent phases. Includes all data types, the game engine (path computation, move application, win detection), level data, and comprehensive unit tests. Also restructures `project.yml` and the directory layout to match the spec's project structure.

#### Files to Create

| File | Purpose |
|------|---------|
| `Sources/Model/Direction.swift` | `Direction` enum (Spec 4.2) |
| `Sources/Model/GridPosition.swift` | `GridPosition` struct (Spec 4.1) |
| `Sources/Model/CellType.swift` | `CellType` enum (Spec 4.3) |
| `Sources/Model/Level.swift` | `Level` struct with validation (Spec 4.4) |
| `Sources/Model/GamePhase.swift` | `GamePhase` enum (Spec 3.3) |
| `Sources/Model/GameState.swift` | `GameState` struct with `isComplete` (Spec 4.5) |
| `Sources/Model/MoveResult.swift` | `MoveResult` struct (Spec 4.6) |
| `Sources/Model/GameEngine.swift` | Static functions: `computePath`, `applyMove`, `createInitialState` (Spec 5.1-5.4) |
| `Sources/Model/LevelStore.swift` | Static level data for all 3 levels (Spec 8.2-8.4) |
| `Tests/Model/DirectionTests.swift` | Direction delta tests |
| `Tests/Model/LevelTests.swift` | Level validation tests (Spec 11.3, tests #26-35) |
| `Tests/Model/GameStateTests.swift` | Win detection tests (Spec 11.3, tests #17-21) |
| `Tests/Model/GameEngineTests.swift` | Path computation, paint state, state machine, move history, move counter, level solution, createInitialState tests (Spec 11.3, tests #1-16, #22-25, #36-40, #48-56) |

#### Files to Modify

| File | Change |
|------|--------|
| `project.yml` | Update to match Spec 10.1: add `xcodeVersion`, update `bundleIdPrefix` to `com.damaze`, add `INFOPLIST_KEY_UILaunchScreen_Generation` and `INFOPLIST_KEY_UISupportedInterfaceOrientations` settings. Source roots remain `[Sources]` and `[Tests]` (XcodeGen recurses into subdirectories). |
| `Sources/DamazeApp.swift` | Move to `Sources/App/DamazeApp.swift`. Keep content unchanged for now (still renders `ContentView`). |
| `Sources/Views/ContentView.swift` | Move to `Sources/View/ContentView.swift`. Keep content unchanged for now. |
| `Tests/DamazeTests.swift` | Delete (replaced by the specific test files in `Tests/Model/`). |

#### Implementation Details

**Direction.swift** (Spec 4.2):
```swift
enum Direction: CaseIterable {
    case up, down, left, right

    var rowDelta: Int { ... }  // up: -1, down: +1, left: 0, right: 0
    var colDelta: Int { ... }  // up: 0, down: 0, left: -1, right: +1
}
```

**GridPosition.swift** (Spec 4.1):
```swift
struct GridPosition: Equatable, Hashable {
    let row: Int
    let col: Int
}
```

**CellType.swift** (Spec 4.3):
```swift
enum CellType: Int {
    case wall = 0
    case floor = 1
    case start = 2
}
```

**Level.swift** (Spec 4.4):
```swift
struct Level {
    let grid: [[CellType]]
    let rows: Int
    let cols: Int
    let startPosition: GridPosition
    let floorTileCount: Int

    init(grid: [[Int]]) throws
}
```
Validation in `init` (see Spec 4.4 for the 6 rules):
1. Non-empty grid (at least 1 row, 1 column)
2. Rectangular (all rows same length)
3. Exactly one cell with value 2
4. All cell values must be 0, 1, or 2
5. `floorTileCount` >= 1
6. Max dimension 7x7

Throw descriptive errors for each violation. Use a custom error enum (e.g., `LevelError`) with cases for each validation failure.

**GamePhase.swift** (Spec 3.3):
```swift
enum GamePhase {
    case awaitingInput
    case moving
    case won
}
```

**GameState.swift** (Spec 4.5):
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

**MoveResult.swift** (Spec 4.6):
```swift
struct MoveResult {
    let path: [GridPosition]
    let isWin: Bool
    let newBallPosition: GridPosition
}
```

**GameEngine.swift** (Spec 5.1-5.4):
```swift
enum GameEngine {
    static func computePath(
        from position: GridPosition,
        direction: Direction,
        grid: [[CellType]],
        rows: Int,
        cols: Int
    ) -> [GridPosition]

    static func applyMove(
        direction: Direction,
        state: inout GameState
    ) -> MoveResult

    static func createInitialState(for level: Level) -> GameState
}
```
- `computePath`: Step cell-by-cell in direction. Stop at wall or boundary. Return tiles traversed (excluding start). See Spec 5.1.
- `applyMove`: Check phase, compute path, update state, return result. See Spec 5.2 for exact behavior.
- `createInitialState`: Create fresh `GameState` with start tile painted. See Spec 5.4.

**LevelStore.swift** (Spec 8.1-8.4):
```swift
enum LevelStore {
    static let levels: [Level] = [ level1, level2, level3 ]

    static let level1: Level  // "First Steps" 4x4 (Spec 8.2)
    static let level2: Level  // "The Notch" 5x5 (Spec 8.3)
    static let level3: Level  // "Backtrack" 6x5 (Spec 8.4)
}
```
Use the exact grid arrays from Spec 8.2, 8.3, 8.4. The `Level` init can throw, so use `try!` for these known-good constants (or provide a non-throwing factory). Store level names and color scheme identifiers alongside the data. A `LevelData` helper struct or direct level construction is acceptable -- the key requirement is that `LevelStore.levels` provides an ordered array of valid `Level` instances.

Level color scheme identifiers (blue, green, orange) should be representable without importing SwiftUI. Options: a `ColorScheme` enum in the model, or store color info in a separate view-layer mapping. Recommended approach: add a `colorName` string property or a `LevelColorScheme` enum to the model (no SwiftUI import needed), and let the view layer map it to actual `Color` values. Alternatively, just store the level index and derive colors from it in the view.

**DirectionTests.swift**:
Test that each direction's `rowDelta` and `colDelta` return the correct values per the table in Spec 4.2.

**Test counts and IDs** (mapped to Spec 11.3):

- `GameEngineTests.swift`: Tests #1-16 (path computation), #22-25 (state machine), #36-40 (move history + move counter), #48-50 (level solutions), #51-56 (createInitialState)
- `GameStateTests.swift`: Tests #17-21 (win detection)
- `LevelTests.swift`: Tests #26-35 (level validation)
- `DirectionTests.swift`: Direction delta correctness (not numbered in spec, but required for confidence)

Use the exact test names from Spec 11.2 and 11.3. Follow the `test_<unit>_<scenario>_<expectedResult>()` naming convention.

For test grids: construct levels inline using `try Level(grid: ...)` with small purpose-built grids. Do not use `LevelStore` levels except for tests #48-50 (level solution verification). See Spec 11.4 for example pattern.

Note on test #1: the spec expects `Level(grid: [[1, 1, 1, 1, 1]])` (a 1x5 all-floor grid). This grid has no start position (no value-2 cell), so `Level.init` will throw. For path computation tests that need grids without a start position, either: (a) replace one cell with `2` and position the ball at a different cell, or (b) call `computePath` directly with a raw `[[CellType]]` grid, bypassing `Level.init`. The recommended approach is (a): include a start cell somewhere in the test grid, and ignore it for path computation purposes. Example: `[[2, 1, 1, 1, 1]]` with ball at `(0,0)` still tests the full corridor slide.

#### Acceptance Criteria

1. `xcodebuild build` succeeds with zero errors and zero warnings related to model files.
2. `xcodebuild test` runs and all tests pass (approximately 50+ tests).
3. No file under `Sources/Model/` imports SwiftUI or UIKit.
4. The app still launches and displays the placeholder ContentView (no visual regression).
5. All test names follow the `test_<unit>_<scenario>_<expectedResult>()` convention.
6. Level solution tests #48-50 verify the exact move sequences from the spec.
7. `project.yml` matches Spec 10.1 configuration.

---

### Phase 2: Input Handling & ViewModel
**ID:** `phase-2`
**Complexity:** S
**Dependencies:** Phase 1

#### Description

Create the `InputMapper` (pure function for swipe direction detection) and the `@Observable GameViewModel` that bridges the model layer to SwiftUI views. The ViewModel wraps `GameState`, manages level progression, and exposes animation-related state. This phase does not create any visible UI changes -- it prepares the wiring that Phase 3 will connect to views.

#### Files to Create

| File | Purpose |
|------|---------|
| `Sources/View/InputMapper.swift` | `direction(from: CGSize) -> Direction?` (Spec 6.1) |
| `Sources/App/GameViewModel.swift` | `@Observable` ViewModel bridging model to view (Spec 10.3) |
| `Tests/View/InputMapperTests.swift` | Input mapper tests (Spec 11.3, tests #41-47) |

#### Implementation Details

**InputMapper.swift** (Spec 6.1):
```swift
import CoreGraphics

enum InputMapper {
    static func direction(from translation: CGSize) -> Direction? {
        let dx = translation.width
        let dy = translation.height

        guard max(abs(dx), abs(dy)) >= 20 else {
            return nil
        }

        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        } else {
            return dy > 0 ? .down : .up
        }
    }
}
```
This lives in `Sources/View/` because it references `CGSize` from CoreGraphics. It is a pure function with no SwiftUI dependency.

**GameViewModel.swift** (Spec 10.3):
```swift
import SwiftUI

@Observable
class GameViewModel {
    // Core state
    var gameState: GameState
    var currentLevelIndex: Int
    var isShowingCompletion: Bool

    // Animation state (view-layer, not model)
    var animatingBallPosition: GridPosition
    var bufferedDirection: Direction?
    var isBumping: Bool
    var bumpDirection: Direction?

    // Computed properties
    var currentLevel: Level { gameState.level }
    var ballPosition: GridPosition { gameState.ballPosition }
    var paintedTiles: Set<GridPosition> { gameState.paintedTiles }
    var moveCount: Int { gameState.moveCount }
    var phase: GamePhase { gameState.phase }

    init() {
        let level = LevelStore.levels[0]
        let state = GameEngine.createInitialState(for: level)
        self.gameState = state
        self.currentLevelIndex = 0
        self.isShowingCompletion = false
        self.animatingBallPosition = state.ballPosition
        self.bufferedDirection = nil
        self.isBumping = false
        self.bumpDirection = nil
    }

    // Actions
    func handleSwipe(direction: Direction) { ... }
    func onAnimationComplete() { ... }
    func restart() { ... }
    func advanceLevel() { ... }
    func playAgain() { ... }
}
```

Key behaviors:
- `handleSwipe`: If phase is `.awaitingInput`, call `GameEngine.applyMove`. If phase is `.moving`, buffer the direction (Spec 6.3). If empty path, set `isBumping = true` and `bumpDirection`.
- `onAnimationComplete`: Transition from `.moving` to `.awaitingInput` or `.won`. Check buffered direction. See Spec 3.3 transitions.
- `restart`: Call `GameEngine.createInitialState` for current level. Clear buffer. See Spec 7.10 restart button behavior.
- `advanceLevel`: Increment `currentLevelIndex`. If next level exists, create new state. If last level, set `isShowingCompletion = true`. See Spec 9.2.
- `playAgain`: Reset to level 0, create initial state. See Spec 9.3.

The ViewModel does NOT drive animations directly -- it provides the data. Phase 4 will add the animation sequencing logic (timer-based cell-by-cell movement). For now, `handleSwipe` can update `animatingBallPosition` to the final position immediately.

**InputMapperTests.swift** (Spec 11.3, tests #41-47):
Implement all 7 tests from the spec table. Use the exact test names and input values specified.

#### Acceptance Criteria

1. `xcodebuild build` succeeds.
2. `xcodebuild test` passes -- all Phase 1 tests still pass, plus 7 new InputMapper tests.
3. `InputMapper.swift` imports only `CoreGraphics` (or `Foundation`) -- no SwiftUI.
4. `GameViewModel` compiles with `import SwiftUI` and `@Observable`.
5. `GameViewModel.init()` successfully creates an initial game state from LevelStore.
6. The app still launches (placeholder UI unchanged).

---

### Phase 3: Grid Rendering & Basic UI
**ID:** `phase-3`
**Complexity:** M
**Dependencies:** Phase 2

#### Description

Build the static visual layer: grid rendering, cell views, ball overlay, and HUD. The app will display Level 1 with the ball at its start position. No interaction yet -- no swipe handling, no animation. This phase proves the rendering pipeline works end-to-end.

#### Files to Create

| File | Purpose |
|------|---------|
| `Sources/View/GameView.swift` | Main game screen: grid + HUD + layout container (Spec 7.2, 7.10) |
| `Sources/View/GridView.swift` | Grid rendering with nested ForEach (Spec 7.2) |
| `Sources/View/CellView.swift` | Single cell rendering with visual states (Spec 7.3) |
| `Sources/View/BallView.swift` | Ball circle overlay (Spec 7.4) -- static position only, no animation yet |
| `Sources/View/HUDView.swift` | Level counter, move counter, restart button (Spec 7.10) |

#### Files to Modify

| File | Change |
|------|--------|
| `Sources/App/DamazeApp.swift` | Change root view from `ContentView()` to `GameView()`. Inject `GameViewModel` into the environment or pass as parameter. |
| `Sources/View/ContentView.swift` | Delete this file. It is replaced by `GameView`. |

#### Implementation Details

**Level color mapping** (Spec 7.3):
Create a helper (in `GameView.swift` or a small utility) that maps level index to colors:
```swift
// Level 1 (index 0): blue
// Level 2 (index 1): green
// Level 3 (index 2): orange
var paintColor: Color { ... }       // .blue.opacity(0.35), .green.opacity(0.35), .orange.opacity(0.35)
var ballColor: Color { ... }        // .blue, .green, .orange
var wallColor: Color { ... }        // Color(white: 0.17) for all levels
```

**GameView.swift** (Spec 7.2, 7.10, 7.11):
```swift
struct GameView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HUDView(...)
                Spacer()
                GridView(...)  // with BallView overlaid
                Spacer()
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}
```
- Use `GeometryReader` to compute cell size per Spec 7.2 formula.
- Grid centered horizontally and vertically.
- Swipe gesture attachment point is the grid area (Spec 7.10) -- add a clear overlay or `.contentShape(Rectangle())` to make the grid area tappable/swipeable. Gesture handling itself deferred to Phase 4.

**GridView.swift** (Spec 7.2):
```swift
struct GridView: View {
    let level: Level
    let paintedTiles: Set<GridPosition>
    let cellSize: CGFloat
    let paintColor: Color
    let wallColor: Color

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<level.rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<level.cols, id: \.self) { col in
                        CellView(...)
                    }
                }
            }
        }
    }
}
```

**CellView.swift** (Spec 7.3):
```swift
struct CellView: View {
    let cellType: CellType
    let isPainted: Bool
    let cellSize: CGFloat
    let paintColor: Color
    let wallColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: cellSize * 0.1)
            .fill(backgroundColor)
            .frame(width: cellSize - 2, height: cellSize - 2)  // 2pt gap via 1pt padding per side
            .padding(1)
    }
}
```
Background color logic:
- Wall: `wallColor` (`Color(white: 0.17)`)
- Unpainted floor/start: `Color(hex: "#F2F2F7")` (or `Color(UIColor.systemGray6)`)
- Painted floor/start: `paintColor`

**BallView.swift** (Spec 7.4):
```swift
struct BallView: View {
    let position: GridPosition
    let cellSize: CGFloat
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: cellSize * 0.7, height: cellSize * 0.7)
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
            .position(
                x: CGFloat(position.col) * cellSize + cellSize / 2,
                y: CGFloat(position.row) * cellSize + cellSize / 2
            )
    }
}
```
The ball is positioned as an overlay on the grid container using `.position()` for absolute placement within the grid's coordinate space.

**HUDView.swift** (Spec 7.10):
```swift
struct HUDView: View {
    let levelNumber: Int      // 1-based display number
    let moveCount: Int
    let onRestart: () -> Void

    var body: some View {
        HStack {
            Text("Level \(levelNumber)")
                .font(.headline)
            Spacer()
            Text("Moves: \(moveCount)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: onRestart) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}
```

**DamazeApp.swift update**:
```swift
@main
struct DamazeApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}
```

#### Acceptance Criteria

1. `xcodebuild build` succeeds.
2. `xcodebuild test` passes (all prior tests still pass).
3. App launches in simulator and displays:
   - Level 1 grid (4x4 with walls and floors correctly colored).
   - Ball visible at start position (3,3) as a blue circle.
   - HUD showing "Level 1", "Moves: 0", and a restart button.
4. Grid is centered on screen with correct padding.
5. Wall cells are dark (`Color(white: 0.17)`), unpainted floors are light, start tile is painted (blue tint).
6. The restart button calls `viewModel.restart()` (even though there is no interaction to reset yet, the wiring must be in place).
7. `ContentView.swift` is deleted. `DamazeApp.swift` lives at `Sources/App/DamazeApp.swift`.

---

### Phase 4: Interaction & Animation
**ID:** `phase-4`
**Complexity:** L
**Dependencies:** Phase 3

#### Description

Add swipe gesture handling, ball movement animation (cell-by-cell with chained timers), paint fill animation, bump animation, idle pulse, and input buffering. After this phase, the core gameplay loop is fully functional: swipe to move, watch the ball slide, see tiles paint, get feedback on invalid moves.

#### Files to Modify

| File | Change |
|------|--------|
| `Sources/View/GameView.swift` | Attach `DragGesture` to grid area. On gesture end, call `InputMapper.direction(from:)` then `viewModel.handleSwipe(direction:)`. |
| `Sources/View/BallView.swift` | Add idle pulse animation (Spec 7.8), bump animation (Spec 7.7), smooth position transitions. |
| `Sources/View/CellView.swift` | Add paint transition animation (Spec 7.6). |
| `Sources/App/GameViewModel.swift` | Add cell-by-cell animation sequencing logic (Spec 7.5). Manage `animatingBallPosition`, `visuallyPaintedTiles`, animation timers. |

#### Implementation Details

**Swipe gesture on GameView** (Spec 6.1, 6.2):
```swift
.gesture(
    DragGesture(minimumDistance: 20)
        .onEnded { value in
            if let direction = InputMapper.direction(from: value.translation) {
                viewModel.handleSwipe(direction: direction)
            }
        }
)
```
Attach to the grid overlay area, not the full screen (Spec 7.10).

**GameViewModel animation sequencing** (Spec 7.5):

The ViewModel needs additional state for driving the view-side animation:

```swift
// Additional state in GameViewModel:
var visuallyPaintedTiles: Set<GridPosition>  // Tiles that the VIEW has painted (lags behind model)
var isAnimating: Bool                         // True while cell-by-cell timer is running
```

When `handleSwipe` gets a non-empty `MoveResult`:
1. Store the `path` and `isWin` flag.
2. Set `isAnimating = true`.
3. Start a cell-by-cell timer sequence:
   - Timer interval: `0.125` seconds per tile (Spec 7.5).
   - Total duration: `max(0.15, path.count * 0.125)` seconds.
   - On each tick: update `animatingBallPosition` to `path[step]`, add `path[step]` to `visuallyPaintedTiles`.
   - Use `withAnimation(.linear(duration: 0.125))` for position update (Spec 7.5 easing).
   - Use `withAnimation(.easeIn(duration: 0.15))` for paint transition (Spec 7.6).
4. On sequence complete: call `onAnimationComplete()`.

Implementation with `DispatchQueue.main.asyncAfter` chaining (Spec 7.5 recommends chained timers):
```swift
private func animatePath(_ path: [GridPosition], step: Int, isWin: Bool) {
    guard step < path.count else {
        // Animation complete
        isAnimating = false
        onAnimationComplete(isWin: isWin)
        return
    }
    let timePerTile: TimeInterval = 0.125
    withAnimation(.linear(duration: timePerTile)) {
        animatingBallPosition = path[step]
    }
    withAnimation(.easeIn(duration: 0.15)) {
        visuallyPaintedTiles.insert(path[step])
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + timePerTile) { [weak self] in
        self?.animatePath(path, step: step + 1, isWin: isWin)
    }
}
```

For single-tile moves, use `max(0.15, 1 * 0.125) = 0.15` seconds as the timer interval for that single step.

**Input buffering** (Spec 6.3):
In `handleSwipe`:
```swift
func handleSwipe(direction: Direction) {
    if gameState.phase == .moving || isAnimating {
        bufferedDirection = direction  // Replace any existing buffer
        return
    }
    executeMove(direction: direction)
}
```
In `onAnimationComplete`:
```swift
func onAnimationComplete(isWin: Bool) {
    if isWin {
        gameState.phase = .won
        bufferedDirection = nil
        // Trigger win sequence (Phase 5)
    } else {
        gameState.phase = .awaitingInput
        if let buffered = bufferedDirection {
            bufferedDirection = nil
            executeMove(direction: buffered)
        }
    }
}
```

**Bump animation** (Spec 7.7):
When `applyMove` returns an empty path:
- Set `isBumping = true` and `bumpDirection = direction`.
- In `BallView`, apply an offset of 2pt in the bump direction.
- Use `spring(response: 0.15, dampingFraction: 0.5)` animation.
- After a brief delay (0.15s), reset `isBumping = false`.
- Phase remains `.awaitingInput` -- input is NOT locked during bump.

**BallView bump offset**:
```swift
var bumpOffset: CGSize {
    guard isBumping, let dir = bumpDirection else { return .zero }
    switch dir {
    case .up: return CGSize(width: 0, height: -2)
    case .down: return CGSize(width: 0, height: 2)
    case .left: return CGSize(width: -2, height: 0)
    case .right: return CGSize(width: 2, height: 0)
    }
}
// Apply: .offset(bumpOffset).animation(.spring(response: 0.15, dampingFraction: 0.5), value: isBumping)
```

**Idle pulse** (Spec 7.8):
```swift
// In BallView:
@State private var isPulsing = false

// Apply when phase == .awaitingInput and not animating:
.scaleEffect(isPulsing ? 1.08 : 1.0)
.animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
.onAppear { isPulsing = true }
.onChange(of: isAnimating) { _, animating in
    isPulsing = !animating
}
```
The pulse stops during movement and resumes when awaiting input.

**CellView paint animation** (Spec 7.6):
```swift
// CellView already uses isPainted to determine color.
// Add animation modifier:
.animation(.easeIn(duration: 0.15), value: isPainted)
```
Since `visuallyPaintedTiles` is updated one cell at a time during the timer sequence, each cell animates independently as the ball reaches it.

**Synchronizing model and visual state**:
- `gameState.paintedTiles` = model truth (updated instantly by `applyMove`).
- `visuallyPaintedTiles` = what the view renders (updated cell-by-cell during animation).
- On restart, sync: `visuallyPaintedTiles = gameState.paintedTiles` (just the start tile).
- `CellView.isPainted` reads from `visuallyPaintedTiles`, not `gameState.paintedTiles`.

#### Acceptance Criteria

1. `xcodebuild build` succeeds.
2. `xcodebuild test` passes (all prior tests still pass).
3. Swiping on the grid moves the ball in the swiped direction.
4. Ball animates smoothly cell-by-cell at ~8 tiles/sec (linear easing).
5. Cells paint as the ball crosses them (color transition visible).
6. Swiping into a wall produces a bump animation (2pt shift and spring back).
7. Ball pulses gently (scale 1.0 to 1.08) when awaiting input.
8. Pulse stops during ball movement and resumes after.
9. Swiping during ball movement buffers the input; buffered swipe executes immediately when current movement completes.
10. A second swipe during movement replaces the buffer (only last swipe kept).
11. Phase transitions are correct: `.awaitingInput` -> `.moving` -> `.awaitingInput` (or `.won`).

---

### Phase 5: Win Flow & Level Progression
**ID:** `phase-5`
**Complexity:** M
**Dependencies:** Phase 4

#### Description

Implement the win animation sequence, level-to-level transitions, and the completion screen shown after all 3 levels are beaten. After this phase, the full Classic mode gameplay loop is complete: play Level 1 through Level 3, see win celebrations, reach the congratulations screen, and play again.

#### Files to Create

| File | Purpose |
|------|---------|
| `Sources/View/CompletionView.swift` | "Congratulations" screen (Spec 9.3) |

#### Files to Modify

| File | Change |
|------|--------|
| `Sources/App/GameViewModel.swift` | Add win sequence timing, level advancement logic, `playAgain()`. |
| `Sources/View/GameView.swift` | Add win overlay (Level Complete text), level transition animation, conditional display of CompletionView. |
| `Sources/View/GridView.swift` | Add win grid pulse animation (Spec 7.9 step 3). |
| `Sources/View/BallView.swift` | Stop idle pulse on win. |

#### Implementation Details

**Win animation sequence** (Spec 7.9):

When `onAnimationComplete` is called with `isWin == true`:

1. **0.0s**: Last tile paints normally (already handled by Phase 4 animation).
2. **+0.3s pause**: Let the player see the fully painted grid. Use `DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)`.
3. **+0.3s - +0.7s**: Grid pulse. All painted cells scale to 1.05 and back over 0.4s using `.easeInOut`. Add a `isGridPulsing` flag to ViewModel. GridView applies `.scaleEffect(isGridPulsing ? 1.05 : 1.0)` with `.easeInOut(duration: 0.4)` animation.
4. **+0.7s - +1.0s**: "Level Complete!" text fades in. Add `isShowingWinText` flag. `Text("Level Complete!").font(.title.bold()).opacity(isShowingWinText ? 1 : 0)` with `.easeIn(duration: 0.3)` animation. Move count displayed below: `"Moves: {N}"` in `.headline`.
5. **+1.5s**: Level transition. Call `advanceLevel()`.

```swift
func triggerWinSequence() {
    gameState.phase = .won

    // Step 1: 0.3s pause (ball already at final position)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        // Step 2: Grid pulse
        withAnimation(.easeInOut(duration: 0.4)) {
            self?.isGridPulsing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            withAnimation(.easeInOut(duration: 0.4)) {
                self?.isGridPulsing = false
            }
            // Step 3: Win text fade-in
            withAnimation(.easeIn(duration: 0.3)) {
                self?.isShowingWinText = true
            }
        }
    }

    // Step 4: Level transition at 1.5s total
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        self?.isShowingWinText = false
        self?.isGridPulsing = false
        self?.advanceLevel()
    }
}
```

**Additional ViewModel state for win sequence**:
```swift
var isGridPulsing: Bool = false
var isShowingWinText: Bool = false
```

**Level transition** (Spec 9.2):
```swift
func advanceLevel() {
    let nextIndex = currentLevelIndex + 1
    if nextIndex < LevelStore.levels.count {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentLevelIndex = nextIndex
            gameState = GameEngine.createInitialState(for: LevelStore.levels[nextIndex])
            animatingBallPosition = gameState.ballPosition
            visuallyPaintedTiles = gameState.paintedTiles
            bufferedDirection = nil
        }
    } else {
        withAnimation(.easeInOut(duration: 0.4)) {
            isShowingCompletion = true
        }
    }
}
```

**Play Again** (Spec 9.3):
```swift
func playAgain() {
    withAnimation(.easeInOut(duration: 0.4)) {
        isShowingCompletion = false
        currentLevelIndex = 0
        gameState = GameEngine.createInitialState(for: LevelStore.levels[0])
        animatingBallPosition = gameState.ballPosition
        visuallyPaintedTiles = gameState.paintedTiles
        bufferedDirection = nil
    }
}
```

**CompletionView.swift** (Spec 9.3):
```swift
struct CompletionView: View {
    let onPlayAgain: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Congratulations!")
                .font(.largeTitle.bold())
            Text("You completed all levels.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Thanks for playing Damaze")
                .font(.body)
                .foregroundStyle(.secondary)
            Button("Play Again", action: onPlayAgain)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
```

**GameView.swift updates**:
```swift
var body: some View {
    if viewModel.isShowingCompletion {
        CompletionView(onPlayAgain: viewModel.playAgain)
    } else {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    HUDView(...)
                    Spacer()
                    // Grid + Ball
                    Spacer()
                }

                // Win overlay
                if viewModel.isShowingWinText {
                    VStack(spacing: 8) {
                        Text("Level Complete!")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                        Text("Moves: \(viewModel.moveCount)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}
```

**Restart during win sequence**: If the player taps restart during the win animation, it should cancel the win sequence and reset the level. In `restart()`, clear `isGridPulsing`, `isShowingWinText`, and any pending `DispatchQueue` calls. A simple approach: use a generation counter that increments on restart, and check it in each `asyncAfter` callback before acting.

#### Acceptance Criteria

1. `xcodebuild build` succeeds.
2. `xcodebuild test` passes (all prior tests still pass).
3. Painting all tiles in Level 1 triggers the win sequence:
   - 0.3s pause after last tile painted.
   - Grid pulses (scale 1.05 and back, 0.4s).
   - "Level Complete!" and "Moves: N" text fades in.
   - After 1.5s total, Level 2 loads with a 0.4s cross-fade transition.
4. Level 2 displays with green color scheme. Level 3 displays with orange.
5. Completing Level 3 shows the CompletionView with "Congratulations!", subtitle text, and "Play Again" button.
6. "Play Again" resets to Level 1 with blue color scheme.
7. Restart button works at any point, including during win animation.
8. Input buffer is cleared on level transition and restart.
9. The full gameplay loop is playable: Level 1 -> Level 2 -> Level 3 -> Completion -> Play Again -> Level 1.

---

## 3. Dependency Graph

```
phase-1 (Model Layer)
    |
    v
phase-2 (Input Handling & ViewModel)
    |
    v
phase-3 (Grid Rendering & Basic UI)
    |
    v
phase-4 (Interaction & Animation)
    |
    v
phase-5 (Win Flow & Level Progression)
```

All phases are strictly sequential. Each phase depends on the previous phase being complete. No phases can execute in parallel.

---

## 4. Risk Notes

### R1: Test grids without start positions
**Problem:** Many spec test cases (e.g., #1-4) describe grids like "1x5 all floor" which have no start cell (value 2). The `Level.init` requires exactly one start cell and will throw.
**Mitigation:** Either (a) add a start cell to test grids and position the ball elsewhere for the test, or (b) call `GameEngine.computePath` directly with a `[[CellType]]` array, bypassing `Level.init`. Approach (a) is recommended for consistency. The Phase 1 polecat should handle this when implementing tests.

### R2: DispatchQueue timer drift during animation
**Problem:** Chained `DispatchQueue.main.asyncAfter` calls can accumulate timing drift, causing animation to feel uneven on slow devices.
**Mitigation:** For v1, this is acceptable. The animation durations are short (max ~0.875s for a 7-tile slide). If drift is noticeable, switch to a `CADisplayLink`-based timer. Phase 4 polecat should note this as a known limitation.

### R3: Restart during animation leaves orphaned timers
**Problem:** If the player taps restart while a cell-by-cell animation timer chain is in progress, the old timers will still fire and modify state.
**Mitigation:** Use a generation counter (increment on restart or level change). Each timer callback checks if the current generation matches the generation at dispatch time; if not, it no-ops. Phase 4 polecat must implement this.

### R4: @Observable requires iOS 17
**Problem:** `@Observable` macro was introduced in iOS 17, but the spec targets iOS 16.0+.
**Mitigation:** If the deployment target remains iOS 16, use `ObservableObject` with `@Published` properties instead of `@Observable`. If the deployment target is raised to iOS 17, `@Observable` works directly. The Phase 2 polecat should check the deployment target in `project.yml` and choose accordingly. The spec explicitly states `@Observable` (Spec 10.3), so raising the deployment target to 17.0 is the preferred approach if acceptable. Update `project.yml` accordingly.

### R5: Ball overlay positioning
**Problem:** The ball is rendered as an overlay using `.position()` which positions within the parent's coordinate space. If the grid is embedded in padding, spacers, or scroll views, the ball coordinates may be offset.
**Mitigation:** Use a `ZStack` for the grid and ball, where the `ZStack` has the exact same frame as the grid. The ball's `.position()` is then relative to the grid's origin. Phase 3 polecat should verify ball alignment visually in the simulator.

### R6: Level data correctness
**Problem:** The spec contains detailed level grids with hand-verified solutions. A transcription error in `LevelStore.swift` could produce unsolvable levels.
**Mitigation:** Tests #48-50 verify each level's documented solution. If these tests pass, the level data is correct. Phase 1 polecat must implement these tests and ensure they pass.
