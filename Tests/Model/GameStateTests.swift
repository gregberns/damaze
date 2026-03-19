import XCTest
@testable import Damaze

final class GameStateTests: XCTestCase {
    // #17
    func test_isComplete_allTilesPainted_returnsTrue() throws {
        let level = try Level(grid: [
            [2, 1, 1],
        ])
        var state = GameEngine.createInitialState(for: level)
        state.paintedTiles = [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2),
        ]
        XCTAssertTrue(state.isComplete)
    }

    // #18
    func test_isComplete_oneTileRemaining_returnsFalse() throws {
        let level = try Level(grid: [
            [2, 1, 1],
        ])
        var state = GameEngine.createInitialState(for: level)
        state.paintedTiles = [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
        ]
        XCTAssertFalse(state.isComplete)
    }

    // #19
    func test_isComplete_singleFloorTileLevel_trueAtSpawn() throws {
        let level = try Level(grid: [
            [0, 0, 0],
            [0, 2, 0],
            [0, 0, 0],
        ])
        let state = GameEngine.createInitialState(for: level)
        XCTAssertTrue(state.isComplete)
    }

    // #20
    func test_applyMove_completingMove_setsIsWinTrue() throws {
        let level = try Level(grid: [
            [2, 1],
        ])
        var state = GameEngine.createInitialState(for: level)
        let result = GameEngine.applyMove(direction: .right, state: &state)
        XCTAssertTrue(result.isWin)
    }

    // #21
    func test_applyMove_nonCompletingMove_setsIsWinFalse() throws {
        let bigLevel = try Level(grid: [
            [2, 1],
            [1, 1],
        ])
        var bigState = GameEngine.createInitialState(for: bigLevel)
        let result = GameEngine.applyMove(direction: .right, state: &bigState)
        XCTAssertFalse(result.isWin)
    }
}
