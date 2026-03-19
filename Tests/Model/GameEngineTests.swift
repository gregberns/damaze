import XCTest
@testable import Damaze

final class GameEngineTests: XCTestCase {

    // MARK: - Path Computation Tests

    // #1
    func test_computePath_straightCorridorRight_slidesToEnd() throws {
        let level = try Level(grid: [
            [2, 1, 1, 1, 1]
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

    // #2
    func test_computePath_straightCorridorLeft_slidesToEnd() throws {
        let level = try Level(grid: [
            [1, 1, 1, 1, 2]
        ])
        let path = GameEngine.computePath(
            from: GridPosition(row: 0, col: 4),
            direction: .left,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        XCTAssertEqual(path, [
            GridPosition(row: 0, col: 3),
            GridPosition(row: 0, col: 2),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 0),
        ])
    }

    // #3
    func test_computePath_straightCorridorUp_slidesToEnd() throws {
        let level = try Level(grid: [
            [1], [1], [1], [1], [2]
        ])
        let path = GameEngine.computePath(
            from: GridPosition(row: 4, col: 0),
            direction: .up,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        XCTAssertEqual(path, [
            GridPosition(row: 3, col: 0),
            GridPosition(row: 2, col: 0),
            GridPosition(row: 1, col: 0),
            GridPosition(row: 0, col: 0),
        ])
    }

    // #4
    func test_computePath_straightCorridorDown_slidesToEnd() throws {
        let level = try Level(grid: [
            [2], [1], [1], [1], [1]
        ])
        let path = GameEngine.computePath(
            from: GridPosition(row: 0, col: 0),
            direction: .down,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        XCTAssertEqual(path, [
            GridPosition(row: 1, col: 0),
            GridPosition(row: 2, col: 0),
            GridPosition(row: 3, col: 0),
            GridPosition(row: 4, col: 0),
        ])
    }

    // #5
    func test_computePath_immediateWall_returnsEmptyPath() throws {
        let level = try Level(grid: [
            [1, 2, 0, 1]
        ])
        let path = GameEngine.computePath(
            from: GridPosition(row: 0, col: 1),
            direction: .right,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        XCTAssertEqual(path, [])
    }

    // #6
    func test_computePath_immediateBoundary_returnsEmptyPath() throws {
        let level = try Level(grid: [
            [2, 1, 1]
        ])
        let path = GameEngine.computePath(
            from: GridPosition(row: 0, col: 0),
            direction: .up,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        XCTAssertEqual(path, [])
    }

    // #7
    func test_computePath_immediateBoundaryLeft_returnsEmptyPath() throws {
        let level = try Level(grid: [
            [2, 1, 1]
        ])
        let path = GameEngine.computePath(
            from: GridPosition(row: 0, col: 0),
            direction: .left,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        XCTAssertEqual(path, [])
    }

    // #8
    func test_computePath_stopsAtWall_doesNotEnterWall() throws {
        let level = try Level(grid: [
            [2, 1, 1, 0]
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
        ])
    }

    // #9
    func test_computePath_stopsAtBoundary_lastCellInBounds() throws {
        let level = try Level(grid: [
            [2, 1, 1]
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
        ])
    }

    // #10
    func test_computePath_singleTileMove_returnsOneTile() throws {
        let level = try Level(grid: [
            [2, 1, 0]
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
        ])
    }

    // #11
    func test_computePath_noMovePossibleInAnyDirection_singleTileSurroundedByWalls() throws {
        let level = try Level(grid: [
            [0, 0, 0],
            [0, 2, 0],
            [0, 0, 0],
        ])
        let pos = GridPosition(row: 1, col: 1)
        for dir in Direction.allCases {
            let path = GameEngine.computePath(
                from: pos,
                direction: dir,
                grid: level.grid,
                rows: level.rows,
                cols: level.cols
            )
            XCTAssertEqual(path, [], "Expected empty path for direction \(dir)")
        }
    }

    // #12
    func test_computePath_lShapedCorridor_doesNotTurnCorner() throws {
        let level = try Level(grid: [
            [0, 1, 1],
            [0, 1, 0],
            [0, 2, 0],
        ])
        let path = GameEngine.computePath(
            from: GridPosition(row: 2, col: 1),
            direction: .up,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        XCTAssertEqual(path, [
            GridPosition(row: 1, col: 1),
            GridPosition(row: 0, col: 1),
        ])
    }

    // MARK: - Paint State Tests

    // #13
    func test_applyMove_paintsTilesAlongPath() throws {
        let level = try Level(grid: [
            [2, 1, 1, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        for c in 0...4 {
            XCTAssertTrue(state.paintedTiles.contains(GridPosition(row: 0, col: c)),
                          "Expected tile (0,\(c)) to be painted")
        }
    }

    // #14
    func test_applyMove_retraversalDoesNotDuplicatePaint() throws {
        let level = try Level(grid: [
            [2, 1, 1, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        // Move right to paint all tiles
        GameEngine.applyMove(direction: .right, state: &state)
        state.phase = .awaitingInput
        let countBefore = state.paintedTiles.count
        // Move left — re-traverses all painted tiles
        GameEngine.applyMove(direction: .left, state: &state)
        XCTAssertEqual(state.paintedTiles.count, countBefore)
    }

    // #15
    func test_applyMove_emptyPath_doesNotModifyPaintedTiles() throws {
        let level = try Level(grid: [
            [0, 2, 0]
        ])
        var state = GameEngine.createInitialState(for: level)
        let countBefore = state.paintedTiles.count
        GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(state.paintedTiles.count, countBefore)
    }

    // #16
    func test_applyMove_partialOverlap_onlyNewTilesCounted() throws {
        let level = try Level(grid: [
            [2, 1, 1, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        // Pre-paint first 3 tiles
        state.paintedTiles.insert(GridPosition(row: 0, col: 1))
        state.paintedTiles.insert(GridPosition(row: 0, col: 2))
        let countBefore = state.paintedTiles.count
        GameEngine.applyMove(direction: .right, state: &state)
        // (0,3) and (0,4) are new
        XCTAssertEqual(state.paintedTiles.count, countBefore + 2)
    }

    // MARK: - State Machine Tests

    // #22
    func test_applyMove_duringMovingPhase_rejectsMove() throws {
        let level = try Level(grid: [
            [2, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        state.phase = .moving
        let result = GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(result.path, [])
    }

    // #23
    func test_applyMove_duringWonPhase_rejectsMove() throws {
        let level = try Level(grid: [
            [2, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        state.phase = .won
        let result = GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(result.path, [])
    }

    // #24
    func test_applyMove_validMove_setsPhaseToMoving() throws {
        let level = try Level(grid: [
            [2, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(state.phase, .moving)
    }

    // #25
    func test_applyMove_invalidMove_phaseRemainsAwaitingInput() throws {
        let level = try Level(grid: [
            [0, 2, 0]
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(state.phase, .awaitingInput)
    }

    // MARK: - Move History Tests

    // #36
    func test_applyMove_validMove_appendsToHistory() throws {
        let level = try Level(grid: [
            [2, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(state.moveHistory, [.right])
    }

    // #37
    func test_applyMove_invalidMove_doesNotAppendToHistory() throws {
        let level = try Level(grid: [
            [0, 2, 0]
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(state.moveHistory, [])
    }

    // #38
    func test_applyMove_multipleValidMoves_historyAccurate() throws {
        let level = try Level(grid: [
            [2, 1],
            [1, 1],
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        state.phase = .awaitingInput
        GameEngine.applyMove(direction: .down, state: &state)
        state.phase = .awaitingInput
        GameEngine.applyMove(direction: .left, state: &state)
        XCTAssertEqual(state.moveHistory, [.right, .down, .left])
    }

    // MARK: - Move Counter Tests

    // #39
    func test_applyMove_validMove_incrementsMoveCount() throws {
        let level = try Level(grid: [
            [2, 1, 1]
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(state.moveCount, 1)
    }

    // #40
    func test_applyMove_invalidMove_doesNotIncrementMoveCount() throws {
        let level = try Level(grid: [
            [0, 2, 0]
        ])
        var state = GameEngine.createInitialState(for: level)
        GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertEqual(state.moveCount, 0)
    }

    // MARK: - Level Solution Tests

    // #48
    func test_level1_solvableWithDocumentedSolution() {
        let level = LevelStore.level1.level
        var state = GameEngine.createInitialState(for: level)
        let moves: [Direction] = [.left, .up, .right, .down]
        for move in moves {
            GameEngine.applyMove(direction: move, state: &state)
            state.phase = .awaitingInput
        }
        XCTAssertTrue(state.isComplete)
    }

    // #49
    func test_level2_solvableWithDocumentedSolution() {
        let level = LevelStore.level2.level
        var state = GameEngine.createInitialState(for: level)
        let moves: [Direction] = [.right, .up, .left, .up, .right, .down]
        for move in moves {
            GameEngine.applyMove(direction: move, state: &state)
            state.phase = .awaitingInput
        }
        XCTAssertTrue(state.isComplete)
    }

    // #50
    func test_level3_solvableWithDocumentedSolution() {
        let level = LevelStore.level3.level
        var state = GameEngine.createInitialState(for: level)
        let moves: [Direction] = [.up, .left, .up, .left, .up, .right, .up, .right, .down, .right, .down, .left, .down]
        for move in moves {
            GameEngine.applyMove(direction: move, state: &state)
            state.phase = .awaitingInput
        }
        XCTAssertTrue(state.isComplete)
    }

    // MARK: - createInitialState Tests

    // #51
    func test_createInitialState_ballAtStartPosition() throws {
        let level = try Level(grid: [
            [1, 2, 1],
        ])
        let state = GameEngine.createInitialState(for: level)
        XCTAssertEqual(state.ballPosition, level.startPosition)
    }

    // #52
    func test_createInitialState_startTilePainted() throws {
        let level = try Level(grid: [
            [1, 2, 1],
        ])
        let state = GameEngine.createInitialState(for: level)
        XCTAssertTrue(state.paintedTiles.contains(level.startPosition))
    }

    // #53
    func test_createInitialState_paintedCountIsOne() throws {
        let level = try Level(grid: [
            [1, 2, 1],
        ])
        let state = GameEngine.createInitialState(for: level)
        XCTAssertEqual(state.paintedTiles.count, 1)
    }

    // #54
    func test_createInitialState_phaseIsAwaitingInput() throws {
        let level = try Level(grid: [
            [1, 2, 1],
        ])
        let state = GameEngine.createInitialState(for: level)
        XCTAssertEqual(state.phase, .awaitingInput)
    }

    // #55
    func test_createInitialState_moveCountIsZero() throws {
        let level = try Level(grid: [
            [1, 2, 1],
        ])
        let state = GameEngine.createInitialState(for: level)
        XCTAssertEqual(state.moveCount, 0)
    }

    // #56
    func test_createInitialState_moveHistoryIsEmpty() throws {
        let level = try Level(grid: [
            [1, 2, 1],
        ])
        let state = GameEngine.createInitialState(for: level)
        XCTAssertEqual(state.moveHistory, [])
    }
}
