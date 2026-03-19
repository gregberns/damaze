# Contributing

## Build & Test

See [README.md](README.md#quick-start) for setup. Run `xcodegen generate` after any change to `project.yml` or file structure.

## Architecture

The hard boundary: **no SwiftUI imports in `Sources/Model/`**. The model layer is pure Swift. All game logic lives in `GameEngine` as static pure functions. The view layer animates to match model state.

Read [CLAUDE.md](CLAUDE.md) for the full set of conventions.

## Tests

All game logic must be unit tested. Test naming convention:

```
test_<unit>_<scenario>_<expectedResult>()
```

Every level ships with a verified solution sequence tested in `GameEngineTests`. Run the full suite before committing.

## Adding Levels

1. Define a new `LevelData` in `Sources/Model/LevelStore.swift` with a grid array (0=wall, 1=floor, 2=start)
2. Add it to the `allLevels` array
3. Verify the level has exactly one start tile and at least one floor tile (the `Level` init validates this)
4. Add a solution test in `Tests/Model/GameEngineTests.swift` proving the level is solvable
5. Pick a `LevelColorScheme` — add new cases to the enum and the SwiftUI color extension in `GameView.swift` if needed
