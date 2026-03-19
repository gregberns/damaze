# Damaze

An ice-sliding paint-maze puzzle game for iOS. Swipe to send a ball sliding across a grid — it won't stop until it hits a wall. Every tile it crosses gets painted. Win by painting them all.

## Quick Start

```bash
# Prerequisites: Xcode 16+, XcodeGen (brew install xcodegen)

# Generate the Xcode project
xcodegen generate

# Build
xcodebuild -scheme Damaze -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | xcsift

# Run tests
xcodebuild -scheme DamazeTests -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  test 2>&1 | xcsift
```

Or open `Damaze.xcodeproj` in Xcode and hit Run.

## How It Works

The core mechanic is **ice-sliding**: swipe in a cardinal direction and the ball travels the full length of the corridor until it hits a wall. You can't stop mid-slide. This turns simple-looking grids into genuine routing puzzles — you need to find a sequence of swipes that paints every tile.

Classic mode ships with 3 hand-crafted levels of increasing difficulty. No timer, no move limit, no way to lose. Just swipe until you solve it or restart to try again.

## Project Structure

```
Sources/
  App/        DamazeApp (entry point), GameViewModel (@Observable bridge)
  Model/      Pure Swift: types, GameEngine, LevelStore (zero SwiftUI imports)
  View/       SwiftUI views, InputMapper, animations
Tests/
  Model/      Unit tests for all model types and engine
  View/       InputMapper tests
```

**Key architecture rule:** the Model layer is pure Swift with no SwiftUI dependency. `GameEngine` exposes static pure functions that compute move results synchronously. The View layer receives results and animates to catch up.

## Key Types

| Type | Role |
|------|------|
| `Level` | Validated grid data (throwing init rejects invalid grids) |
| `GameState` | Ball position, painted tiles, phase, move history |
| `GameEngine` | Static pure functions: `computePath`, `applyMove`, `createInitialState` |
| `GameViewModel` | `@Observable` wrapper bridging model to SwiftUI |
| `InputMapper` | Pure function: swipe gesture → `Direction?` |

## Levels

Levels are defined as 2D integer arrays in `LevelStore.swift`:
- `0` = wall
- `1` = floor (paintable)
- `2` = ball start position

Grid coordinate system: `grid[0][0]` = top-left. Row increases downward, column increases rightward.

## Docs

- [Game Premise](GAME-PREMISE.md) — Full game design document (all modes, mechanics, visual design)
- [iOS Recommendations](IOS-RECOMMENDATIONS.md) — Tech stack decisions and toolchain setup
- [Implementation Spec](plans/damaze-classic/02-spec/spec.md) — Locked spec for Classic mode (single source of truth)
- [Implementation Plan](plans/damaze-classic/03-plan/plan.md) — 5-phase build plan with acceptance criteria
- [CLAUDE.md](CLAUDE.md) — AI agent conventions and project rules

## Tech

- **Platform:** iOS 17.0+, portrait only, iPhone
- **UI:** Pure SwiftUI (no SpriteKit)
- **Build:** XcodeGen for project generation
- **Tests:** XCTest (61 tests covering the model layer)
- **Dependencies:** None beyond XcodeGen
