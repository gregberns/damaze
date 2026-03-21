# Damaze

iOS ice-sliding paint-maze puzzle game. Pure SwiftUI, XcodeGen, no SpriteKit, no monetization.

## Spec & Plan

The single source of truth for implementation:
- **Spec:** `plans/damaze-classic/02-spec/spec.md` — All design decisions locked. When in doubt, read the spec.
- **Plan:** `plans/damaze-classic/03-plan/plan.md` — 5 sequential phases, each self-contained.

## Build Commands

**IMPORTANT: ALWAYS use scripts/test.sh. NEVER run xcodebuild directly — it will stall your session.**

```bash
# Generate Xcode project (run after any project.yml or file structure change)
xcodegen generate

# Run tests (handles simulator boot, output filtering, timeout)
scripts/test.sh

# Run tests skipping xcodegen (faster when project.yml hasn't changed)
scripts/test.sh quick

# Build only (no tests)
scripts/test.sh build
```

## Architecture Rules

1. **Model layer has ZERO SwiftUI imports.** Files in `Sources/Model/` import only Foundation or nothing. Any SwiftUI import in Model/ is a bug.
2. **Pure model, view animates.** The GameEngine computes the full move result synchronously. The view layer receives the result and animates to catch up.
3. **Test everything in the model.** All game logic (path computation, win detection, level validation, state machine) is unit tested. View layer is manually verified.

## Quality Standards

- All tests must pass before committing: `scripts/test.sh quick`
- Test naming convention: `test_<unit>_<scenario>_<expectedResult>()`
- Every level ships with a verified solution sequence tested in GameEngineTests
- No SwiftUI imports in Model/ files — enforce this as a hard boundary

## Project Structure

```
Sources/
  App/        — @main entry, GameViewModel (@Observable bridge)
  Model/      — Pure Swift: types, GameEngine, LevelStore (NO SwiftUI)
  View/       — SwiftUI views, InputMapper, animations
Tests/
  Model/      — Unit tests for all model types and engine
  View/       — InputMapper tests
```

## Key Types (see spec for details)

- `GameEngine` — Static pure functions: computePath, applyMove, createInitialState
- `GameState` — Ball position, painted tiles, phase, move history
- `Level` — Validated grid data with throwing init
- `GameViewModel` — @Observable wrapper bridging model to SwiftUI
- `InputMapper` — Pure function: CGSize translation -> Direction?

## Coordinate System

`grid[0][0]` = top-left. Row increases downward. Col increases rightward.
Swipe up = row decreases. Swipe right = col increases.
